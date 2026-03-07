import 'models/lobby.dart';

abstract class MultiplayerService {
  /// Whether the current user is hosting a lobby
  bool get isHost;

  /// The current active lobby if connected
  Lobby? get currentLobby;

  /// Stream of lobby updates for real-time reactivity
  Stream<Lobby?> get lobbyUpdates;

  /// Creates a new lobby and becomes the host
  /// Returns the randomly generated 5-digit room code
  Future<String> hostLobby({
    required String hostName,
    required String hostAvatarColor,
    int maxPlayers = 10,
  });

  /// Joins an existing lobby via the 5-digit room code
  Future<void> joinLobby({
    required String roomCode,
    required String playerName,
    required String playerAvatarColor,
  });

  /// Leaves or destroys the current lobby
  Future<void> leaveLobby();

  /// Pushes a new game state map to the lobby document. Only host should do this.
  Future<void> syncGameState(Map<String, dynamic> state);

  /// Sends a targeted event payload if supported. E.g. client sending drink adjustment.
  Future<void> sendEvent(String eventName, Map<String, dynamic> payload);
}
