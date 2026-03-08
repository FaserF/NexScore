import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/pwa/pwa_prompt.dart' as pwa;

void main() {
  group('PWA Prompt Logic Tests', () {
    test('isStandalone returns false by default on stub', () {
      expect(pwa.isStandalone(), isFalse);
    });

    test('canShowInstallPrompt returns false by default on stub', () {
      expect(pwa.canShowInstallPrompt(), isFalse);
    });

    // Note: JS interop tests are hard in unit tests,
    // but we've verified the logic flow in settings_screen.dart
  });
}
