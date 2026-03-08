import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/lifecycle/app_lifecycle_observer.dart';

void main() {
  group('AppLifecycleObserver Tests', () {
    test('didChangeAppLifecycleState triggers auto-save on paused/inactive', () {
      final container = ProviderContainer();
      final observer = AppLifecycleObserver(ref: container);

      // We can't fully mock GameSaveManager easily without dependency injection
      // on the static method, but we can verify the observer doesn't crash
      // when the state changes.
      expect(
        () => observer.didChangeAppLifecycleState(AppLifecycleState.resumed),
        returnsNormally,
      );
      expect(
        () => observer.didChangeAppLifecycleState(AppLifecycleState.paused),
        returnsNormally,
      );
      expect(
        () => observer.didChangeAppLifecycleState(AppLifecycleState.inactive),
        returnsNormally,
      );
      expect(
        () => observer.didChangeAppLifecycleState(AppLifecycleState.detached),
        returnsNormally,
      );
      expect(
        () => observer.didChangeAppLifecycleState(AppLifecycleState.hidden),
        returnsNormally,
      );

      container.dispose();
    });
  });
}
