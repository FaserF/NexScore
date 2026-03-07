import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firestore_multiplayer_impl.dart';
import '../models/lobby.dart';
import '../multiplayer_service.dart';

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
