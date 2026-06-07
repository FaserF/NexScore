import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScreenshotController {
  final GlobalKey _containerKey = GlobalKey();
  GlobalKey get containerKey => _containerKey;

  Future<Uint8List?> capture({
    double? pixelRatio,
    Duration delay = const Duration(milliseconds: 20),
  }) {
    final context = _containerKey.currentContext;
    final double ratio = pixelRatio ?? (context != null ? MediaQuery.of(context).devicePixelRatio : 1.0);

    return Future.delayed(delay, () async {
      try {
        final findRenderObject = _containerKey.currentContext?.findRenderObject();
        if (findRenderObject == null) return null;
        final RenderRepaintBoundary boundary = findRenderObject as RenderRepaintBoundary;
        
        final image = await boundary.toImage(pixelRatio: ratio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return byteData?.buffer.asUint8List();
      } catch (e) {
        rethrow;
      }
    });
  }

  Future<Uint8List> captureFromWidget(
    Widget widget, {
    Duration delay = const Duration(seconds: 1),
    double? pixelRatio,
    BuildContext? context,
    Size? targetSize,
  }) async {
    Widget child = widget;
    if (context != null) {
      child = InheritedTheme.captureAll(
        context,
        MediaQuery(
          data: MediaQuery.of(context),
          child: Material(
            color: Colors.transparent,
            child: child,
          ),
        ),
      );
    }

    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    final platformDispatcher = WidgetsBinding.instance.platformDispatcher;
    final fallBackView = platformDispatcher.views.first;
    final view = context == null ? fallBackView : View.maybeOf(context) ?? fallBackView;
    
    final Size logicalSize = targetSize ?? view.physicalSize / view.devicePixelRatio;
    final Size imageSize = targetSize ?? view.physicalSize;

    final RenderView renderView = RenderView(
      view: view,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints(
          maxWidth: logicalSize.width,
          maxHeight: logicalSize.height,
        ),
        devicePixelRatio: pixelRatio ?? 1.0,
      ),
    );

    final PipelineOwner pipelineOwner = PipelineOwner();
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());

    pipelineOwner.rootNode = renderView;
    renderView.prepareInitialFrame();

    final RenderObjectToWidgetElement<RenderBox> rootElement =
        RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      ),
    ).attachToRenderTree(buildOwner);

    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    ui.Image? image;
    await Future.delayed(delay);

    image = await repaintBoundary.toImage(
      pixelRatio: pixelRatio ?? (imageSize.width / logicalSize.width),
    );

    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    try {
      buildOwner.finalizeTree();
    } catch (_) {}

    if (byteData == null) {
      throw Exception('Failed to convert screenshot to byte data');
    }
    return byteData.buffer.asUint8List();
  }
}

class Screenshot extends StatelessWidget {
  final Widget? child;
  final ScreenshotController controller;

  const Screenshot({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: controller.containerKey,
      child: child,
    );
  }
}
