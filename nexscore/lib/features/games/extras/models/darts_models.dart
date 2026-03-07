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

  const DartRound({this.throws = const []});

  int get roundTotal => throws.fold(0, (sum, t) => sum + t.total);

  Map<String, dynamic> toJson() => {
    'throws': throws.map((t) => t.toJson()).toList(),
  };

  factory DartRound.fromJson(Map<String, dynamic> json) {
    return DartRound(
      throws: (json['throws'] as List)
          .map((t) => DartThrow.fromJson(t))
          .toList(),
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
    int totalThrows = rounds.fold(0, (sum, r) => sum + r.throws.length);
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

  const DartsGameState({
    this.playerStates = const {},
    this.targetScore = 301,
    this.finishType = DartsFinishType.double,
    this.startType = DartsStartType.straight,
  });

  DartsGameState copyWith({
    Map<String, DartPlayerState>? playerStates,
    int? targetScore,
    DartsFinishType? finishType,
    DartsStartType? startType,
  }) {
    return DartsGameState(
      playerStates: playerStates ?? this.playerStates,
      targetScore: targetScore ?? this.targetScore,
      finishType: finishType ?? this.finishType,
      startType: startType ?? this.startType,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerStates': playerStates.map((k, v) => MapEntry(k, v.toJson())),
    'targetScore': targetScore,
    'finishType': finishType.name,
    'startType': startType.name,
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
    );
  }
}
