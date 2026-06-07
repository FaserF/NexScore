import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

enum ApkVerificationResult {
  valid,
  mismatch,
  networkError,
  notAndroid,
  unknownError
}

class ApkVerificationService {
  static const _channel = MethodChannel('de.fabiseitz.nex_score/apk_verification');
  
  static const String _apiRepoUrl = String.fromEnvironment(
    'GITHUB_REPOSITORY_URL',
    defaultValue: 'https://api.github.com/repos/FaserF/NexScore',
  );

  static String get _downloadBaseUrl {
    var url = _apiRepoUrl;
    if (url.startsWith('https://api.github.com/repos/')) {
      url = url.replaceFirst('https://api.github.com/repos/', 'https://github.com/');
    }
    return url;
  }

  /// Verifies the local APK signature against the GitHub Releases checksum.
  static Future<ApkVerificationResult> verifyApk() async {
    if (kIsWeb || !Platform.isAndroid) {
      return ApkVerificationResult.notAndroid;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;

      final url = '$_downloadBaseUrl/releases/download/v$version/NexScore-v$version.apk.sha256';
      AppLogger.addLog('APK verification: Fetching remote SHA from $url');
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 404) {
        AppLogger.addLog('APK verification: Remote SHA256 not found (404). Assuming debug or local build.');
        return ApkVerificationResult.valid;
      }

      if (response.statusCode != 200) {
        AppLogger.addLog('APK verification: Network error ${response.statusCode} fetching remote SHA');
        return ApkVerificationResult.networkError;
      }

      final remoteSha = response.body.trim().toLowerCase().split(' ').first;
      if (remoteSha.isEmpty) {
        AppLogger.addLog('APK verification: Empty remote SHA');
        return ApkVerificationResult.networkError;
      }

      AppLogger.addLog('APK verification: Computing local APK SHA256...');
      final String? localSha = await _channel.invokeMethod<String>('getApkSha256');
      if (localSha == null) {
        AppLogger.addLog('APK verification: Failed to calculate local APK SHA');
        return ApkVerificationResult.unknownError;
      }
      
      final cleanLocalSha = localSha.trim().toLowerCase();
      AppLogger.addLog('APK verification: Remote SHA: $remoteSha');
      AppLogger.addLog('APK verification: Local SHA:  $cleanLocalSha');

      if (remoteSha == cleanLocalSha) {
        AppLogger.addLog('APK verification: Success! SHA hashes match.');
        return ApkVerificationResult.valid;
      } else {
        AppLogger.addLog('APK verification: WARNING! Hash mismatch!');
        return ApkVerificationResult.mismatch;
      }
    } on SocketException catch (e) {
      AppLogger.addLog('APK verification network error: SocketException: $e');
      return ApkVerificationResult.networkError;
    } on http.ClientException catch (e) {
      AppLogger.addLog('APK verification network error: ClientException: $e');
      return ApkVerificationResult.networkError;
    } catch (e) {
      AppLogger.addLog('APK verification error: $e');
      return ApkVerificationResult.unknownError;
    }
  }
}

// A notifier/provider to perform the check once and cache the state.
final apkVerificationProvider = NotifierProvider<ApkVerificationNotifier, AsyncValue<ApkVerificationResult>>(
  ApkVerificationNotifier.new,
);

class ApkVerificationNotifier extends Notifier<AsyncValue<ApkVerificationResult>> {
  @override
  AsyncValue<ApkVerificationResult> build() {
    checkVerification();
    return const AsyncValue.loading();
  }

  Future<void> checkVerification() async {
    state = const AsyncValue.loading();
    try {
      final result = await ApkVerificationService.verifyApk();
      state = AsyncValue.data(result);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
