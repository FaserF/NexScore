import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('window.flutterShowInstallPrompt')
external JSPromise<JSBoolean>? get _flutterShowInstallPrompt;

/// Shows the PWA install prompt. Returns true if accepted or shown.
Future<bool> showInstallPrompt() async {
  try {
    if (_flutterShowInstallPrompt != null) {
      final result = await _flutterShowInstallPrompt!.toDart;
      return result.toDart;
    }
  } catch (e) {
    debugPrint('Error showing PWA prompt: $e');
  }
  return false;
}
