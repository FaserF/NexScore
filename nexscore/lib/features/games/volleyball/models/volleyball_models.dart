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

  factory VolleyballRules.indoor({int setsToWin = 3}) => VolleyballRules(
    setsToWin: setsToWin,
    pointsPerSet: 25,
    decidingSetPoints: 15,
    switchSidesEvery: 0,
    timeoutsPerSet: 2,
  );

  factory VolleyballRules.beach({int setsToWin = 2}) => VolleyballRules(
    setsToWin: setsToWin,
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
  final bool setupDone;
  final bool sidesSwapped;
  final bool earlyFinished;

  VolleyballGameState({
    this.type = VolleyballType.indoor,
    VolleyballRules? rules,
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
    List<String>? teamAPlayers,
    List<String>? teamBPlayers,
    List<VolleyballSet>? sets,
    this.currentSetIndex = 0,
    this.matchFinished = false,
    this.server,
    this.timeoutsA = 0,
    this.timeoutsB = 0,
    this.setupDone = false,
    this.sidesSwapped = false,
    this.earlyFinished = false,
  }) : rules = rules ?? VolleyballRules.indoor(),
       teamAPlayers = teamAPlayers ?? [],
       teamBPlayers = teamBPlayers ?? [],
       sets = sets ?? [VolleyballSet()];

  VolleyballSet get currentSet => sets[currentSetIndex];

  int get setsWonA =>
      sets.where((s) => s.isFinished && s.scoreA > s.scoreB).length;
  int get setsWonB =>
      sets.where((s) => s.isFinished && s.scoreB > s.scoreA).length;

  /// Calculates league points based on DVV/FIVB (3-2-1) system.
  /// 3 points: Win 3-0 or 3-1
  /// 2 points: Win 3-2
  /// 1 point: Lose 2-3
  /// 0 points: Lose 0-3 or 1-3
  /// For other configurations (e.g. Best of 3):
  /// Win: 3 points, Lose: 0 points (simplified)
  (int, int) get leaguePoints {
    if (!matchFinished && !earlyFinished) return (0, 0);

    final sA = setsWonA;
    final sB = setsWonB;

    if (rules.setsToWin == 3) {
      if (sA == 3) {
        if (sB <= 1) return (3, 0);
        if (sB == 2) return (2, 1);
      }
      if (sB == 3) {
        if (sA <= 1) return (0, 3);
        if (sA == 2) return (1, 2);
      }
    }

    // Default win/loss points for non-standard or early finish
    if (sA > sB) return (3, 0);
    if (sB > sA) return (0, 3);
    return (0, 0);
  }

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
    'setupDone': setupDone,
    'sidesSwapped': sidesSwapped,
    'earlyFinished': earlyFinished,
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
      setupDone: json['setupDone'] as bool? ?? false,
      sidesSwapped: json['sidesSwapped'] as bool? ?? false,
      earlyFinished: json['earlyFinished'] as bool? ?? false,
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
    bool? setupDone,
    bool? sidesSwapped,
    bool? earlyFinished,
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
      setupDone: setupDone ?? this.setupDone,
      sidesSwapped: sidesSwapped ?? this.sidesSwapped,
      earlyFinished: earlyFinished ?? this.earlyFinished,
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
    'setupDone': setupDone,
    'sidesSwapped': sidesSwapped,
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
        setupDone: map['setupDone'] ?? false,
        sidesSwapped: map['sidesSwapped'] ?? false,
      );
}
