import 'package:flutter/foundation.dart';

/// Shows the PWA install prompt. Returns true if accepted or shown.
Future<bool> showInstallPrompt() async {
  debugPrint('PWA install prompt is not available on this platform.');
  return false;
}
