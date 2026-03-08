import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and restoring game states.
class StatePersistenceService {
  static const String _lastGameKey = 'last_game_id';
  static const String _statePrefix = 'game_state_';

  /// Save the current state of a game.
  Future<void> saveGameState(String gameId, Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastGameKey, gameId);
    await prefs.setString(
      '$_statePrefix$gameId',
      jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'data': state,
      }),
    );
  }

  /// Load the last saved game ID.
  Future<String?> getLastGameId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastGameKey);
  }

  /// Load the state for a specific game.
  Future<Map<String, dynamic>?> loadGameState(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('$_statePrefix$gameId');
    if (json == null) return null;

    final Map<String, dynamic> decoded = jsonDecode(json);
    return decoded['data'] as Map<String, dynamic>?;
  }

  /// Clear the state for a specific game (e.g. when finished).
  Future<void> clearGameState(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_statePrefix$gameId');

    final lastId = prefs.getString(_lastGameKey);
    if (lastId == gameId) {
      await prefs.remove(_lastGameKey);
    }
  }

  /// Clear all saved states.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) => k.startsWith(_statePrefix) || k == _lastGameKey,
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
