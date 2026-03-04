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

  const DartPlayerState({required this.startingScore, this.rounds = const []});

  /// Calculates the current score based on X01 rules (Double out not strictly enforced yet, just absolute 0)
  int get currentScore {
    int score = startingScore;
    for (final round in rounds) {
      final newScore = score - round.roundTotal;
      if (newScore > 0) {
        score = newScore;
      } else if (newScore == 0) {
        // Double out condition would go here (last throw must have multiplier == 2)
        score = 0;
      } else {
        // Bust! Score doesn't change for this round.
      }
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

  DartPlayerState copyWith({int? startingScore, List<DartRound>? rounds}) {
    return DartPlayerState(
      startingScore: startingScore ?? this.startingScore,
      rounds: rounds ?? this.rounds,
    );
  }

  Map<String, dynamic> toJson() => {
    'startingScore': startingScore,
    'rounds': rounds.map((r) => r.toJson()).toList(),
  };

  factory DartPlayerState.fromJson(Map<String, dynamic> json) {
    return DartPlayerState(
      startingScore: json['startingScore'] as int? ?? 301,
      rounds:
          (json['rounds'] as List?)
              ?.map((r) => DartRound.fromJson(r))
              .toList() ??
          [],
    );
  }
}

class DartsGameState {
  final Map<String, DartPlayerState> playerStates;
  final int targetScore; // usually 301 or 501

  const DartsGameState({this.playerStates = const {}, this.targetScore = 301});

  DartsGameState copyWith({
    Map<String, DartPlayerState>? playerStates,
    int? targetScore,
  }) {
    return DartsGameState(
      playerStates: playerStates ?? this.playerStates,
      targetScore: targetScore ?? this.targetScore,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerStates': playerStates.map((k, v) => MapEntry(k, v.toJson())),
    'targetScore': targetScore,
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
    );
  }
}
