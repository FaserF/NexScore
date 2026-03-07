import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pwaUpdateProvider = StateNotifierProvider<PwaUpdateNotifier, bool>((ref) {
  return PwaUpdateNotifier();
});

class PwaUpdateNotifier extends StateNotifier<bool> {
  PwaUpdateNotifier() : super(false) {
    if (kIsWeb) {
      _init();
    }
  }

  void _init() {
    // Check initial state
    final isUpdateAvailable = js.context['flutterUpdateAvailable'];
    if (isUpdateAvailable == true) {
      state = true;
    }

    // Register callback for future updates
    js.context['onFlutterUpdateAvailable'] = () {
      state = true;
    };
  }

  void reloadApp() {
    if (kIsWeb) {
      js.context.callMethod('flutterReloadApp');
    }
  }
}
