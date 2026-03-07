import 'dart:js_interop';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@JS()
external void flutterReloadApp();

@JS('window.flutterUpdateAvailable')
external JSBoolean? get _flutterUpdateAvailable;

@JS('window.onFlutterUpdateAvailable')
external set _onFlutterUpdateAvailable(JSFunction value);

final pwaUpdateProvider = NotifierProvider<PwaUpdateNotifier, bool>(() {
  return PwaUpdateNotifier();
});

class PwaUpdateNotifier extends Notifier<bool> {
  @override
  bool build() {
    _init();
    return false;
  }

  void _init() {
    if (_flutterUpdateAvailable?.toDart == true) {
      state = true;
    }
    _onFlutterUpdateAvailable = (() {
      state = true;
    }).toJS;
  }

  void reloadApp() {
    flutterReloadApp();
  }
}
