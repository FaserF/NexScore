import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/utils/app_version.dart';

void main() {
  group('AppVersion', () {
    test('current returns the default version in test environment', () {
      expect(AppVersion.current, isNotEmpty);
    });

    test('displayVersion starts with v', () {
      expect(AppVersion.displayVersion, startsWith('v'));
    });

    test('displayVersion includes current version', () {
      expect(AppVersion.displayVersion, 'v${AppVersion.current}');
    });

    test('isPreRelease is true for default version starting with 0.', () {
      // Default is 0.1.0+1 which starts with '0.'
      expect(AppVersion.isPreRelease, true);
    });
  });
}
