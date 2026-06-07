import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';
import '../utils/app_version.dart';

class GitHubRelease {
  final String tagName;
  final String htmlUrl;
  final String body;
  final bool isPrerelease;
  final String? apkUrl;
  final String? ipaUrl;

  GitHubRelease({
    required this.tagName,
    required this.htmlUrl,
    required this.body,
    required this.isPrerelease,
    this.apkUrl,
    this.ipaUrl,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    String? apk;
    String? ipa;
    final assets = json['assets'] as List<dynamic>? ?? [];
    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      final url = asset['browser_download_url'] as String?;
      if (name.endsWith('.apk')) {
        apk = url;
      } else if (name.endsWith('.ipa')) {
        ipa = url;
      }
    }

    return GitHubRelease(
      tagName: json['tag_name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isPrerelease: json['prerelease'] as bool? ?? false,
      apkUrl: apk,
      ipaUrl: ipa,
    );
  }
}

class BuiltInUpdaterService {
  static const String _repoUrl = String.fromEnvironment(
    'GITHUB_REPOSITORY_URL',
    defaultValue: 'https://api.github.com/repos/FaserF/NexScore',
  ) + '/releases';

  /// Determines if the app was installed from an official App Store / Play Store.
  /// Returns true if it's sideloaded (or run locally in debug/release).
  static Future<bool> isSideloaded() async {
    if (kIsWeb) return false;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final installer = packageInfo.installerStore;
      
      // If installerStore is null or empty, or doesn't match standard store names,
      // it is considered sideloaded.
      if (installer == null || installer.isEmpty) {
        return true;
      }

      final stores = [
        'com.android.vending', // Google Play Store
        'com.apple.AppStore',  // Apple App Store
        'com.sec.android.app.samsungapps', // Samsung Galaxy Store
        'com.huawei.appmarket', // Huawei AppGallery
        'com.amazon.venezia', // Amazon Appstore
      ];

      return !stores.contains(installer);
    } catch (e) {
      AppLogger.error('Failed to detect installer store: $e');
      return true; // Fallback to true to allow updater
    }
  }

  /// Checks for newer versions on GitHub based on the configured channel.
  static Future<GitHubRelease?> checkForUpdates(String channel) async {
    try {
      final response = await http.get(Uri.parse(_repoUrl));
      if (response.statusCode != 200) {
        AppLogger.error('Failed to fetch releases: ${response.statusCode}');
        return null;
      }

      final List<dynamic> releasesJson = json.decode(response.body);
      final releases = releasesJson.map((r) => GitHubRelease.fromJson(r)).toList();

      final currentVerStr = AppVersion.current.split('+').first; // Remove build number
      final currentVer = parseVersionString(currentVerStr);

      for (final release in releases) {
        final relVerStr = release.tagName.replaceFirst('v', '').split('+').first;
        final relVer = parseVersionString(relVerStr);

        // If release version is older or same, ignore
        if (!isVersionNewer(currentVer, relVer)) continue;

        // Apply channel filtering rules:
        // stable: only non-prerelease tags
        // beta: beta tags or newer stable tags
        // dev: any newer tag
        if (channel == 'stable') {
          if (release.isPrerelease) continue;
        } else if (channel == 'beta') {
          // Allow beta releases or stable releases (non-prerelease)
          final isBetaTag = release.tagName.contains('beta') || release.tagName.contains('b');
          if (release.isPrerelease && !isBetaTag) continue;
        }

        // Return the first matching newer release
        return release;
      }
    } catch (e) {
      AppLogger.error('Error checking for updates: $e');
    }
    return null;
  }

  /// Initiates update download/install depending on the platform.
  static Future<void> performUpdate(GitHubRelease release) async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final url = release.apkUrl;
      if (url == null) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else if (Platform.isIOS) {
      final url = release.ipaUrl ?? release.htmlUrl;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Internal helper to parse semantic version numbers.
  static List<int> parseVersionString(String ver) {
    try {
      // Remove trailing tags e.g. -beta.0 or -dev0
      final cleanVer = ver.split('-').first.split('b').first;
      final parts = cleanVer.split('.').map(int.parse).toList();
      while (parts.length < 3) {
        parts.add(0);
      }
      return parts;
    } catch (_) {
      return [0, 0, 0];
    }
  }

  /// Check if candidate version is newer than current version.
  static bool isVersionNewer(List<int> current, List<int> candidate) {
    for (int i = 0; i < 3; i++) {
      if (candidate[i] > current[i]) return true;
      if (candidate[i] < current[i]) return false;
    }
    return false; // Equal
  }
}
