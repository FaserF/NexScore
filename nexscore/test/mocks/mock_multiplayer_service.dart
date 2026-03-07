import 'dart:async';
import 'package:nexscore/core/multiplayer/models/lobby.dart';
import 'package:nexscore/core/multiplayer/multiplayer_service.dart';

class MockMultiplayerService implements MultiplayerService {
  final _lobbyStreamController = StreamController<Lobby?>.broadcast();
  Lobby? _currentLobby;

  @override
  bool get isHost => false;

  @override
  Lobby? get currentLobby => _currentLobby;

  @override
  Stream<Lobby?> get lobbyUpdates => _lobbyStreamController.stream;

  @override
  Future<String> hostLobby({
    required String hostName,
    required String hostAvatarColor,
    int maxPlayers = 10,
  }) async {
    return 'MOCK1';
  }

  @override
  Future<void> joinLobby({
    required String roomCode,
    required String playerName,
    required String playerAvatarColor,
  }) async {
    // No-op in mock
  }

  @override
  Future<void> leaveLobby() async {
    _currentLobby = null;
    _lobbyStreamController.add(null);
  }

  @override
  Future<void> syncGameState(Map<String, dynamic> state) async {
    // No-op in mock
  }

  @override
  Future<void> sendEvent(String eventName, Map<String, dynamic> payload) async {
    // No-op in mock
  }

  void dispose() {
    _lobbyStreamController.close();
  }
}
