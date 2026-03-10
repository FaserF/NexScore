import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PWA External Link Integrity Tests', () {
    test('All launchUrl calls should use LaunchMode.externalApplication', () {
      final libDir = Directory('lib');
      final entities = libDir.listSync(recursive: true);
      
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          
          if (content.contains('launchUrl(') && !content.contains('url_launcher_string.dart')) {
            if (!content.contains('LaunchMode.externalApplication')) {
              // Some links might be mailto: or tel: which don't necessarily need externalApplication,
              // but for our PWA docs fix, they all should.
              fail('File ${entity.path} contains launchUrl without LaunchMode.externalApplication. This breaks PWA navigation.');
            }
          }
        }
      }
    });
  });
}
