import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/multiplayer/models/multiplayer_user.dart';

void main() {
  group('MultiplayerUser Model Tests', () {
    final now = DateTime.now();

    test('toMap and fromMap consistency', () {
      final user = MultiplayerUser(
        uid: 'user123',
        name: 'Test Player',
        avatarColor: '0xFF00FF',
        isHost: true,
        lastActive: now,
      );

      final map = user.toMap();
      final fromMap = MultiplayerUser.fromMap(map);

      expect(fromMap.uid, user.uid);
      expect(fromMap.name, user.name);
      expect(fromMap.avatarColor, user.avatarColor);
      expect(fromMap.isHost, user.isHost);
      expect(
        fromMap.lastActive.millisecondsSinceEpoch,
        user.lastActive.millisecondsSinceEpoch,
      );
    });

    test('copyWith works correctly', () {
      final user = MultiplayerUser(
        uid: 'user123',
        name: 'Test Player',
        avatarColor: '0xFF00FF',
        isHost: false,
        lastActive: now,
      );

      final updated = user.copyWith(name: 'New Name', isHost: true);

      expect(updated.name, 'New Name');
      expect(updated.isHost, true);
      expect(updated.uid, user.uid);
    });
  });
}
