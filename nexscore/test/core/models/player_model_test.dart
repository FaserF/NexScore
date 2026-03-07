import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/models/player_model.dart';

void main() {
  group('Player Model Tests', () {
    test('Player serialization with emoji', () {
      final player = Player(
        id: '1',
        name: 'Test',
        avatarColor: '#FF0000',
        emoji: '😀',
      );

      final map = player.toMap();
      expect(map['emoji'], '😀');

      final fromMap = Player.fromMap(map);
      expect(fromMap.emoji, '😀');
    });

    test('Player serialization without emoji', () {
      final player = Player(id: '2', name: 'Test 2', avatarColor: '#00FF00');

      final map = player.toMap();
      expect(map['emoji'], isNull);

      final fromMap = Player.fromMap(map);
      expect(fromMap.emoji, isNull);
    });

    test('Player copyWith emoji', () {
      final player = Player(id: '3', name: 'Test 3', avatarColor: '#0000FF');

      final updated = player.copyWith(emoji: '🎮');
      expect(updated.emoji, '🎮');
      expect(updated.name, 'Test 3');
    });
  });
}
