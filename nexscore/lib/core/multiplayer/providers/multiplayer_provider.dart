import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore_multiplayer_impl.dart';
import '../models/lobby.dart';
import '../multiplayer_service.dart';
import '../sync_engine.dart';
import '../../models/player_model.dart';
import '../../providers/active_players_provider.dart';

/// Provides the singleton instance of the MultiplayerService
final multiplayerServiceProvider = Provider<MultiplayerService>((ref) {
  final service = FirestoreMultiplayerImpl();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provides a stream of the real-time Lobby object (if connected)
final lobbyStreamProvider = StreamProvider<Lobby?>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  return service.lobbyUpdates;
});

/// Convenience provider to watch the current Lobby state synchronously
final currentLobbyProvider = Provider<Lobby?>((ref) {
  final asyncLobby = ref.watch(lobbyStreamProvider);
  return asyncLobby.value;
});

/// Convenience provider to know if the current user is the host
final isHostProvider = Provider<bool>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  final currentLobby = ref.watch(currentLobbyProvider);
  // Re-evaluate whenever lobby changes
  return service.isHost;
});

/// Automatically synchronizes the players in the active lobby into the app's player list
final lobbyPlayerSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Lobby?>>(lobbyStreamProvider, (previous, next) {
    final lobby = next.value;
    if (lobby != null) {
      final mappedPlayers = lobby.users.values
          .map(
            (u) => Player(
              id: u.uid,
              name: u.name,
              avatarColor: u.avatarColor,
              ownerUid: u.isHost ? 'host' : u.uid,
            ),
          )
          .toList();

      // We must use Future.microtask to avoid modifying providers during build phase
      Future.microtask(() {
        ref.read(activePlayersProvider.notifier).setPlayers(mappedPlayers);
      });
    }
  });
});

/// Provides a SyncEngine instance for the current multiplayer session
final syncEngineProvider = Provider<SyncEngine>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  final engine = SyncEngine(service);
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// Stream provider for clients to receive the host's game state in real-time
final gameStateSyncProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.gameStateStream;
});
