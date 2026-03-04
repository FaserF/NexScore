import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/models/session_model.dart';
import 'package:nexscore/core/storage/database_service.dart';

final sessionRepositoryProvider = Provider((ref) => SessionRepository());

class SessionsNotifier extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    return _repository.getSessions();
  }

  SessionRepository get _repository => ref.read(sessionRepositoryProvider);

  Future<void> addSession(Session session) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.insertSession(session);
      return _repository.getSessions();
    });
  }

  Future<void> updateSession(Session session) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.updateSession(session);
      return _repository.getSessions();
    });
  }

  Future<void> deleteSession(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteSession(id);
      return _repository.getSessions();
    });
  }
}

final sessionsProvider = AsyncNotifierProvider<SessionsNotifier, List<Session>>(
  () {
    return SessionsNotifier();
  },
);

class SessionRepository {
  Future<List<Session>> getSessions() async {
    final maps = await DatabaseService.instance.query(
      'sessions',
      orderBy: 'startTime DESC',
    );
    return maps.map((m) => Session.fromMap(m)).toList();
  }

  Future<void> insertSession(Session session) async {
    await DatabaseService.instance.insert('sessions', session.toMap());
  }

  Future<void> updateSession(Session session) async {
    await DatabaseService.instance.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(String id) async {
    await DatabaseService.instance.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
