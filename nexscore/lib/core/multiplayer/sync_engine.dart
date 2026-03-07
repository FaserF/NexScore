import 'dart:async';
import 'multiplayer_service.dart';

/// The SyncEngine is responsible for serializing the host's game state
/// and pushing it to Firestore, where clients receive it via streams.
///
/// Host: Calls [pushState] whenever local game state changes.
/// Client: Listens to [lobbyUpdates] and extracts the `gameState` field.
class SyncEngine {
  final MultiplayerService _service;
  Timer? _debounceTimer;

  SyncEngine(this._service);

  /// Push the host's current game state to the Firestore lobby document.
  /// Debounces by 100ms to avoid excessive writes during rapid state changes.
  void pushState(Map<String, dynamic> state) {
    if (!_service.isHost) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      _service.syncGameState(state);
    });
  }

  /// Returns a stream of game state maps that the client can listen to.
  /// Filters out null lobbies and null game states.
  Stream<Map<String, dynamic>> get gameStateStream {
    return _service.lobbyUpdates
        .where((lobby) => lobby != null && lobby.gameState != null)
        .map((lobby) => lobby!.gameState!);
  }

  /// Sends a client event (e.g. drink counter adjustment) to the host
  /// via the Firestore events subcollection.
  Future<void> sendClientEvent(String eventName, Map<String, dynamic> payload) {
    return _service.sendEvent(eventName, payload);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}
