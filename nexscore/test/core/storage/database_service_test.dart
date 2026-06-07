import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/storage/database_service.dart';

void main() {
  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      // Clear database before each test to start fresh
      await dbService.clearDatabase();
    });

    tearDown(() async {
      await dbService.clearDatabase();
    });

    test('Database tables are created with the correct schemas', () async {
      final tables = await dbService.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
      );

      final tableNames = tables.map((t) => t['name'] as String).toList();
      expect(tableNames, contains('players'));
      expect(tableNames, contains('sessions'));
      expect(tableNames, contains('player_groups'));
    });

    test('Database indexes are created and verified', () async {
      final indexes = await dbService.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['index'],
      );

      final indexNames = indexes.map((i) => i['name'] as String).toList();
      expect(indexNames, contains('idx_players_is_deleted'));
      expect(indexNames, contains('idx_sessions_start_time'));
    });

    test('Players CRUD operations work correctly', () async {
      final player = {
        'id': 'player_1',
        'name': 'Alice',
        'avatarColor': '#FF0000',
        'emoji': '🎲',
        'ownerUid': 'user_123',
        'isDeleted': 0,
      };

      // Insert
      await dbService.insert('players', player);

      // Query
      var results = await dbService.query(
        'players',
        where: 'id = ?',
        whereArgs: ['player_1'],
      );
      expect(results.length, 1);
      expect(results.first['name'], 'Alice');
      expect(results.first['emoji'], '🎲');
      expect(results.first['isDeleted'], 0);

      // Update
      final updatedPlayer = {
        'id': 'player_1',
        'name': 'Alice Smith',
        'avatarColor': '#00FF00',
        'emoji': '🎯',
        'ownerUid': 'user_123',
        'isDeleted': 1,
      };
      await dbService.update(
        'players',
        updatedPlayer,
        where: 'id = ?',
        whereArgs: ['player_1'],
      );

      results = await dbService.query(
        'players',
        where: 'id = ?',
        whereArgs: ['player_1'],
      );
      expect(results.length, 1);
      expect(results.first['name'], 'Alice Smith');
      expect(results.first['emoji'], '🎯');
      expect(results.first['isDeleted'], 1);

      // Delete
      await dbService.delete(
        'players',
        where: 'id = ?',
        whereArgs: ['player_1'],
      );

      results = await dbService.query(
        'players',
        where: 'id = ?',
        whereArgs: ['player_1'],
      );
      expect(results.isEmpty, true);
    });

    test('Sessions CRUD operations work correctly', () async {
      final session = {
        'id': 'session_1',
        'gameType': 'sudoku',
        'startTime': '2026-06-07T12:00:00Z',
        'endTime': '2026-06-07T12:30:00Z',
        'durationSeconds': 1800,
        'players': '["player_1", "player_2"]',
        'scores': '{"player_1": 100, "player_2": 80}',
        'gameData': '{"difficulty": "medium"}',
        'ownerUid': 'user_123',
        'completed': 1,
      };

      // Insert
      await dbService.insert('sessions', session);

      // Query
      var results = await dbService.query(
        'sessions',
        where: 'id = ?',
        whereArgs: ['session_1'],
      );
      expect(results.length, 1);
      expect(results.first['gameType'], 'sudoku');
      expect(results.first['completed'], 1);

      // Update
      final updatedSession = Map<String, dynamic>.from(session);
      updatedSession['completed'] = 0;
      updatedSession['durationSeconds'] = 2000;
      await dbService.update(
        'sessions',
        updatedSession,
        where: 'id = ?',
        whereArgs: ['session_1'],
      );

      results = await dbService.query(
        'sessions',
        where: 'id = ?',
        whereArgs: ['session_1'],
      );
      expect(results.first['completed'], 0);
      expect(results.first['durationSeconds'], 2000);

      // Delete
      await dbService.delete(
        'sessions',
        where: 'id = ?',
        whereArgs: ['session_1'],
      );

      results = await dbService.query(
        'sessions',
        where: 'id = ?',
        whereArgs: ['session_1'],
      );
      expect(results.isEmpty, true);
    });

    test('Player groups CRUD operations work correctly', () async {
      final group = {
        'id': 'group_1',
        'name': 'Family',
        'playerIds': '["player_1", "player_2"]',
      };

      // Insert
      await dbService.insert('player_groups', group);

      // Query
      var results = await dbService.query(
        'player_groups',
        where: 'id = ?',
        whereArgs: ['group_1'],
      );
      expect(results.length, 1);
      expect(results.first['name'], 'Family');

      // Update
      final updatedGroup = {
        'id': 'group_1',
        'name': 'Friends',
        'playerIds': '["player_1", "player_3"]',
      };
      await dbService.update(
        'player_groups',
        updatedGroup,
        where: 'id = ?',
        whereArgs: ['group_1'],
      );

      results = await dbService.query(
        'player_groups',
        where: 'id = ?',
        whereArgs: ['group_1'],
      );
      expect(results.first['name'], 'Friends');
      expect(results.first['playerIds'], '["player_1", "player_3"]');

      // Delete
      await dbService.delete(
        'player_groups',
        where: 'id = ?',
        whereArgs: ['group_1'],
      );

      results = await dbService.query(
        'player_groups',
        where: 'id = ?',
        whereArgs: ['group_1'],
      );
      expect(results.isEmpty, true);
    });
  });
}
