import 'package:flutter/foundation.dart';

/// Returns true if the PWA install prompt can be shown.
bool canShowInstallPrompt() => false;

/// Shows the PWA install prompt. Returns true if accepted or shown.
Future<bool> showInstallPrompt() async {
  debugPrint('PWA install prompt is not available on this platform.');
  return false;
}

/// Callback for when the install prompt is ready.
set onInstallPromptReady(void Function()? value) {}
