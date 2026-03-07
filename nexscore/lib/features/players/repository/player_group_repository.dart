import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/error/failures.dart';
import 'package:nexscore/core/error/result.dart';
import 'package:nexscore/core/models/player_group.dart';
import 'package:nexscore/core/storage/database_service.dart';

final playerGroupRepositoryProvider = Provider(
  (ref) => PlayerGroupRepository(),
);

class PlayerGroupsNotifier extends AsyncNotifier<List<PlayerGroup>> {
  @override
  Future<List<PlayerGroup>> build() async {
    final result = await _repository.getPlayerGroups();
    return result.fold((failure) => throw failure, (groups) => groups);
  }

  PlayerGroupRepository get _repository =>
      ref.read(playerGroupRepositoryProvider);

  Future<Result<void>> addGroup(PlayerGroup group) async {
    final result = await _repository.insertPlayerGroup(group);
    if (result.isSuccess) {
      final groupsResult = await _repository.getPlayerGroups();
      state = groupsResult.fold(
        (f) => AsyncValue.error(f, StackTrace.current),
        (g) => AsyncValue.data(g),
      );
    }
    return result;
  }

  Future<Result<void>> updateGroup(PlayerGroup group) async {
    final result = await _repository.updatePlayerGroup(group);
    if (result.isSuccess) {
      final groupsResult = await _repository.getPlayerGroups();
      state = groupsResult.fold(
        (f) => AsyncValue.error(f, StackTrace.current),
        (g) => AsyncValue.data(g),
      );
    }
    return result;
  }

  Future<void> deleteGroup(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deletePlayerGroup(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) async {
        final groupsResult = await _repository.getPlayerGroups();
        state = groupsResult.fold(
          (f) => AsyncValue.error(f, StackTrace.current),
          (g) => AsyncValue.data(g),
        );
      },
    );
  }
}

final playerGroupsProvider =
    AsyncNotifierProvider<PlayerGroupsNotifier, List<PlayerGroup>>(
      () => PlayerGroupsNotifier(),
    );

class PlayerGroupRepository {
  Future<Result<List<PlayerGroup>>> getPlayerGroups() async {
    try {
      final maps = await DatabaseService.instance.query(
        'player_groups',
        orderBy: 'name ASC',
      );
      final groups = maps.map((m) => PlayerGroup.fromMap(m)).toList();
      return Result.success(groups);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure(
          'Failed to fetch player groups',
          error: e,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<Result<void>> insertPlayerGroup(PlayerGroup group) async {
    if (group.name.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure('Group name cannot be empty'),
      );
    }
    try {
      await DatabaseService.instance.insert('player_groups', group.toMap());
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure(
          'Failed to insert player group',
          error: e,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<Result<void>> updatePlayerGroup(PlayerGroup group) async {
    if (group.name.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure('Group name cannot be empty'),
      );
    }
    try {
      await DatabaseService.instance.update(
        'player_groups',
        group.toMap(),
        where: 'id = ?',
        whereArgs: [group.id],
      );
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure(
          'Failed to update player group',
          error: e,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<Result<void>> deletePlayerGroup(String id) async {
    try {
      await DatabaseService.instance.delete(
        'player_groups',
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure(
          'Failed to delete player group',
          error: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
