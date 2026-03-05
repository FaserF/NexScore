import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/error/failures.dart';
import 'package:nexscore/core/error/result.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/storage/database_service.dart';

final playerRepositoryProvider = Provider((ref) => PlayerRepository());

// Using a StateNotifier for reactivity with SQFlite
class PlayersNotifier extends AsyncNotifier<List<Player>> {
  @override
  Future<List<Player>> build() async {
    final result = await _repository.getPlayers();
    return result.fold(
      (failure) => throw failure, // AsyncNotifier will catch this
      (players) => players,
    );
  }

  PlayerRepository get _repository => ref.read(playerRepositoryProvider);

  Future<Result<void>> addPlayer(Player player) async {
    final result = await _repository.insertPlayer(player);
    if (result.isSuccess) {
      final playersResult = await _repository.getPlayers();
      state = playersResult.fold(
        (f) => AsyncValue.error(f, StackTrace.current),
        (p) => AsyncValue.data(p),
      );
    }
    return result;
  }

  Future<Result<void>> updatePlayer(Player player) async {
    final result = await _repository.updatePlayer(player);
    if (result.isSuccess) {
      final playersResult = await _repository.getPlayers();
      state = playersResult.fold(
        (f) => AsyncValue.error(f, StackTrace.current),
        (p) => AsyncValue.data(p),
      );
    }
    return result;
  }

  Future<void> deletePlayer(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.markDeleted(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) async {
        final playersResult = await _repository.getPlayers();
        state = playersResult.fold(
          (f) => AsyncValue.error(f, StackTrace.current),
          (p) => AsyncValue.data(p),
        );
      },
    );
  }
}

final playersProvider = AsyncNotifierProvider<PlayersNotifier, List<Player>>(
  () => PlayersNotifier(),
);

class PlayerRepository {
  Future<Result<List<Player>>> getPlayers() async {
    try {
      final maps = await DatabaseService.instance.query(
        'players',
        where: 'isDeleted = ?',
        whereArgs: [0],
        orderBy: 'name ASC',
      );
      final players = maps.map((m) => Player.fromMap(m)).toList();
      return Result.success(players);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure('Failed to fetch players', error: e, stackTrace: stack),
      );
    }
  }

  Future<Result<void>> insertPlayer(Player player) async {
    final trimmedName = player.name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(
        ValidationFailure('Player name cannot be empty'),
      );
    }
    try {
      // Check for duplicate names (case-insensitive)
      final existing = await DatabaseService.instance.query(
        'players',
        where: 'LOWER(name) = ? AND isDeleted = ?',
        whereArgs: [trimmedName.toLowerCase(), 0],
      );
      if (existing.isNotEmpty) {
        return const Result.failure(ValidationFailure('error_name_taken'));
      }

      await DatabaseService.instance.insert('players', player.toMap());
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure('Failed to insert player', error: e, stackTrace: stack),
      );
    }
  }

  Future<Result<void>> updatePlayer(Player player) async {
    final trimmedName = player.name.trim();
    if (trimmedName.isEmpty) {
      return const Result.failure(
        ValidationFailure('Player name cannot be empty'),
      );
    }
    try {
      // Check for duplicate names (excluding current player)
      final existing = await DatabaseService.instance.query(
        'players',
        where: 'LOWER(name) = ? AND id != ? AND isDeleted = ?',
        whereArgs: [trimmedName.toLowerCase(), player.id, 0],
      );
      if (existing.isNotEmpty) {
        return const Result.failure(ValidationFailure('error_name_taken'));
      }

      await DatabaseService.instance.update(
        'players',
        player.toMap(),
        where: 'id = ?',
        whereArgs: [player.id],
      );
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure('Failed to update player', error: e, stackTrace: stack),
      );
    }
  }

  Future<Result<void>> markDeleted(String id) async {
    try {
      await DatabaseService.instance.update(
        'players',
        {'isDeleted': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure('Failed to delete player', error: e, stackTrace: stack),
      );
    }
  }
}
