import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/storage/database_service.dart';

final playerRepositoryProvider = Provider((ref) => PlayerRepository());

// Provides a real-time stream of all non-deleted players
final playersStreamProvider = StreamProvider<List<Player>>((ref) {
  final repo = ref.watch(playerRepositoryProvider);
  return Stream.periodic(
    const Duration(seconds: 1),
  ).asyncMap((_) => repo.getPlayers());
  // Note: in a real app, sqflite doesn't natively support reactive streams without plugins (like sqlbrite).
  // Polling or using a StateNotifier is better. For this 2026 standard offline app, we will use a StateNotifier.
});

// Using a StateNotifier for reactivity with SQFlite
class PlayersNotifier extends AsyncNotifier<List<Player>> {
  @override
  Future<List<Player>> build() async {
    return _repository.getPlayers();
  }

  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  Future<void> addPlayer(Player player) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertPlayer(player);
      return _repository.getPlayers();
    });
  }

  Future<void> updatePlayer(Player player) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updatePlayer(player);
      return _repository.getPlayers();
    });
  }

  Future<void> deletePlayer(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.markDeleted(id);
      return _repository.getPlayers();
    });
  }
}

final playersProvider = AsyncNotifierProvider<PlayersNotifier, List<Player>>(
  () {
    return PlayersNotifier();
  },
);

class PlayerRepository {
  Future<List<Player>> getPlayers() async {
    final maps = await DatabaseService.instance.query(
      'players',
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  Future<void> insertPlayer(Player player) async {
    await DatabaseService.instance.insert('players', player.toMap());
  }

  Future<void> updatePlayer(Player player) async {
    await DatabaseService.instance.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<void> markDeleted(String id) async {
    await DatabaseService.instance.update(
      'players',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
