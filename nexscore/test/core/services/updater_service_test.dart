import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/services/updater_service.dart';

void main() {
  group('BuiltInUpdaterService - Version Parsing & Comparison Logic', () {
    // Accessing private helper logic via test wrappers or mock endpoints is preferred,
    // but we can test the public update channel logic directly by asserting version comparison.
    
    test('isVersionNewer correctly compares major, minor, patch', () {
      // Test cases using exposed public methods directly
      expect(BuiltInUpdaterService.isVersionNewer(
        BuiltInUpdaterService.parseVersionString('1.0.0'),
        BuiltInUpdaterService.parseVersionString('2.0.0'),
      ), isTrue);
      
      expect(BuiltInUpdaterService.isVersionNewer(
        BuiltInUpdaterService.parseVersionString('1.1.0'),
        BuiltInUpdaterService.parseVersionString('1.2.0'),
      ), isTrue);
      
      expect(BuiltInUpdaterService.isVersionNewer(
        BuiltInUpdaterService.parseVersionString('1.0.0'),
        BuiltInUpdaterService.parseVersionString('1.0.1'),
      ), isTrue);
      
      expect(BuiltInUpdaterService.isVersionNewer(
        BuiltInUpdaterService.parseVersionString('1.0.0'),
        BuiltInUpdaterService.parseVersionString('1.0.0'),
      ), isFalse);
      
      expect(BuiltInUpdaterService.isVersionNewer(
        BuiltInUpdaterService.parseVersionString('2.0.0'),
        BuiltInUpdaterService.parseVersionString('1.9.9'),
      ), isFalse);
    });

    test('GitHubRelease JSON parsing assigns correctly', () {
      final json = {
        'tag_name': 'v1.2.3-beta.0',
        'html_url': 'https://github.com/FaserF/NexScore/releases/tag/v1.2.3-beta.0',
        'body': 'This is a test beta release',
        'prerelease': true,
        'assets': [
          {
            'name': 'NexScore-v1.2.3-beta.0.apk',
            'browser_download_url': 'https://github.com/download/apk'
          },
          {
            'name': 'NexScore-v1.2.3-beta.0.ipa',
            'browser_download_url': 'https://github.com/download/ipa'
          }
        ]
      };

      final release = GitHubRelease.fromJson(json);

      expect(release.tagName, equals('v1.2.3-beta.0'));
      expect(release.htmlUrl, equals('https://github.com/FaserF/NexScore/releases/tag/v1.2.3-beta.0'));
      expect(release.body, equals('This is a test beta release'));
      expect(release.isPrerelease, isTrue);
      expect(release.apkUrl, equals('https://github.com/download/apk'));
      expect(release.ipaUrl, equals('https://github.com/download/ipa'));
    });
  });
}
