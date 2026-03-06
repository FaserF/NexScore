import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Documentation Tests', () {
    test('AUTH_SETUP.md contains exact GitHub callback CAUTION warning', () {
      // Find the docs directory relative to the current working directory which is usually the project root in tests or `nexscore` directory
      final d = Directory.current.path;
      String filePath;

      if (d.endsWith('nexscore')) {
        filePath = '${Directory.current.parent.path}/docs/AUTH_SETUP.md';
      } else {
        filePath = '$d/docs/AUTH_SETUP.md';
      }

      final file = File(filePath);

      expect(
        file.existsSync(),
        isTrue,
        reason: 'AUTH_SETUP.md should exist at $filePath',
      );

      final content = file.readAsStringSync();

      // We are looking for this exact specific disclaimer
      const expectedText =
          'The **callback URL** must be the one Firebase showed you in [Step 2.2](#22-enable-authentication-providers). If it doesn\'t match exactly, GitHub login will fail with a redirect error.';

      expect(
        content.contains(expectedText),
        isTrue,
        reason:
            'AUTH_SETUP.md must contain the exact CAUTION text about the GitHub callback URL to prevent regression.',
      );
    });
  });
}
