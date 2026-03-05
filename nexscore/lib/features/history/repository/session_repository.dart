import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/error/failures.dart';
import 'package:nexscore/core/error/result.dart';
import 'package:nexscore/core/models/session_model.dart';
import 'package:nexscore/core/storage/database_service.dart';

final sessionRepositoryProvider = Provider((ref) => SessionRepository());

class SessionsNotifier extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    final result = await _repository.getSessions();
    return result.fold((failure) => throw failure, (sessions) => sessions);
  }

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  Future<void> addSession(Session session) async {
    state = const AsyncValue.loading();
    final result = await _repository.insertSession(session);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) async {
        final sessionsResult = await _repository.getSessions();
        state = sessionsResult.fold(
          (f) => AsyncValue.error(f, StackTrace.current),
          (p) => AsyncValue.data(p),
        );
      },
    );
  }

  Future<void> updateSession(Session session) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateSession(session);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) async {
        final sessionsResult = await _repository.getSessions();
        state = sessionsResult.fold(
          (f) => AsyncValue.error(f, StackTrace.current),
          (p) => AsyncValue.data(p),
        );
      },
    );
  }

  Future<void> deleteSession(String id) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteSession(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure, StackTrace.current),
      (_) async {
        final sessionsResult = await _repository.getSessions();
        state = sessionsResult.fold(
          (f) => AsyncValue.error(f, StackTrace.current),
          (p) => AsyncValue.data(p),
        );
      },
    );
  }
}

final sessionsProvider = AsyncNotifierProvider<SessionsNotifier, List<Session>>(
  () => SessionsNotifier(),
);

class SessionRepository {
  Future<Result<List<Session>>> getSessions() async {
    try {
      final maps = await DatabaseService.instance.query(
        'sessions',
        orderBy: 'startTime DESC',
      );
      final sessions = maps.map((m) => Session.fromMap(m)).toList();
      return Result.success(sessions);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure(
          'Failed to fetch sessions',
          error: e,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<Result<void>> insertSession(Session session) async {
    try {
      await DatabaseService.instance.insert('sessions', session.toMap());
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure(
          'Failed to insert session',
          error: e,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<Result<void>> updateSession(Session session) async {
    try {
      await DatabaseService.instance.update(
        'sessions',
        session.toMap(),
        where: 'id = ?',
        whereArgs: [session.id],
      );
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure(
          'Failed to update session',
          error: e,
          stackTrace: stack,
        ),
      );
    }
  }

  Future<Result<void>> deleteSession(String id) async {
    try {
      await DatabaseService.instance.delete(
        'sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
      return const Result.success(null);
    } catch (e, stack) {
      return Result.failure(
        DatabaseFailure(
          'Failed to delete session',
          error: e,
          stackTrace: stack,
        ),
      );
    }
  }
}
