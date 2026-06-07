import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SudokuScore {
  final String id;
  final String date;
  final String playerName;
  final int timeSeconds;
  final String variant;
  final String difficulty;
  final String mode;
  final bool synced;

  SudokuScore({
    required this.id,
    required this.date,
    required this.playerName,
    required this.timeSeconds,
    required this.variant,
    required this.difficulty,
    required this.mode,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'playerName': playerName,
      'timeSeconds': timeSeconds,
      'variant': variant,
      'difficulty': difficulty,
      'mode': mode,
      'synced': synced ? 1 : 0,
    };
  }

  factory SudokuScore.fromMap(Map<String, dynamic> map) {
    return SudokuScore(
      id: map['id'] as String,
      date: map['date'] as String,
      playerName: map['playerName'] as String,
      timeSeconds: map['timeSeconds'] as int,
      variant: map['variant'] as String,
      difficulty: map['difficulty'] as String,
      mode: map['mode'] as String,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}

class SudokuSyncService {
  static const String _scoresKey = 'sudoku_local_scores';
  static const String _completedChallengesKey = 'sudoku_completed_challenges';

  static FirebaseFirestore? get _firestore {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseFirestore.instance;
  }

  static FirebaseAuth? get _auth {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance;
  }

  /// Saves score locally first, then attempts to push to Firestore
  static Future<void> saveAndSyncScore({
    required String playerName,
    required int timeSeconds,
    required String variant,
    required String difficulty,
    required String mode,
    bool isDaily = false,
    String? dailyDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final id = const Uuid().v4();
    final date = dailyDate ?? DateTime.now().toIso8601String().substring(0, 10);

    final newScore = SudokuScore(
      id: id,
      date: date,
      playerName: playerName,
      timeSeconds: timeSeconds,
      variant: variant,
      difficulty: difficulty,
      mode: mode,
      synced: false,
    );

    // Save locally
    List<SudokuScore> localScores = await getLocalScores();
    localScores.add(newScore);
    await _saveLocalScores(prefs, localScores);

    if (isDaily && dailyDate != null) {
      await markChallengeCompleted(dailyDate);
    }

    // Try to sync with firebase
    await triggerSync();
  }

  /// Gets all cached local scores
  static Future<List<SudokuScore>> getLocalScores() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_scoresKey);
    if (jsonStr == null) return [];
    try {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => SudokuScore.fromMap(item)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> _saveLocalScores(SharedPreferences prefs, List<SudokuScore> scores) async {
    final list = scores.map((s) => s.toMap()).toList();
    await prefs.setString(_scoresKey, jsonEncode(list));
  }

  /// Syncs any unsynced offline scores to Firebase Firestore
  static Future<void> triggerSync() async {
    final firestore = _firestore;
    if (firestore == null) return;

    try {
      final localScores = await getLocalScores();
      final unsynced = localScores.where((s) => !s.synced).toList();
      if (unsynced.isEmpty) return;

      // Ensure Anonymous auth is signed in to write
      final auth = _auth;
      if (auth != null && auth.currentUser == null) {
        await auth.signInAnonymously();
      }

      final uid = auth?.currentUser?.uid ?? 'anonymous';

      for (final score in unsynced) {
        await firestore.collection('sudoku_leaderboards').doc(score.id).set({
          'uid': uid,
          'playerName': score.playerName,
          'timeSeconds': score.timeSeconds,
          'variant': score.variant,
          'difficulty': score.difficulty,
          'mode': score.mode,
          'date': score.date,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Mark all as synced locally
      final prefs = await SharedPreferences.getInstance();
      final updatedScores = localScores.map((s) {
        if (!s.synced) {
          return SudokuScore(
            id: s.id,
            date: s.date,
            playerName: s.playerName,
            timeSeconds: s.timeSeconds,
            variant: s.variant,
            difficulty: s.difficulty,
            mode: s.mode,
            synced: true,
          );
        }
        return s;
      }).toList();

      await _saveLocalScores(prefs, updatedScores);
      debugPrint('SudokuSyncService: Synced ${unsynced.length} scores successfully.');
    } catch (e) {
      debugPrint('SudokuSyncService: Sync failed ($e). Stored offline.');
    }
  }

  /// Marks a specific daily challenge as completed locally
  static Future<void> markChallengeCompleted(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_completedChallengesKey) ?? [];
    if (!list.contains(dateStr)) {
      list.add(dateStr);
      await prefs.setStringList(_completedChallengesKey, list);
    }
  }

  /// Returns list of dates of completed challenges
  static Future<List<String>> getCompletedChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedChallengesKey) ?? [];
  }

  /// Fetches global highscores for a variant and difficulty from Firestore
  static Future<List<Map<String, dynamic>>> fetchLeaderboard({
    required String variant,
    required String difficulty,
    required String mode,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final querySnapshot = await firestore
          .collection('sudoku_leaderboards')
          .where('variant', isEqualTo: variant)
          .where('difficulty', isEqualTo: difficulty)
          .where('mode', isEqualTo: mode)
          .orderBy('timeSeconds', descending: false)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => throw Exception('Leaderboard request timed out'),
          );

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'playerName': data['playerName'] ?? 'Anonymous',
          'timeSeconds': data['timeSeconds'] ?? 9999,
          'date': data['date'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Failed to fetch leaderboard: $e');
      return [];
    }
  }
}
