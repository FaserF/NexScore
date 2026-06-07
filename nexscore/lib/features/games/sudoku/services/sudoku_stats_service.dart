import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SudokuStats {
  final int gamesPlayed;
  final int gamesWon;
  final int bestTimeSeconds;
  final int averageTimeSeconds;
  final int currentStreak;
  final int longestStreak;

  SudokuStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.bestTimeSeconds = 0,
    this.averageTimeSeconds = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'gamesPlayed': gamesPlayed,
      'gamesWon': gamesWon,
      'bestTimeSeconds': bestTimeSeconds,
      'averageTimeSeconds': averageTimeSeconds,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }

  factory SudokuStats.fromMap(Map<String, dynamic> map) {
    return SudokuStats(
      gamesPlayed: map['gamesPlayed'] as int? ?? 0,
      gamesWon: map['gamesWon'] as int? ?? 0,
      bestTimeSeconds: map['bestTimeSeconds'] as int? ?? 0,
      averageTimeSeconds: map['averageTimeSeconds'] as int? ?? 0,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
    );
  }
}

class SudokuStatsService {
  static const String _statsPrefix = 'sudoku_stats_v2_';

  static String _getKey(String variant, String difficulty) {
    return '$_statsPrefix${variant}_$difficulty';
  }

  static Future<SudokuStats> getStats(String variant, String difficulty) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_getKey(variant, difficulty));
    if (jsonStr == null) return SudokuStats();
    try {
      return SudokuStats.fromMap(jsonDecode(jsonStr));
    } catch (e) {
      return SudokuStats();
    }
  }

  static Future<void> recordGame({
    required String variant,
    required String difficulty,
    required bool won,
    required int timeSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getKey(variant, difficulty);
    
    final current = await getStats(variant, difficulty);
    
    int newPlayed = current.gamesPlayed + 1;
    int newWon = current.gamesWon + (won ? 1 : 0);
    int newBest = current.bestTimeSeconds;
    if (won && (current.bestTimeSeconds == 0 || timeSeconds < current.bestTimeSeconds)) {
      newBest = timeSeconds;
    }

    int newAvg = current.averageTimeSeconds;
    if (won) {
      if (current.gamesWon == 0) {
        newAvg = timeSeconds;
      } else {
        newAvg = ((current.averageTimeSeconds * current.gamesWon) + timeSeconds) ~/ newWon;
      }
    }

    int newStreak = won ? current.currentStreak + 1 : 0;
    int newLongest = newStreak > current.longestStreak ? newStreak : current.longestStreak;

    final updated = SudokuStats(
      gamesPlayed: newPlayed,
      gamesWon: newWon,
      bestTimeSeconds: newBest,
      averageTimeSeconds: newAvg,
      currentStreak: newStreak,
      longestStreak: newLongest,
    );

    await prefs.setString(key, jsonEncode(updated.toMap()));
  }
}
