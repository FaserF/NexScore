import 'dart:convert';

class Session {
  final String id;
  final String gameType; // wizard, qwixx, etc.
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final List<String> players; // Player IDs
  final Map<String, int> scores; // PlayerId -> Score
  final Map<String, dynamic> gameData; // Custom Game JSON State
  final String? ownerUid;
  final bool completed;

  const Session({
    required this.id,
    required this.gameType,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    required this.players,
    required this.scores,
    required this.gameData,
    this.ownerUid,
    this.completed = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameType': gameType,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'players': jsonEncode(players),
      'scores': jsonEncode(scores),
      'gameData': jsonEncode(gameData),
      'ownerUid': ownerUid,
      'completed': completed ? 1 : 0,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as String,
      gameType: map['gameType'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      durationSeconds: map['durationSeconds'] as int,
      players: List<String>.from(jsonDecode(map['players'] as String)),
      scores: Map<String, int>.from(jsonDecode(map['scores'] as String)),
      gameData: Map<String, dynamic>.from(
        jsonDecode(map['gameData'] as String),
      ),
      ownerUid: map['ownerUid'] as String?,
      completed: (map['completed'] as int) == 1,
    );
  }

  Session copyWith({
    String? id,
    String? gameType,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    List<String>? players,
    Map<String, int>? scores,
    Map<String, dynamic>? gameData,
    String? ownerUid,
    bool? completed,
  }) {
    return Session(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      players: players ?? this.players,
      scores: scores ?? this.scores,
      gameData: gameData ?? this.gameData,
      ownerUid: ownerUid ?? this.ownerUid,
      completed: completed ?? this.completed,
    );
  }
}
