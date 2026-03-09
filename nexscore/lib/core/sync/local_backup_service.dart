import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/database_service.dart';
import '../../features/settings/provider/settings_provider.dart';
import '../utils/logger.dart';
import 'local_backup_stub.dart' if (dart.library.html) 'local_backup_web.dart';

class LocalBackupService {
  final Ref? ref;
  LocalBackupService({this.ref});

  Future<void> exportBackup() async {
    final stopwatch = Stopwatch()..start();
    try {
      final data = await _buildPayload();
      final jsonString = jsonEncode(data);
      final bytes = utf8.encode(jsonString);
      final fileName =
          'nexscore_backup_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0]}.json';

      if (kIsWeb) {
        _downloadWeb(bytes, fileName);
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save NexScore Backup',
          fileName: fileName,
          bytes: bytes,
        );
        if (result != null) {
          AppLogger.info('Backup saved to $result', tag: 'LocalBackup');
        }
      }

      if (ref != null) {
        ref!
            .read(settingsProvider.notifier)
            .updateLastBackupMetadata(DateTime.now(), 'local');
      }

      AppLogger.info(
        'Local backup export complete',
        tag: 'LocalBackup',
        metadata: {'duration': '${stopwatch.elapsedMilliseconds}ms'},
      );
    } catch (e, stack) {
      AppLogger.error(
        'Local backup export failed',
        tag: 'LocalBackup',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<bool> importBackup() async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return false;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return false;

      final jsonString = utf8.decode(bytes);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      await _importData(data);

      AppLogger.info(
        'Local backup import complete',
        tag: 'LocalBackup',
        metadata: {'duration': '${stopwatch.elapsedMilliseconds}ms'},
      );
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'Local backup import failed',
        tag: 'LocalBackup',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  void _downloadWeb(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      downloadWeb(bytes, fileName);
    }
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final db = DatabaseService.instance;
    final players = await db.query('players');
    final sessions = await db.query('sessions');
    final groups = await db.query('player_groups');

    return {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'source': 'nexscore_local',
      'players': players,
      'sessions': sessions,
      'player_groups': groups,
    };
  }

  Future<void> _importData(Map<String, dynamic> data) async {
    final db = DatabaseService.instance;

    // Optional: Clear existing data or merge?
    // GistSyncService uses 'replace' conflict algorithm, so we merge by ID.

    final players = (data['players'] as List<dynamic>?) ?? [];
    for (final p in players) {
      await db.insert('players', Map<String, dynamic>.from(p as Map));
    }

    final sessions = (data['sessions'] as List<dynamic>?) ?? [];
    for (final s in sessions) {
      await db.insert('sessions', Map<String, dynamic>.from(s as Map));
    }

    final groups = (data['player_groups'] as List<dynamic>?) ?? [];
    for (final g in groups) {
      await db.insert('player_groups', Map<String, dynamic>.from(g as Map));
    }
  }
}

final localBackupServiceProvider = Provider(
  (ref) => LocalBackupService(ref: ref),
);
