import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('Web Index Integrity Tests', () {
    late File indexFile;
    late String content;

    setUpAll(() {
      // Adjust path based on where the test is run.
      // Assuming it's run from the 'nexscore' root.
      indexFile = File('web/index.html');
      expect(
        indexFile.existsSync(),
        isTrue,
        reason: 'web/index.html should exist',
      );
      content = indexFile.readAsStringSync();
    });

    test('index.html should contain the loading indicator', () {
      expect(content, contains('<div id="loading-indicator" class="loading">'));
      expect(content, contains('<img src="logo.png" alt="Loading..." />'));
    });

    test('index.html should have the loading styles', () {
      expect(content, contains('.loading {'));
      expect(content, contains('.loading img {'));
      expect(content, contains('@keyframes pulse {'));
    });

    test('index.html should have correctly wrapped scripts', () {
      // Ensure we don't have the raw JS text outside of a script tag
      // which was the previous issue.
      expect(content, contains('<script>'));
      expect(content, contains('// PWA Update Detection'));
      expect(
        content,
        contains('window.addEventListener(\'load\', function () {'),
      );

      // Specifically check if the comment before the script is NOT naked
      // In the broken version, it was:
      // // We rely on standard flutter_bootstrap.js...
      // but it should be inside a <script> tag.

      final scriptIndex = content.indexOf('<script>');
      final logicIndex = content.indexOf(
        '// We rely on standard flutter_bootstrap.js',
      );

      expect(
        logicIndex,
        greaterThan(scriptIndex),
        reason:
            'PWA logic index ($logicIndex) should be after a <script> tag opening index ($scriptIndex)',
      );
    });

    test('index.html should contain Flutter bootstrap', () {
      expect(
        content,
        contains('<script src="flutter_bootstrap.js" async></script>'),
      );
    });
  });
}
