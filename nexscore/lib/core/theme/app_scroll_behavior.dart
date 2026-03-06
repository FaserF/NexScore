import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Custom ScrollBehavior to force momentum-based scrolling (BouncingScrollPhysics)
/// on Web, especially for mobile PWA usage.
class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Forcing BouncingScrollPhysics (iOS-style) often feels "smoother" and more
    // "native" on mobile web than the default ClampingScrollPhysics.
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}
