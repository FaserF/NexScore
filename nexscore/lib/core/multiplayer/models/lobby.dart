import 'multiplayer_user.dart';

enum LobbyState { waiting, playing, closed }

class Lobby {
  final String id; // the 5-digit room code
  final String hostUid;
  final int maxPlayers;
  final LobbyState state;
  final Map<String, MultiplayerUser> users; // map of uid -> MultiplayerUser
  final Map<String, dynamic>? gameState; // The synchronized game state JSON
  final DateTime createdAt;

  const Lobby({
    required this.id,
    required this.hostUid,
    required this.maxPlayers,
    this.state = LobbyState.waiting,
    required this.users,
    this.gameState,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostUid': hostUid,
      'maxPlayers': maxPlayers,
      'state': state.name,
      'users': users.map((k, v) => MapEntry(k, v.toMap())),
      'gameState': gameState,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Lobby.fromMap(Map<String, dynamic> map) {
    final usersMap = map['users'] as Map<String, dynamic>? ?? {};
    final users = usersMap.map(
      (k, v) => MapEntry(k, MultiplayerUser.fromMap(v as Map<String, dynamic>)),
    );

    return Lobby(
      id: map['id'] as String,
      hostUid: map['hostUid'] as String,
      maxPlayers: map['maxPlayers'] as int? ?? 10,
      state: LobbyState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => LobbyState.waiting,
      ),
      users: users,
      gameState: map['gameState'] as Map<String, dynamic>?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
    );
  }

  Lobby copyWith({
    String? id,
    String? hostUid,
    int? maxPlayers,
    LobbyState? state,
    Map<String, MultiplayerUser>? users,
    Map<String, dynamic>? gameState,
    DateTime? createdAt,
  }) {
    return Lobby(
      id: id ?? this.id,
      hostUid: hostUid ?? this.hostUid,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      state: state ?? this.state,
      users: users ?? this.users,
      gameState: gameState ?? this.gameState,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
