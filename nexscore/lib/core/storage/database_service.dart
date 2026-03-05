import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/logger.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // Web-only in-memory storage
  final Map<String, List<Map<String, dynamic>>> _webDb = {
    'players': [],
    'sessions': [],
  };

  static const _dbName = 'nexscore.db';

  DatabaseService._init();

  Future<Database?> get _db async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    AppLogger.info('Creating database tables and indexes...', tag: 'Database');
    await db.execute('''
CREATE TABLE players (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  avatarColor TEXT NOT NULL,
  ownerUid TEXT,
  isDeleted INTEGER NOT NULL DEFAULT 0
)
''');
    await db.execute(
      'CREATE INDEX idx_players_is_deleted ON players(isDeleted)',
    );

    await db.execute('''
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  gameType TEXT NOT NULL,
  startTime TEXT NOT NULL,
  endTime TEXT,
  durationSeconds INTEGER NOT NULL DEFAULT 0,
  players TEXT NOT NULL,
  scores TEXT NOT NULL,
  gameData TEXT NOT NULL,
  ownerUid TEXT,
  completed INTEGER NOT NULL DEFAULT 0
)
''');
    await db.execute(
      'CREATE INDEX idx_sessions_start_time ON sessions(startTime)',
    );
    AppLogger.info('Database initialization complete.', tag: 'Database');
  }

  // --- Platform Agnostic CRUD ---

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      List<Map<String, dynamic>> results;
      if (kIsWeb) {
        results = List<Map<String, dynamic>>.from(_webDb[table] ?? []);
        if (where?.contains('isDeleted = ?') ?? false) {
          results = results.where((e) => e['isDeleted'] == 0).toList();
        }
      } else {
        final db = await _db;
        results = await db!.query(
          table,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
        );
      }
      AppLogger.info(
        'Query $table complete',
        tag: 'Database',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'count': results.length,
          'where': ?where,
        },
      );
      return results;
    } catch (e, stack) {
      AppLogger.error(
        'Query $table failed',
        tag: 'Database',
        error: e,
        stackTrace: stack,
        metadata: {'where': where},
      );
      rethrow;
    }
  }

  Future<void> insert(String table, Map<String, dynamic> values) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (kIsWeb) {
        _webDb[table]!.add(values);
      } else {
        final db = await _db;
        await db!.insert(
          table,
          values,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      AppLogger.info(
        'Insert into $table complete',
        tag: 'Database',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'id': values['id'],
        },
      );
    } catch (e, stack) {
      AppLogger.error(
        'Insert into $table failed',
        tag: 'Database',
        error: e,
        stackTrace: stack,
        metadata: {'id': values['id']},
      );
      rethrow;
    }
  }

  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (kIsWeb) {
        final id = values['id'] ?? whereArgs?.first;
        final index = _webDb[table]!.indexWhere((e) => e['id'] == id);
        if (index != -1) {
          _webDb[table]![index] = {..._webDb[table]![index], ...values};
        }
      } else {
        final db = await _db;
        await db!.update(table, values, where: where, whereArgs: whereArgs);
      }
      AppLogger.info(
        'Update $table complete',
        tag: 'Database',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'where': ?where,
        },
      );
    } catch (e, stack) {
      AppLogger.error(
        'Update $table failed',
        tag: 'Database',
        error: e,
        stackTrace: stack,
        metadata: {'where': where},
      );
      rethrow;
    }
  }

  Future<void> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      if (kIsWeb) {
        final id = whereArgs?.first;
        _webDb[table]!.removeWhere((e) => e['id'] == id);
      } else {
        final db = await _db;
        await db!.delete(table, where: where, whereArgs: whereArgs);
      }
      AppLogger.info(
        'Delete from $table complete',
        tag: 'Database',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'where': ?where,
        },
      );
    } catch (e, stack) {
      AppLogger.error(
        'Delete from $table failed',
        tag: 'Database',
        error: e,
        stackTrace: stack,
        metadata: {'where': where},
      );
      rethrow;
    }
  }

  Future<void> clearDatabase() async {
    AppLogger.warning('Clearing entire database!', tag: 'Database');
    if (kIsWeb) {
      _webDb['players']!.clear();
      _webDb['sessions']!.clear();
      return;
    }
    final db = await _db;
    await db!.delete('players');
    await db.delete('sessions');
  }

  Future<void> close() async {
    if (kIsWeb) return;
    final db = await _db;
    await db?.close();
    AppLogger.info('Database closed.', tag: 'Database');
  }
}
