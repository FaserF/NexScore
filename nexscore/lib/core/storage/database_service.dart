import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    await db.execute('''
CREATE TABLE players (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  avatarColor TEXT NOT NULL,
  ownerUid TEXT,
  isDeleted INTEGER NOT NULL DEFAULT 0
)
''');
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
  }

  // --- Platform Agnostic CRUD ---

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    if (kIsWeb) {
      var results = List<Map<String, dynamic>>.from(_webDb[table] ?? []);
      // Simple filtering for 'isDeleted = 0' as used in players
      if (where?.contains('isDeleted = ?') ?? false) {
        results = results.where((e) => e['isDeleted'] == 0).toList();
      }
      return results;
    }
    final db = await _db;
    return await db!.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  Future<void> insert(String table, Map<String, dynamic> values) async {
    if (kIsWeb) {
      _webDb[table]!.add(values);
      return;
    }
    final db = await _db;
    await db!.insert(
      table,
      values,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (kIsWeb) {
      final id = values['id'] ?? whereArgs?.first;
      final index = _webDb[table]!.indexWhere((e) => e['id'] == id);
      if (index != -1) {
        _webDb[table]![index] = {..._webDb[table]![index], ...values};
      }
      return;
    }
    final db = await _db;
    await db!.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<void> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    if (kIsWeb) {
      final id = whereArgs?.first;
      _webDb[table]!.removeWhere((e) => e['id'] == id);
      return;
    }
    final db = await _db;
    await db!.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> clearDatabase() async {
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
  }
}
