import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/state_persistence_service.dart';

/// Provider for the ID of the game currently being played.
class ActiveGameIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  @override
  set state(String? value) => super.state = value;
}

final activeGameIdProvider = NotifierProvider<ActiveGameIdNotifier, String?>(
  ActiveGameIdNotifier.new,
);

/// Provider for the persistence service.
final persistenceServiceProvider = Provider((ref) => StatePersistenceService());

/// Notifier to manage loading and resuming games.
class PersistenceNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final service = ref.read(persistenceServiceProvider);
    return service.getLastGameId();
  }

  Future<void> clearLastGame() async {
    final service = ref.read(persistenceServiceProvider);
    final lastId = state.value;
    if (lastId != null) {
      await service.clearGameState(lastId);
      state = const AsyncValue.data(null);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final service = ref.read(persistenceServiceProvider);
    final lastId = await service.getLastGameId();
    state = AsyncValue.data(lastId);
  }
}

final persistenceNotifierProvider =
    AsyncNotifierProvider<PersistenceNotifier, String?>(
      PersistenceNotifier.new,
    );
