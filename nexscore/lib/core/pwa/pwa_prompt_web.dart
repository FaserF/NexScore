import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('flutterShowInstallPrompt')
external JSPromise<JSBoolean> _flutterShowInstallPrompt();

@JS('flutterCanShowInstallPrompt')
external JSBoolean _flutterCanShowInstallPrompt();

@JS('onFlutterInstallPromptReady')
external set _onInstallPromptReady(JSFunction? value);

/// Callback for when the install prompt is ready.
set onInstallPromptReady(void Function()? value) {
  _onInstallPromptReady = value?.toJS;
}

/// Returns true if the PWA install prompt can be shown.
bool canShowInstallPrompt() {
  try {
    return _flutterCanShowInstallPrompt().toDart;
  } catch (e) {
    return false;
  }
}

/// Returns true if the app is running in standalone mode (PWA installed).
bool isStandalone() {
  try {
    // In our JS, flutterCanShowInstallPrompt returns !isStandalone
    return !_flutterCanShowInstallPrompt().toDart;
  } catch (e) {
    return false;
  }
}

/// Shows the PWA install prompt. Returns true if accepted or shown.
Future<bool> showInstallPrompt() async {
  try {
    final result = await _flutterShowInstallPrompt().toDart;
    return result.toDart;
  } catch (e) {
    debugPrint('Error showing PWA prompt: $e');
    return false;
  }
}
