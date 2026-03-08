import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('window.flutterShowInstallPrompt')
external JSPromise<JSBoolean> _flutterShowInstallPrompt();

@JS('window.flutterCanShowInstallPrompt')
external JSBoolean _flutterCanShowInstallPrompt();

@JS('window.onFlutterInstallPromptReady')
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

/// Shows the PWA install prompt. Returns true if accepted or shown.
Future<bool> showInstallPrompt() async {
  try {
    final result = await _flutterShowInstallPrompt().toDart;
    return result.toDart;
  } catch (e) {
    debugPrint('Error showing PWA prompt: $e');
  }
  return false;
}
