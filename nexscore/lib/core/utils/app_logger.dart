import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

class AppLogger {
  static final List<String> _logs = [];
  static bool debugMode = false; // synced from SettingsProvider

  /// Adds a raw log string to the memory buffer.
  /// (Printing logic is handled in main.dart's debugPrint override)
  static void addLog(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logLine = '[$timestamp] $message';
    _logs.add(logLine);

    // Bounded buffer
    if (_logs.length > 5000) {
      _logs.removeRange(0, 1000);
    }
  }

  @visibleForTesting
  static List<String> get debugLogs => List.unmodifiable(_logs);

  @visibleForTesting
  static void clearLogs() => _logs.clear();

  /// Exports the logs as a text file cross-platform.
  static Future<void> exportLogs() async {
    final data = _logs.join('\n');
    final bytes = utf8.encode(data);
    final xFile = XFile.fromData(
      Uint8List.fromList(bytes),
      mimeType: 'text/plain',
      name: 'nexscore_logs.txt',
    );

    await Share.shareXFiles([xFile], subject: 'NexScore Debug Logs');
  }
}
