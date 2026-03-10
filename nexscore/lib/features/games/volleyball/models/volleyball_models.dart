import 'package:flutter/foundation.dart';

enum VolleyballType { indoor, beach }

enum VolleyballRuleSet { dvv, bvv }

enum VolleyballSide { left, right }

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

  int get midSetSideSwitchPoints {
    if (decidingSetPoints <= 15) return 8;
    return 13; // For 21 or 25 point sets
  }

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

  /// BVV Freizeitliga: always 3 sets, all to 25 pts (no 15-pt deciding set).
  factory VolleyballRules.bvv() => const VolleyballRules(
    setsToWin: 2,
    pointsPerSet: 25,
    decidingSetPoints: 25, // No special deciding set in BVV
    switchSidesEvery: 0,
    timeoutsPerSet: 2,
  );

  /// Total number of sets that can be played (e.g. 5 for Best-of-5, 3 for Best-of-3).
  int get maxSets => setsToWin * 2 - 1;

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
class VolleyballPoint {
  final String scorer; // 'A' or 'B'
  final String server; // 'A' or 'B'

  const VolleyballPoint({required this.scorer, required this.server});

  Map<String, dynamic> toJson() => {'scorer': scorer, 'server': server};

  factory VolleyballPoint.fromJson(Map<String, dynamic> json) =>
      VolleyballPoint(
        scorer: json['scorer'] as String,
        server: json['server'] as String,
      );
}

@immutable
class VolleyballTimeout {
  final String team; // 'A' or 'B'
  final DateTime timestamp;
  final int scoreA;
  final int scoreB;

  const VolleyballTimeout({
    required this.team,
    required this.timestamp,
    required this.scoreA,
    required this.scoreB,
  });

  Map<String, dynamic> toJson() => {
    'team': team,
    'timestamp': timestamp.toIso8601String(),
    'scoreA': scoreA,
    'scoreB': scoreB,
  };

  factory VolleyballTimeout.fromJson(Map<String, dynamic> json) =>
      VolleyballTimeout(
        team: json['team'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        scoreA: json['scoreA'] as int,
        scoreB: json['scoreB'] as int,
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
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool midSetSideSwitchDone;
  final List<VolleyballPoint> pointHistory;
  final List<VolleyballTimeout> timeouts;

  const VolleyballSet({
    this.scoreA = 0,
    this.scoreB = 0,
    this.timeoutsTakenA = 0,
    this.timeoutsTakenB = 0,
    this.isFinished = false,
    this.sideSwitches = 0,
    this.startedAt,
    this.endedAt,
    this.midSetSideSwitchDone = false,
    this.pointHistory = const [],
    this.timeouts = const [],
  });

  Map<String, dynamic> toJson() => {
    'scoreA': scoreA,
    'scoreB': scoreB,
    'timeoutsTakenA': timeoutsTakenA,
    'timeoutsTakenB': timeoutsTakenB,
    'isFinished': isFinished,
    'sideSwitches': sideSwitches,
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'midSetSideSwitchDone': midSetSideSwitchDone,
    'pointHistory': pointHistory.map((p) => p.toJson()).toList(),
    'timeouts': timeouts.map((t) => t.toJson()).toList(),
  };

  factory VolleyballSet.fromJson(Map<String, dynamic> json) => VolleyballSet(
    scoreA: json['scoreA'] as int,
    scoreB: json['scoreB'] as int,
    timeoutsTakenA: json['timeoutsTakenA'] as int? ?? 0,
    timeoutsTakenB: json['timeoutsTakenB'] as int? ?? 0,
    isFinished: json['isFinished'] as bool? ?? false,
    sideSwitches: json['sideSwitches'] as int? ?? 0,
    startedAt: json['startedAt'] != null
        ? DateTime.parse(json['startedAt'] as String)
        : null,
    endedAt: json['endedAt'] != null
        ? DateTime.parse(json['endedAt'] as String)
        : null,
    midSetSideSwitchDone: json['midSetSideSwitchDone'] as bool? ?? false,
    pointHistory:
        (json['pointHistory'] as List?)
            ?.map((p) => VolleyballPoint.fromJson(p as Map<String, dynamic>))
            .toList() ??
        const [],
    timeouts:
        (json['timeouts'] as List?)
            ?.map((t) => VolleyballTimeout.fromJson(t as Map<String, dynamic>))
            .toList() ??
        const [],
  );

  VolleyballSet copyWith({
    int? scoreA,
    int? scoreB,
    int? timeoutsTakenA,
    int? timeoutsTakenB,
    bool? isFinished,
    int? sideSwitches,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? midSetSideSwitchDone,
    List<VolleyballPoint>? pointHistory,
    List<VolleyballTimeout>? timeouts,
  }) {
    return VolleyballSet(
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      timeoutsTakenA: timeoutsTakenA ?? this.timeoutsTakenA,
      timeoutsTakenB: timeoutsTakenB ?? this.timeoutsTakenB,
      isFinished: isFinished ?? this.isFinished,
      sideSwitches: sideSwitches ?? this.sideSwitches,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      midSetSideSwitchDone: midSetSideSwitchDone ?? this.midSetSideSwitchDone,
      pointHistory: pointHistory ?? this.pointHistory,
      timeouts: timeouts ?? this.timeouts,
    );
  }

  Map<String, dynamic> toMap() => {
    'scoreA': scoreA,
    'scoreB': scoreB,
    'isFinished': isFinished,
    'sideSwitches': sideSwitches,
    'timeoutsTakenA': timeoutsTakenA,
    'timeoutsTakenB': timeoutsTakenB,
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'midSetSideSwitchDone': midSetSideSwitchDone,
  };

  factory VolleyballSet.fromMap(Map<String, dynamic> map) => VolleyballSet(
    scoreA: map['scoreA'] as int,
    scoreB: map['scoreB'] as int,
    isFinished: map['isFinished'] as bool? ?? false,
    sideSwitches: map['sideSwitches'] as int? ?? 0,
    timeoutsTakenA: map['timeoutsTakenA'] as int? ?? 0,
    timeoutsTakenB: map['timeoutsTakenB'] as int? ?? 0,
    startedAt: map['startedAt'] != null
        ? DateTime.parse(map['startedAt'] as String)
        : null,
    endedAt: map['endedAt'] != null
        ? DateTime.parse(map['endedAt'] as String)
        : null,
    midSetSideSwitchDone: map['midSetSideSwitchDone'] as bool? ?? false,
    pointHistory:
        (map['pointHistory'] as List?)
            ?.map((p) => VolleyballPoint.fromJson(p as Map<String, dynamic>))
            .toList() ??
        const [],
    timeouts:
        (map['timeouts'] as List?)
            ?.map((t) => VolleyballTimeout.fromJson(t as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

@immutable
class VolleyballGameState {
  final String teamAName;
  final String teamBName;
  final List<VolleyballSet> sets;
  final VolleyballType type;
  final VolleyballRules rules;
  final VolleyballRuleSet ruleSet;
  final int currentSetIndex;
  final bool matchFinished;
  final bool pendingContinue;
  final String? server; // 'A' or 'B'
  final List<String> teamAPlayers;
  final List<String> teamBPlayers;
  final int timeoutsA;
  final int timeoutsB;
  final bool setupDone;
  final bool sidesSwapped;
  final bool earlyFinished;
  final DateTime? matchStartedAt;
  final DateTime? matchEndedAt;
  final VolleyballSide teamASide;
  final bool pendingSideSwitch;
  final bool canUndo;

  VolleyballGameState({
    this.type = VolleyballType.indoor,
    VolleyballRules? rules,
    this.ruleSet = VolleyballRuleSet.bvv,
    this.teamAName = 'Team A',
    this.teamBName = 'Team B',
    List<String>? teamAPlayers,
    List<String>? teamBPlayers,
    List<VolleyballSet>? sets,
    this.currentSetIndex = 0,
    this.matchFinished = false,
    this.pendingContinue = false,
    this.server,
    this.timeoutsA = 0,
    this.timeoutsB = 0,
    this.setupDone = false,
    this.sidesSwapped = false,
    this.earlyFinished = false,
    this.matchStartedAt,
    this.matchEndedAt,
    this.teamASide = VolleyballSide.left,
    this.pendingSideSwitch = false,
    this.canUndo = false,
  }) : rules = rules ?? VolleyballRules.indoor(),
       teamAPlayers = teamAPlayers ?? [],
       teamBPlayers = teamBPlayers ?? [],
       sets = sets ?? [const VolleyballSet()];

  VolleyballSet get currentSet => sets[currentSetIndex];

  int get setsWonA =>
      sets.where((s) => s.isFinished && s.scoreA > s.scoreB).length;
  int get setsWonB =>
      sets.where((s) => s.isFinished && s.scoreB > s.scoreA).length;

  /// Whether all possible sets have been played.
  bool get allSetsPlayed =>
      sets.where((s) => s.isFinished).length >= rules.maxSets;

  /// Calculates league points based on the selected rule set.
  (int, int) get leaguePoints {
    if (!matchFinished && !earlyFinished) return (0, 0);

    final sA = setsWonA;
    final sB = setsWonB;

    if (ruleSet == VolleyballRuleSet.bvv) {
      if (sA > sB) {
        if (sB == 0) return (3, 0);
        return (2, 1);
      }
      if (sB > sA) {
        if (sA == 0) return (0, 3);
        return (1, 2);
      }
      return (0, 0);
    }

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
    'ruleSet': ruleSet.name,
    'currentSetIndex': currentSetIndex,
    'matchFinished': matchFinished,
    'pendingContinue': pendingContinue,
    'server': server,
    'teamAPlayers': teamAPlayers,
    'teamBPlayers': teamBPlayers,
    'timeoutsA': timeoutsA,
    'timeoutsB': timeoutsB,
    'setupDone': setupDone,
    'sidesSwapped': sidesSwapped,
    'earlyFinished': earlyFinished,
    'matchStartedAt': matchStartedAt?.toIso8601String(),
    'matchEndedAt': matchEndedAt?.toIso8601String(),
    'teamASide': teamASide.name,
    'pendingSideSwitch': pendingSideSwitch,
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
      ruleSet: VolleyballRuleSet.values.byName(
        json['ruleSet'] as String? ?? 'bvv',
      ),
      currentSetIndex: json['currentSetIndex'] as int? ?? 0,
      matchFinished: json['matchFinished'] as bool? ?? false,
      pendingContinue: json['pendingContinue'] as bool? ?? false,
      server: json['server'] as String?,
      teamAPlayers: List<String>.from(json['teamAPlayers'] ?? []),
      teamBPlayers: List<String>.from(json['teamBPlayers'] ?? []),
      timeoutsA: json['timeoutsA'] as int? ?? 0,
      timeoutsB: json['timeoutsB'] as int? ?? 0,
      setupDone: json['setupDone'] as bool? ?? false,
      sidesSwapped: json['sidesSwapped'] as bool? ?? false,
      earlyFinished: json['earlyFinished'] as bool? ?? false,
      matchStartedAt: json['matchStartedAt'] != null
          ? DateTime.parse(json['matchStartedAt'] as String)
          : null,
      matchEndedAt: json['matchEndedAt'] != null
          ? DateTime.parse(json['matchEndedAt'] as String)
          : null,
      teamASide: VolleyballSide.values.byName(
        json['teamASide'] as String? ?? 'left',
      ),
      pendingSideSwitch: json['pendingSideSwitch'] as bool? ?? false,
      canUndo: json['canUndo'] as bool? ?? false,
    );
  }

  VolleyballGameState copyWith({
    String? teamAName,
    String? teamBName,
    List<VolleyballSet>? sets,
    VolleyballType? type,
    VolleyballRules? rules,
    VolleyballRuleSet? ruleSet,
    int? currentSetIndex,
    bool? matchFinished,
    bool? pendingContinue,
    String? server,
    List<String>? teamAPlayers,
    List<String>? teamBPlayers,
    int? timeoutsA,
    int? timeoutsB,
    bool? setupDone,
    bool? sidesSwapped,
    bool? earlyFinished,
    DateTime? matchStartedAt,
    DateTime? matchEndedAt,
    VolleyballSide? teamASide,
    bool? pendingSideSwitch,
    bool? canUndo,
  }) {
    return VolleyballGameState(
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      sets: sets ?? this.sets,
      type: type ?? this.type,
      rules: rules ?? this.rules,
      ruleSet: ruleSet ?? this.ruleSet,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      matchFinished: matchFinished ?? this.matchFinished,
      pendingContinue: pendingContinue ?? this.pendingContinue,
      server: server ?? this.server,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
      timeoutsA: timeoutsA ?? this.timeoutsA,
      timeoutsB: timeoutsB ?? this.timeoutsB,
      setupDone: setupDone ?? this.setupDone,
      sidesSwapped: sidesSwapped ?? this.sidesSwapped,
      earlyFinished: earlyFinished ?? this.earlyFinished,
      matchStartedAt: matchStartedAt ?? this.matchStartedAt,
      matchEndedAt: matchEndedAt ?? this.matchEndedAt,
      teamASide: teamASide ?? this.teamASide,
      pendingSideSwitch: pendingSideSwitch ?? this.pendingSideSwitch,
      canUndo: canUndo ?? this.canUndo,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'rules': rules.toMap(),
    'ruleSet': ruleSet.name,
    'teamAName': teamAName,
    'teamBName': teamBName,
    'teamAPlayers': teamAPlayers,
    'teamBPlayers': teamBPlayers,
    'sets': sets.map((s) => s.toMap()).toList(),
    'currentSetIndex': currentSetIndex,
    'setsWonA': setsWonA,
    'setsWonB': setsWonB,
    'matchFinished': matchFinished,
    'pendingContinue': pendingContinue,
    'server': server,
    'timeoutsA': timeoutsA,
    'timeoutsB': timeoutsB,
    'setupDone': setupDone,
    'sidesSwapped': sidesSwapped,
    'matchStartedAt': matchStartedAt?.toIso8601String(),
    'matchEndedAt': matchEndedAt?.toIso8601String(),
    'teamASide': teamASide.name,
    'pendingSideSwitch': pendingSideSwitch,
  };

  factory VolleyballGameState.fromMap(Map<String, dynamic> map) =>
      VolleyballGameState(
        type: VolleyballType.values.byName(map['type'] ?? 'indoor'),
        rules: VolleyballRules.fromMap(map['rules']),
        ruleSet: VolleyballRuleSet.values.byName(map['ruleSet'] ?? 'bvv'),
        teamAName: map['teamAName'] ?? 'Team A',
        teamBName: map['teamBName'] ?? 'Team B',
        teamAPlayers: List<String>.from(map['teamAPlayers'] ?? []),
        teamBPlayers: List<String>.from(map['teamBPlayers'] ?? []),
        sets: (map['sets'] as List)
            .map((s) => VolleyballSet.fromMap(s))
            .toList(),
        currentSetIndex: map['currentSetIndex'] ?? 0,
        matchFinished: map['matchFinished'] ?? false,
        pendingContinue: map['pendingContinue'] ?? false,
        server: map['server'],
        timeoutsA: map['timeoutsA'] ?? 0,
        timeoutsB: map['timeoutsB'] ?? 0,
        setupDone: map['setupDone'] ?? false,
        sidesSwapped: map['sidesSwapped'] ?? false,
        matchStartedAt: map['matchStartedAt'] != null
            ? DateTime.parse(map['matchStartedAt'] as String)
            : null,
        matchEndedAt: map['matchEndedAt'] != null
            ? DateTime.parse(map['matchEndedAt'] as String)
            : null,
        teamASide: VolleyballSide.values.byName(map['teamASide'] ?? 'left'),
        pendingSideSwitch: map['pendingSideSwitch'] ?? false,
        canUndo: map['canUndo'] ?? false,
      );
}
