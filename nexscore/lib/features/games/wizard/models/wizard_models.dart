/// Scoring variants for Wizard.
enum WizardScoringVariant { standard, lenient, extreme }

/// A single round of Wizard tracking per-player bids and tricks won.
class WizardRound {
  final int roundIndex;
  final Map<String, int> bids;
  final Map<String, int> tricks;

  const WizardRound({
    required this.roundIndex,
    this.bids = const {},
    this.tricks = const {},
  });

  Map<String, dynamic> toJson() => {
    'roundIndex': roundIndex,
    'bids': bids,
    'tricks': tricks,
  };

  factory WizardRound.fromJson(Map<String, dynamic> json) {
    return WizardRound(
      roundIndex: json['roundIndex'] as int,
      bids: Map<String, int>.from(json['bids'] as Map),
      tricks: Map<String, int>.from(json['tricks'] as Map),
    );
  }

  WizardRound copyWith({
    int? roundIndex,
    Map<String, int>? bids,
    Map<String, int>? tricks,
  }) {
    return WizardRound(
      roundIndex: roundIndex ?? this.roundIndex,
      bids: bids ?? this.bids,
      tricks: tricks ?? this.tricks,
    );
  }
}

class WizardGameState {
  final List<WizardRound> rounds;
  final WizardScoringVariant scoringVariant;
  final bool ruleSticheDuertenNichtAufgehen;
  final int customStartRound;
  final Map<String, int>? currentRoundBids;

  const WizardGameState({
    this.rounds = const [],
    this.scoringVariant = WizardScoringVariant.standard,
    this.ruleSticheDuertenNichtAufgehen = false,
    this.customStartRound = 1,
    this.currentRoundBids,
  });

  bool get isLenientScoring => scoringVariant == WizardScoringVariant.lenient;

  Map<String, dynamic> toJson() => {
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'scoringVariant': scoringVariant.name,
    'ruleSticheDuertenNichtAufgehen': ruleSticheDuertenNichtAufgehen,
    'customStartRound': customStartRound,
    'currentRoundBids': currentRoundBids,
  };

  factory WizardGameState.fromJson(Map<String, dynamic> json) {
    return WizardGameState(
      rounds: (json['rounds'] as List)
          .map((r) => WizardRound.fromJson(r as Map<String, dynamic>))
          .toList(),
      scoringVariant: WizardScoringVariant.values.firstWhere(
        (v) => v.name == (json['scoringVariant'] as String? ?? 'standard'),
        orElse: () => WizardScoringVariant.standard,
      ),
      ruleSticheDuertenNichtAufgehen:
          json['ruleSticheDuertenNichtAufgehen'] as bool? ?? false,
      customStartRound: json['customStartRound'] as int? ?? 1,
      currentRoundBids: json['currentRoundBids'] != null
          ? Map<String, int>.from(json['currentRoundBids'] as Map)
          : null,
    );
  }

  WizardGameState copyWith({
    List<WizardRound>? rounds,
    WizardScoringVariant? scoringVariant,
    bool? ruleSticheDuertenNichtAufgehen,
    int? customStartRound,
    Map<String, int>? currentRoundBids,
    bool resetBids = false,
  }) {
    return WizardGameState(
      rounds: rounds ?? this.rounds,
      scoringVariant: scoringVariant ?? this.scoringVariant,
      ruleSticheDuertenNichtAufgehen:
          ruleSticheDuertenNichtAufgehen ?? this.ruleSticheDuertenNichtAufgehen,
      customStartRound: customStartRound ?? this.customStartRound,
      currentRoundBids: resetBids
          ? null
          : (currentRoundBids ?? this.currentRoundBids),
    );
  }

  /// Calculates the total score for a player across all rounds.
  ///
  /// **Standard:** Correct bid = +20 + (tricks × 10). Wrong bid = -(diff × 10).
  /// **Lenient:** Correct bid = +20 + (tricks × 10). Wrong bid = (tricks × 10) - (diff × 10).
  /// **Extreme:** Correct bid = +30 + (tricks × 10). Wrong bid = -(diff × 20) — double penalty.
  static int calculatePlayerScore(
    String playerId,
    List<WizardRound> rounds, {
    bool lenient = false,
    bool extreme = false,
  }) {
    int totalScore = 0;

    for (final round in rounds) {
      if (!round.bids.containsKey(playerId) ||
          !round.tricks.containsKey(playerId)) {
        continue;
      }

      final int bid = round.bids[playerId]!;
      final int trick = round.tricks[playerId]!;

      if (bid == trick) {
        totalScore += extreme ? (30 + trick * 10) : (20 + trick * 10);
      } else {
        final int diff = (bid - trick).abs();
        if (lenient) {
          totalScore += (trick * 10) - (diff * 10);
        } else if (extreme) {
          totalScore -= diff * 20;
        } else {
          totalScore -= diff * 10;
        }
      }
    }
    return totalScore;
  }
}
