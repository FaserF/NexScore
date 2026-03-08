import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_save_manager.dart';

/// Observer for the app's lifecycle to trigger auto-saves.
class AppLifecycleObserver extends WidgetsBindingObserver {
  final Ref ref;

  AppLifecycleObserver({required this.ref});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      GameSaveManager.saveCurrentGame(ref);
    }
  }
}

final appLifecycleObserverProvider = Provider<AppLifecycleObserver>((ref) {
  final observer = AppLifecycleObserver(ref: ref);
  WidgetsBinding.instance.addObserver(observer);
  ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  return observer;
});
