import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  ScreenshotController get controller => _screenshotController;

  /// Captures a [Widget] by wrapping it in a [Screenshot] widget and shares it.
  /// Note: On Web, the behavioral fallback might differ based on browser support.
  Future<void> shareWidget(
    BuildContext context,
    Widget widget, {
    String? text,
  }) async {
    try {
      final imageBytes = await _screenshotController.captureFromWidget(
        Material(child: widget),
        context: context,
        delay: const Duration(milliseconds: 100),
      );

      if (kIsWeb) {
        // Simple share for Web if possible, or download
        await Share.shareXFiles([
          XFile.fromData(
            imageBytes,
            mimeType: 'image/png',
            name: 'nexscore_share_${const Uuid().v4().substring(0, 8)}.png',
          ),
        ], text: text);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/nexscore_share_${const Uuid().v4().substring(0, 8)}.png',
        ).create();
        await file.writeAsBytes(imageBytes);

        await Share.shareXFiles([XFile(file.path)], text: text);
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  /// Shares a captured file path directly.
  Future<void> shareFile(String filePath, {String? text}) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }
}

// Provider should be defined in a separate file or here for simplicity
// but I'll put it in lib/core/providers/share_provider.dart later.
