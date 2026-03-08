import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    _log('INFO', message, tag, metadata);
  }

  static void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? metadata,
  }) {
    _log('WARN', message, tag, metadata);
  }

  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    _log('ERROR', message, tag, {
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      ...?metadata,
    });
  }

  static void _log(
    String level,
    String message,
    String? tag,
    Map<String, dynamic>? metadata,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final tagPart = tag != null ? '[$tag] ' : '';
    final metadataPart = metadata != null ? ' | data: $metadata' : '';

    final formattedMessage =
        '$timestamp | $level | $tagPart$message$metadataPart';

    if (kDebugMode || level == 'ERROR') {
      debugPrint(formattedMessage);
    }

    dev.log(
      message,
      name: tag ?? 'App',
      level: _levelToInt(level),
      time: DateTime.now(),
      error: metadata?['error'],
      stackTrace: metadata?['stackTrace'] != null
          ? StackTrace.fromString(metadata!['stackTrace'])
          : null,
    );
  }

  static int _levelToInt(String level) {
    switch (level) {
      case 'INFO':
        return 800;
      case 'WARN':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 0;
    }
  }
}
