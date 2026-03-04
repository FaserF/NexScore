import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/models/session_model.dart';

void main() {
  group('Player Model', () {
    test('toMap and fromMap round-trip correctly', () {
      const player = Player(
        id: 'uuid-001',
        name: 'Alice',
        avatarColor: '#FF5733',
        ownerUid: 'user-abc',
        isDeleted: false,
      );

      final map = player.toMap();
      final restored = Player.fromMap(map);

      expect(restored.id, player.id);
      expect(restored.name, player.name);
      expect(restored.avatarColor, player.avatarColor);
      expect(restored.ownerUid, player.ownerUid);
      expect(restored.isDeleted, player.isDeleted);
    });

    test('copyWith updates only specified fields', () {
      const player = Player(id: 'p1', name: 'Bob', avatarColor: '#000000');
      final updated = player.copyWith(name: 'Charlie');

      expect(updated.id, 'p1');
      expect(updated.name, 'Charlie');
      expect(updated.avatarColor, '#000000');
      expect(updated.ownerUid, isNull);
    });

    test('isDeleted defaults to false', () {
      const player = Player(id: 'p2', name: 'Dan', avatarColor: '#FFFFFF');
      expect(player.isDeleted, false);
    });
  });

  group('Session Model', () {
    final session = Session(
      id: 'session-001',
      gameType: 'wizard',
      startTime: DateTime(2026, 3, 4, 18, 0),
      endTime: DateTime(2026, 3, 4, 19, 0),
      durationSeconds: 3600,
      players: ['p1', 'p2', 'p3'],
      scores: {'p1': 120, 'p2': 85, 'p3': 60},
      gameData: {'rounds': 5},
      ownerUid: null,
      completed: true,
    );

    test('toMap and fromMap round-trip correctly', () {
      final map = session.toMap();
      final restored = Session.fromMap(map);

      expect(restored.id, session.id);
      expect(restored.gameType, session.gameType);
      expect(restored.startTime, session.startTime);
      expect(restored.endTime, session.endTime);
      expect(restored.durationSeconds, session.durationSeconds);
      expect(restored.players, session.players);
      expect(restored.scores, session.scores);
      expect(restored.completed, session.completed);
    });

    test('copyWith updates only specified fields', () {
      final updated = session.copyWith(completed: false, durationSeconds: 7200);

      expect(updated.id, session.id);
      expect(updated.completed, false);
      expect(updated.durationSeconds, 7200);
      expect(updated.gameType, session.gameType);
    });

    test('scores map preserves player ordering', () {
      final map = session.toMap();
      final restored = Session.fromMap(map);
      expect(restored.scores['p1'], 120);
      expect(restored.scores['p2'], 85);
      expect(restored.scores['p3'], 60);
    });
  });
}
