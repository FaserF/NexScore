import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sharing Standardization Integrity Tests', () {
    test('All files should use the standardized Share API', () {
      final libDir = Directory('lib');
      final entities = libDir.listSync(recursive: true);
      
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final content = entity.readAsStringSync();
          
          // Should use SharePlus.instance.share (standard in our project now)
          if (content.contains('Share.shareXFiles')) {
            fail('File ${entity.path} uses the deprecated Share.shareXFiles. Use SharePlus.instance.share instead.');
          }
          
          // If it contains Share.share, it should probably be Share.shareXFiles or Share.share
          // but we specifically standardized on Share.shareXFiles for images/logs.
          if (content.contains('share_plus.dart') && !content.contains('Share.share')) {
              // This is just a warning/check
          }
        }
      }
    });
  });
}
