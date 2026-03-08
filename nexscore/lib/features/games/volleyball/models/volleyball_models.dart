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
    required this.switchSidesEvery,
    this.timeoutsPerSet = 2,
  });

  factory VolleyballRules.indoor() => const VolleyballRules(
    setsToWin: 1,
    pointsPerSet: 15,
    decidingSetPoints: 15,
    switchSidesEvery: 0,
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

  Map<String, dynamic> toMap() => {
    'setsToWin': setsToWin,
    'pointsPerSet': pointsPerSet,
    'decidingSetPoints': decidingSetPoints,
    'switchSidesEvery': switchSidesEvery,
    'timeoutsPerSet': timeoutsPerSet,
  };

  factory VolleyballRules.fromMap(Map<String, dynamic> map) => VolleyballRules(
    setsToWin: map['setsToWin'] as int,
    pointsPerSet: map['pointsPerSet'] as int,
    decidingSetPoints: map['decidingSetPoints'] as int,
    switchSidesEvery: map['switchSidesEvery'] as int? ?? 0,
    timeoutsPerSet: map['timeoutsPerSet'] as int? ?? 2,
  );
}

@immutable
class VolleyballSet {
  final int scoreA;
  final int scoreB;
  final int timeoutsTakenA;
  final int timeoutsTakenB;
  final bool isFinished;
  final int sideSwitches;

  const VolleyballSet({
    this.scoreA = 0,
    this.scoreB = 0,
    this.timeoutsTakenA = 0,
    this.timeoutsTakenB = 0,
    this.isFinished = false,
    this.sideSwitches = 0,
  });

  Map<String, dynamic> toJson() => {
    'scoreA': scoreA,
    'scoreB': scoreB,
    'timeoutsTakenA': timeoutsTakenA,
    'timeoutsTakenB': timeoutsTakenB,
    'isFinished': isFinished,
    'sideSwitches': sideSwitches,
  };

  factory VolleyballSet.fromJson(Map<String, dynamic> json) => VolleyballSet(
    scoreA: json['scoreA'] as int,
    scoreB: json['scoreB'] as int,
    timeoutsTakenA: json['timeoutsTakenA'] as int? ?? 0,
    timeoutsTakenB: json['timeoutsTakenB'] as int? ?? 0,
    isFinished: json['isFinished'] as bool? ?? false,
    sideSwitches: json['sideSwitches'] as int? ?? 0,
  );

  VolleyballSet copyWith({
    int? scoreA,
    int? scoreB,
    int? timeoutsTakenA,
    int? timeoutsTakenB,
    bool? isFinished,
    int? sideSwitches,
  }) {
    return VolleyballSet(
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      timeoutsTakenA: timeoutsTakenA ?? this.timeoutsTakenA,
      timeoutsTakenB: timeoutsTakenB ?? this.timeoutsTakenB,
      isFinished: isFinished ?? this.isFinished,
      sideSwitches: sideSwitches ?? this.sideSwitches,
    );
  }

  Map<String, dynamic> toMap() => {
    'scoreA': scoreA,
    'scoreB': scoreB,
    'isFinished': isFinished,
    'sideSwitches': sideSwitches,
    'timeoutsTakenA': timeoutsTakenA,
    'timeoutsTakenB': timeoutsTakenB,
  };

  factory VolleyballSet.fromMap(Map<String, dynamic> map) => VolleyballSet(
    scoreA: map['scoreA'] as int,
    scoreB: map['scoreB'] as int,
    isFinished: map['isFinished'] as bool? ?? false,
    sideSwitches: map['sideSwitches'] as int? ?? 0,
    timeoutsTakenA: map['timeoutsTakenA'] as int? ?? 0,
    timeoutsTakenB: map['timeoutsTakenB'] as int? ?? 0,
  );
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
  final int timeoutsA;
  final int timeoutsB;

  const VolleyballGameState({
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
    this.sets = const [VolleyballSet()],
    this.type = VolleyballType.indoor,
    this.rules = const VolleyballRules(
      setsToWin: 3,
      pointsPerSet: 25,
      decidingSetPoints: 15,
      switchSidesEvery: 0,
    ),
    this.currentSetIndex = 0,
    this.matchFinished = false,
    this.server,
    this.teamAPlayers = const [],
    this.teamBPlayers = const [],
    this.timeoutsA = 0,
    this.timeoutsB = 0,
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
    'timeoutsA': timeoutsA,
    'timeoutsB': timeoutsB,
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
      timeoutsA: json['timeoutsA'] as int? ?? 0,
      timeoutsB: json['timeoutsB'] as int? ?? 0,
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
    int? timeoutsA,
    int? timeoutsB,
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
      timeoutsA: timeoutsA ?? this.timeoutsA,
      timeoutsB: timeoutsB ?? this.timeoutsB,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'rules': rules.toMap(),
    'teamAName': teamAName,
    'teamBName': teamBName,
    'teamAPlayers': teamAPlayers,
    'teamBPlayers': teamBPlayers,
    'sets': sets.map((s) => s.toMap()).toList(),
    'currentSetIndex': currentSetIndex,
    'setsWonA': setsWonA,
    'setsWonB': setsWonB,
    'matchFinished': matchFinished,
    'server': server,
    'timeoutsA': timeoutsA,
    'timeoutsB': timeoutsB,
  };

  factory VolleyballGameState.fromMap(Map<String, dynamic> map) =>
      VolleyballGameState(
        type: VolleyballType.values.byName(map['type'] ?? 'indoor'),
        rules: VolleyballRules.fromMap(map['rules']),
        teamAName: map['teamAName'] ?? 'Team A',
        teamBName: map['teamBName'] ?? 'Team B',
        teamAPlayers: List<String>.from(map['teamAPlayers'] ?? []),
        teamBPlayers: List<String>.from(map['teamBPlayers'] ?? []),
        sets: (map['sets'] as List)
            .map((s) => VolleyballSet.fromMap(s))
            .toList(),
        currentSetIndex: map['currentSetIndex'] ?? 0,
        matchFinished: map['matchFinished'] ?? false,
        server: map['server'],
        timeoutsA: map['timeoutsA'] ?? 0,
        timeoutsB: map['timeoutsB'] ?? 0,
      );
}
