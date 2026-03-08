import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/multiplayer/models/lobby.dart';
import 'package:nexscore/core/multiplayer/models/multiplayer_user.dart';

void main() {
  group('Lobby Model Tests', () {
    final now = DateTime.now();
    final user = MultiplayerUser(
      uid: 'user1',
      name: 'Host',
      avatarColor: '0xFF0000',
      isHost: true,
      lastActive: now,
    );

    final lobby = Lobby(
      id: 'ABCDE',
      hostUid: 'user1',
      maxPlayers: 5,
      state: LobbyState.waiting,
      users: {'user1': user},
      createdAt: now,
    );

    test('toMap and fromMap consistency', () {
      final map = lobby.toMap();
      final fromMap = Lobby.fromMap(map);

      expect(fromMap.id, lobby.id);
      expect(fromMap.hostUid, lobby.hostUid);
      expect(fromMap.maxPlayers, lobby.maxPlayers);
      expect(fromMap.state, lobby.state);
      expect(fromMap.users.length, lobby.users.length);
      expect(fromMap.users['user1']?.name, user.name);
      // DateTime might lose some precision in epoch conversion but should be close
      expect(
        fromMap.createdAt.millisecondsSinceEpoch,
        lobby.createdAt.millisecondsSinceEpoch,
      );
    });

    test('copyWith works correctly', () {
      final updated = lobby.copyWith(state: LobbyState.playing);
      expect(updated.state, LobbyState.playing);
      expect(updated.id, lobby.id);
    });

    test('LobbyState enum values', () {
      expect(LobbyState.waiting.name, 'waiting');
      expect(LobbyState.playing.name, 'playing');
      expect(LobbyState.closed.name, 'closed');
    });
  });
}
