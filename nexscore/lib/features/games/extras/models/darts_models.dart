enum DartsFinishType {
  single,
  double,
  master, // double or treble
}

enum DartsStartType { straight, double, master }

class DartThrow {
  final int score;
  final int multiplier; // 1 (Single), 2 (Double), 3 (Treble)

  const DartThrow({required this.score, this.multiplier = 1});

  int get total => score * multiplier;

  Map<String, dynamic> toJson() => {'score': score, 'multiplier': multiplier};

  factory DartThrow.fromJson(Map<String, dynamic> json) {
    return DartThrow(
      score: json['score'] as int,
      multiplier: json['multiplier'] as int? ?? 1,
    );
  }
}

class DartRound {
  final List<DartThrow> throws; // Max 3
  final bool isDirect;
  final int? directScore;

  const DartRound({this.throws = const [], this.isDirect = false, this.directScore});

  int get roundTotal => isDirect ? (directScore ?? 0) : throws.fold(0, (sum, t) => sum + t.total);

  Map<String, dynamic> toJson() => {
    'throws': throws.map((t) => t.toJson()).toList(),
    'isDirect': isDirect,
    'directScore': directScore,
  };

  factory DartRound.fromJson(Map<String, dynamic> json) {
    return DartRound(
      throws: (json['throws'] as List?)
              ?.map((t) => DartThrow.fromJson(t))
              .toList() ??
          [],
      isDirect: json['isDirect'] as bool? ?? false,
      directScore: json['directScore'] as int?,
    );
  }
}

class DartPlayerState {
  final int startingScore; // e.g. 301 or 501
  final List<DartRound> rounds;
  final DartsFinishType finishType;
  final DartsStartType startType;

  const DartPlayerState({
    required this.startingScore,
    this.rounds = const [],
    this.finishType = DartsFinishType.double,
    this.startType = DartsStartType.straight,
  });

  /// Calculates the current score based on X01 rules with variant support.
  int get currentScore {
    int score = startingScore;
    bool hasStarted = startType == DartsStartType.straight;

    for (final round in rounds) {
      if (round.isDirect) {
        final roundTotal = round.roundTotal;
        if (!hasStarted) {
          // If Direct Entry is used, we assume any score > 0 starts the game if double/master start is required,
          // or we just check if it's non-zero. To keep it simple, we treat it as starting the game.
          if (roundTotal > 0) {
            hasStarted = true;
          }
        }
        if (hasStarted) {
          final newScore = score - roundTotal;
          if (newScore > 1) {
            score = newScore;
          } else if (newScore == 0) {
            // For simplified mode, let's assume they entered a valid finish if it brings them to 0.
            score = 0;
          }
          // if newScore < 0 or == 1, it's a bust, so score remains unchanged (current round total ignored).
        }
        if (score == 0) break;
        continue;
      }

      int roundRemaining = score;
      bool roundBust = false;
      bool roundStartedAtBeginning = hasStarted;

      for (int i = 0; i < round.throws.length; i++) {
        final t = round.throws[i];

        // Handle Start Type
        if (!hasStarted) {
          if (startType == DartsStartType.double && t.multiplier == 2) {
            hasStarted = true;
          } else if (startType == DartsStartType.master &&
              (t.multiplier == 2 || t.multiplier == 3)) {
            hasStarted = true;
          }

          if (!hasStarted) continue; // Throw doesn't count until started
        }

        final newScore = roundRemaining - t.total;

        if (newScore > 1) {
          roundRemaining = newScore;
        } else if (newScore == 0) {
          // Finish Logic
          bool validFinish = false;
          if (finishType == DartsFinishType.single) {
            validFinish = true;
          } else if (finishType == DartsFinishType.double &&
              t.multiplier == 2) {
            validFinish = true;
          } else if (finishType == DartsFinishType.master &&
              (t.multiplier == 2 || t.multiplier == 3)) {
            validFinish = true;
          }

          if (validFinish) {
            roundRemaining = 0;
            break; // Game ends for this player
          } else {
            roundBust = true;
            break;
          }
        } else {
          // Bust! (Below 0 or exactly 1)
          roundBust = true;
          break;
        }
      }

      if (!roundBust) {
        score = roundRemaining;
      } else {
        // If we bust, we also need to revert the "hasStarted" flag if it was set in THIS round
        if (!roundStartedAtBeginning) {
          hasStarted = false;
        }
      }
      if (score == 0) break;
    }
    return score;
  }

  double get averagePerDart {
    if (rounds.isEmpty) return 0.0;
    int totalThrows = rounds.fold(0, (sum, r) => sum + (r.isDirect ? 3 : r.throws.length));
    if (totalThrows == 0) return 0.0;
    int totalScored = startingScore - currentScore;
    return totalScored / totalThrows;
  }

  DartPlayerState copyWith({
    int? startingScore,
    List<DartRound>? rounds,
    DartsFinishType? finishType,
    DartsStartType? startType,
  }) {
    return DartPlayerState(
      startingScore: startingScore ?? this.startingScore,
      rounds: rounds ?? this.rounds,
      finishType: finishType ?? this.finishType,
      startType: startType ?? this.startType,
    );
  }

  Map<String, dynamic> toJson() => {
    'startingScore': startingScore,
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'finishType': finishType.name,
    'startType': startType.name,
  };

  factory DartPlayerState.fromJson(Map<String, dynamic> json) {
    return DartPlayerState(
      startingScore: json['startingScore'] as int? ?? 301,
      rounds:
          (json['rounds'] as List?)
              ?.map((r) => DartRound.fromJson(r))
              .toList() ??
          [],
      finishType: DartsFinishType.values.firstWhere(
        (e) => e.name == json['finishType'],
        orElse: () => DartsFinishType.double,
      ),
      startType: DartsStartType.values.firstWhere(
        (e) => e.name == json['startType'],
        orElse: () => DartsStartType.straight,
      ),
    );
  }
}

class DartsGameState {
  final Map<String, DartPlayerState> playerStates;
  final int targetScore; // usually 301 or 501
  final DartsFinishType finishType;
  final DartsStartType startType;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool isDirectEntryMode;

  const DartsGameState({
    this.playerStates = const {},
    this.targetScore = 301,
    this.finishType = DartsFinishType.double,
    this.startType = DartsStartType.straight,
    this.startedAt,
    this.endedAt,
    this.canUndo = false,
    this.isDirectEntryMode = false,
  });

  DartsGameState copyWith({
    Map<String, DartPlayerState>? playerStates,
    int? targetScore,
    DartsFinishType? finishType,
    DartsStartType? startType,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? canUndo,
    bool? isDirectEntryMode,
  }) {
    return DartsGameState(
      playerStates: playerStates ?? this.playerStates,
      targetScore: targetScore ?? this.targetScore,
      finishType: finishType ?? this.finishType,
      startType: startType ?? this.startType,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      canUndo: canUndo ?? this.canUndo,
      isDirectEntryMode: isDirectEntryMode ?? this.isDirectEntryMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerStates': playerStates.map((k, v) => MapEntry(k, v.toJson())),
    'targetScore': targetScore,
    'finishType': finishType.name,
    'startType': startType.name,
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'canUndo': canUndo,
    'isDirectEntryMode': isDirectEntryMode,
  };

  factory DartsGameState.fromJson(Map<String, dynamic> json) {
    return DartsGameState(
      playerStates:
          (json['playerStates'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              DartPlayerState.fromJson(v as Map<String, dynamic>),
            ),
          ) ??
          {},
      targetScore: json['targetScore'] as int? ?? 301,
      finishType: DartsFinishType.values.firstWhere(
        (e) => e.name == json['finishType'],
        orElse: () => DartsFinishType.double,
      ),
      startType: DartsStartType.values.firstWhere(
        (e) => e.name == json['startType'],
        orElse: () => DartsStartType.straight,
      ),
      startedAt:
          json['startedAt'] != null
              ? DateTime.tryParse(json['startedAt'] as String)
              : null,
      endedAt:
          json['endedAt'] != null
              ? DateTime.tryParse(json['endedAt'] as String)
              : null,
      canUndo: json['canUndo'] ?? false,
      isDirectEntryMode: json['isDirectEntryMode'] ?? false,
    );
  }
}

/// Returns a list of checkout throws (e.g. ['T20', 'T19', 'D12']) or null if checkout not possible or not mapped.
List<String>? getCheckoutSuggestion(int score) {
  if (score < 2 || score > 170) return null;
  // Bogey numbers (no possible 3-dart checkout)
  if ([159, 162, 163, 165, 166, 168, 169].contains(score)) return null;

  // Pre-calculated beginner/standard double-out paths
  const checkoutMap = <int, List<String>>{
    2: ['D1'],
    3: ['S1', 'D1'],
    4: ['D2'],
    5: ['S1', 'D2'],
    6: ['D3'],
    7: ['S3', 'D2'],
    8: ['D4'],
    9: ['S1', 'D4'],
    10: ['D5'],
    11: ['S3', 'D4'],
    12: ['D6'],
    13: ['S5', 'D4'],
    14: ['D7'],
    15: ['S7', 'D4'],
    16: ['D8'],
    17: ['S1', 'D8'],
    18: ['D9'],
    19: ['S3', 'D8'],
    20: ['D10'],
    21: ['S5', 'D8'],
    22: ['D11'],
    23: ['S7', 'D8'],
    24: ['D12'],
    25: ['S9', 'D8'],
    26: ['D13'],
    27: ['S11', 'D8'],
    28: ['D14'],
    29: ['S13', 'D8'],
    30: ['D15'],
    31: ['S15', 'D8'],
    32: ['D16'],
    33: ['S1', 'D16'],
    34: ['D17'],
    35: ['S3', 'D16'],
    36: ['D18'],
    37: ['S5', 'D16'],
    38: ['D19'],
    39: ['S7', 'D16'],
    40: ['D20'],
    41: ['S9', 'D16'],
    42: ['S10', 'D16'],
    43: ['S11', 'D16'],
    44: ['S12', 'D16'],
    45: ['S13', 'D16'],
    46: ['S14', 'D16'],
    47: ['S15', 'D16'],
    48: ['S16', 'D16'],
    49: ['S17', 'D16'],
    50: ['D25'], // Bullseye
    51: ['S19', 'D16'],
    52: ['S20', 'D16'],
    53: ['S13', 'D20'],
    54: ['S14', 'D20'],
    55: ['S15', 'D20'],
    56: ['S16', 'D20'],
    57: ['S17', 'D20'],
    58: ['S18', 'D20'],
    59: ['S19', 'D20'],
    60: ['S20', 'D20'],
    61: ['T15', 'D8'],
    62: ['T10', 'D16'],
    63: ['T13', 'D12'],
    64: ['T16', 'D8'],
    65: ['T19', 'D4'],
    66: ['T10', 'D18'],
    67: ['T17', 'D8'],
    68: ['T16', 'D10'],
    69: ['T19', 'D6'],
    70: ['T10', 'D20'],
    71: ['T13', 'D16'],
    72: ['T16', 'D12'],
    73: ['T19', 'D8'],
    74: ['T14', 'D16'],
    75: ['T17', 'D12'],
    76: ['T20', 'D8'],
    77: ['T15', 'D16'],
    78: ['T18', 'D12'],
    79: ['T19', 'D11'],
    80: ['T20', 'D10'],
    81: ['T19', 'D12'],
    82: ['T14', 'D20'],
    83: ['T17', 'D16'],
    84: ['T20', 'D12'],
    85: ['T15', 'D20'],
    86: ['T18', 'D16'],
    87: ['T19', 'D15'],
    88: ['T20', 'D14'],
    89: ['T19', 'D16'],
    90: ['T20', 'D15'],
    91: ['T17', 'D20'],
    92: ['T20', 'D16'],
    93: ['T19', 'D18'],
    94: ['T18', 'D20'],
    95: ['T19', 'D19'],
    96: ['T20', 'D18'],
    97: ['T19', 'D20'],
    98: ['T20', 'D19'],
    99: ['T19', 'S10', 'D16'],
    100: ['T20', 'D20'],
    101: ['T17', 'S18', 'D16'],
    102: ['T20', 'S10', 'D16'],
    103: ['T19', 'S10', 'D18'],
    104: ['T20', 'S12', 'D16'],
    105: ['T19', 'S16', 'D16'],
    106: ['T20', 'S10', 'D18'],
    107: ['T19', 'S18', 'D16'],
    108: ['T20', 'S16', 'D16'],
    109: ['T19', 'S20', 'D16'],
    110: ['T20', 'S18', 'D16'],
    111: ['T20', 'S19', 'D16'],
    112: ['T20', 'S12', 'D20'],
    113: ['T19', 'S16', 'D20'],
    114: ['T20', 'S14', 'D20'],
    115: ['T20', 'S15', 'D20'],
    116: ['T20', 'S16', 'D20'],
    117: ['T20', 'S17', 'D20'],
    118: ['T20', 'S18', 'D20'],
    119: ['T19', 'T10', 'D16'],
    120: ['T20', 'S20', 'D20'],
    121: ['T20', 'T11', 'D14'],
    122: ['T18', 'T16', 'D10'],
    123: ['T19', 'T16', 'D9'],
    124: ['T20', 'T16', 'D8'],
    125: ['T20', 'T15', 'D10'],
    126: ['T19', 'T19', 'D6'],
    127: ['T20', 'T17', 'D8'],
    128: ['T18', 'T18', 'D10'],
    129: ['T19', 'T16', 'D12'],
    130: ['T20', 'T18', 'D8'],
    131: ['T20', 'T13', 'D16'],
    132: ['T20', 'T16', 'D12'],
    133: ['T20', 'T17', 'D11'],
    134: ['T20', 'T14', 'D16'],
    135: ['T20', 'T17', 'D12'],
    136: ['T20', 'T20', 'D8'],
    137: ['T19', 'T16', 'D16'],
    138: ['T20', 'T18', 'D12'],
    139: ['T19', 'T14', 'D20'],
    140: ['T20', 'T20', 'D10'],
    141: ['T20', 'T15', 'D18'],
    142: ['T20', 'T14', 'D20'],
    143: ['T20', 'T17', 'D16'],
    144: ['T20', 'T20', 'D12'],
    145: ['T20', 'T15', 'D20'],
    146: ['T20', 'T18', 'D16'],
    147: ['T19', 'T18', 'D18'],
    148: ['T20', 'T16', 'D20'],
    149: ['T20', 'T19', 'D16'],
    150: ['T20', 'T20', 'D15'],
    151: ['T20', 'T17', 'D20'],
    152: ['T20', 'T20', 'D16'],
    153: ['T20', 'T19', 'D18'],
    154: ['T20', 'T18', 'D20'],
    155: ['T19', 'T19', 'D20'],
    156: ['T20', 'T20', 'D18'],
    157: ['T20', 'T19', 'D20'],
    158: ['T20', 'T20', 'D19'],
    160: ['T20', 'T20', 'D20'],
    161: ['T20', 'T17', 'D25'],
    164: ['T20', 'T18', 'D25'],
    167: ['T20', 'T19', 'D25'],
    170: ['T20', 'T20', 'D25'],
  };

  return checkoutMap[score];
}
