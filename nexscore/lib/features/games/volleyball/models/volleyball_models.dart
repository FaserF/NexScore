import 'package:flutter/foundation.dart';

enum VolleyballType { indoor, beach }

@immutable
class VolleyballRules {
  final int setsToWin;
  final int pointsPerSet;
  final int decidingSetPoints;
  final int switchSidesEvery; // Significant for Beach (e.g. 7 points)
  final int timeoutsPerSet;

  const VolleyballRules({
    required this.setsToWin,
    required this.pointsPerSet,
    required this.decidingSetPoints,
    this.switchSidesEvery = 0,
    this.timeoutsPerSet = 2,
  });

  factory VolleyballRules.indoor() => const VolleyballRules(
    setsToWin: 3,
    pointsPerSet: 25,
    decidingSetPoints: 15,
    timeoutsPerSet: 2,
  );

  factory VolleyballRules.beach() => const VolleyballRules(
    setsToWin: 2,
    pointsPerSet: 21,
    decidingSetPoints: 15,
    switchSidesEvery: 7,
    timeoutsPerSet: 1,
  );

  Map<String, dynamic> toJson() => {
    'setsToWin': setsToWin,
    'pointsPerSet': pointsPerSet,
    'decidingSetPoints': decidingSetPoints,
    'switchSidesEvery': switchSidesEvery,
    'timeoutsPerSet': timeoutsPerSet,
  };

  factory VolleyballRules.fromJson(Map<String, dynamic> json) =>
      VolleyballRules(
        setsToWin: json['setsToWin'] as int,
        pointsPerSet: json['pointsPerSet'] as int,
        decidingSetPoints: json['decidingSetPoints'] as int,
        switchSidesEvery: json['switchSidesEvery'] as int? ?? 0,
        timeoutsPerSet: json['timeoutsPerSet'] as int? ?? 2,
      );
}

@immutable
class VolleyballSet {
  final int scoreA;
  final int scoreB;
  final int timeoutsTakenA;
  final int timeoutsTakenB;
  final bool isFinished;

  const VolleyballSet({
    this.scoreA = 0,
    this.scoreB = 0,
    this.timeoutsTakenA = 0,
    this.timeoutsTakenB = 0,
    this.isFinished = false,
  });

  Map<String, dynamic> toJson() => {
    'scoreA': scoreA,
    'scoreB': scoreB,
    'timeoutsTakenA': timeoutsTakenA,
    'timeoutsTakenB': timeoutsTakenB,
    'isFinished': isFinished,
  };

  factory VolleyballSet.fromJson(Map<String, dynamic> json) => VolleyballSet(
    scoreA: json['scoreA'] as int,
    scoreB: json['scoreB'] as int,
    timeoutsTakenA: json['timeoutsTakenA'] as int? ?? 0,
    timeoutsTakenB: json['timeoutsTakenB'] as int? ?? 0,
    isFinished: json['isFinished'] as bool? ?? false,
  );

  VolleyballSet copyWith({
    int? scoreA,
    int? scoreB,
    int? timeoutsTakenA,
    int? timeoutsTakenB,
    bool? isFinished,
  }) {
    return VolleyballSet(
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      timeoutsTakenA: timeoutsTakenA ?? this.timeoutsTakenA,
      timeoutsTakenB: timeoutsTakenB ?? this.timeoutsTakenB,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

@immutable
class VolleyballGameState {
  final String teamAName;
  final String teamBName;
  final List<VolleyballSet> sets;
  final VolleyballType type;
  final VolleyballRules rules;
  final int currentSetIndex;
  final bool matchFinished;
  final String? server; // 'A' or 'B'
  final List<String> teamAPlayers;
  final List<String> teamBPlayers;

  const VolleyballGameState({
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
    this.sets = const [VolleyballSet()],
    this.type = VolleyballType.indoor,
    this.rules = const VolleyballRules(
      setsToWin: 3,
      pointsPerSet: 25,
      decidingSetPoints: 15,
    ),
    this.currentSetIndex = 0,
    this.matchFinished = false,
    this.server,
    this.teamAPlayers = const [],
    this.teamBPlayers = const [],
  });

  VolleyballSet get currentSet => sets[currentSetIndex];

  int get setsWonA =>
      sets.where((s) => s.isFinished && s.scoreA > s.scoreB).length;
  int get setsWonB =>
      sets.where((s) => s.isFinished && s.scoreB > s.scoreA).length;

  Map<String, dynamic> toJson() => {
    'teamAName': teamAName,
    'teamBName': teamBName,
    'sets': sets.map((s) => s.toJson()).toList(),
    'type': type.name,
    'rules': rules.toJson(),
    'currentSetIndex': currentSetIndex,
    'matchFinished': matchFinished,
    'server': server,
    'teamAPlayers': teamAPlayers,
    'teamBPlayers': teamBPlayers,
  };

  factory VolleyballGameState.fromJson(Map<String, dynamic> json) {
    return VolleyballGameState(
      teamAName: json['teamAName'] as String? ?? 'Team A',
      teamBName: json['teamBName'] as String? ?? 'Team B',
      sets:
          (json['sets'] as List?)
              ?.map((s) => VolleyballSet.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [VolleyballSet()],
      type: VolleyballType.values.byName(json['type'] as String? ?? 'indoor'),
      rules: VolleyballRules.fromJson(json['rules'] as Map<String, dynamic>),
      currentSetIndex: json['currentSetIndex'] as int? ?? 0,
      matchFinished: json['matchFinished'] as bool? ?? false,
      server: json['server'] as String?,
      teamAPlayers: List<String>.from(json['teamAPlayers'] ?? []),
      teamBPlayers: List<String>.from(json['teamBPlayers'] ?? []),
    );
  }

  VolleyballGameState copyWith({
    String? teamAName,
    String? teamBName,
    List<VolleyballSet>? sets,
    VolleyballType? type,
    VolleyballRules? rules,
    int? currentSetIndex,
    bool? matchFinished,
    String? server,
    List<String>? teamAPlayers,
    List<String>? teamBPlayers,
  }) {
    return VolleyballGameState(
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      sets: sets ?? this.sets,
      type: type ?? this.type,
      rules: rules ?? this.rules,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      matchFinished: matchFinished ?? this.matchFinished,
      server: server ?? this.server,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
    );
  }
}
