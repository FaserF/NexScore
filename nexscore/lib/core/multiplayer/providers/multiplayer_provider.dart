import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore_multiplayer_impl.dart';
import '../models/lobby.dart';
import '../multiplayer_service.dart';
import '../sync_engine.dart';
import '../../models/player_model.dart';
import '../../providers/active_players_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

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
  // Ensure peripheral listeners are active whenever the lobby is watched
  ref.watch(lobbyPlayerSyncProvider);
  ref.watch(lobbyNotificationTriggersProvider);
  ref.watch(turnNotificationTriggersProvider);

  final asyncLobby = ref.watch(lobbyStreamProvider);
  return asyncLobby.value;
});

/// Convenience provider to know if the current user is the host
final isHostProvider = Provider<bool>((ref) {
  final service = ref.watch(multiplayerServiceProvider);
  ref.watch(lobbyStreamProvider);
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

/// Listens for lobby updates and triggers notifications
final lobbyNotificationTriggersProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Lobby?>>(lobbyStreamProvider, (previous, next) async {
    final previousLobby = previous?.value;
    final lobby = next.value;
    if (lobby == null) return;

    final notifService = ref.read(notificationServiceProvider);
    
    // Check if a new user joined (if we are the host)
    final isHost = ref.read(isHostProvider);
    if (isHost && previousLobby != null) {
      if (lobby.users.length > previousLobby.users.length) {
        // Find who joined
        final newUids = lobby.users.keys.where((uid) => !previousLobby.users.containsKey(uid));
        for (final uid in newUids) {
          final newName = lobby.users[uid]?.name ?? 'A user';
          await notifService.showNotification(
            id: uid.hashCode,
            title: 'New Player Joined',
            body: '$newName joined your lobby.',
          );
        }
      }
    }

    // Check if the game started (for clients and host)
    if (previousLobby != null && 
        previousLobby.state == LobbyState.waiting && 
        lobby.state == LobbyState.playing) {
      await notifService.showNotification(
        id: lobby.id.hashCode,
        title: 'Game Started',
        body: 'The host has started the game!',
      );
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

/// Listens for turn changes in the active game and triggers notifications
final turnNotificationTriggersProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Map<String, dynamic>>>(gameStateSyncProvider, (previous, next) async {
    final prev = previous?.value;
    final curr = next.value;

    if (curr == null) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    bool isMyTurn(Map<String, dynamic>? state) {
      if (state == null) return false;
      if (state['currentPlayerId'] == currentUserId) return true;
      if (state['activePlayerId'] == currentUserId) return true;
      final activeIds = state['activePlayerIds'];
      if (activeIds is List && activeIds.contains(currentUserId)) return true;
      return false;
    }

    final wasMyTurn = isMyTurn(prev);
    final isNowMyTurn = isMyTurn(curr);

    if (!wasMyTurn && isNowMyTurn) {
      // Check if app is in background
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        final notifService = ref.read(notificationServiceProvider);
        await notifService.showNotification(
          id: 9999, // Static ID so we don't spam multiple turn notifications
          title: 'It\'s your turn!',
          body: 'Come back to NexScore and make your move.',
        );
      }
    }
  });
});
