/// Scoring variants for Wizard.
enum WizardScoringVariant { standard, lenient, extreme }

/// A single round of Wizard tracking per-player bids and tricks won.
class WizardRound {
  final int roundIndex;
  final Map<String, int> bids;
  final Map<String, int> tricks;
  final int blownTricks; // For "Bomb" cards
  final Map<String, bool> playedDragon;
  final Map<String, bool> playedFairy;

  const WizardRound({
    required this.roundIndex,
    this.bids = const {},
    this.tricks = const {},
    this.blownTricks = 0,
    this.playedDragon = const {},
    this.playedFairy = const {},
  });

  Map<String, dynamic> toJson() => {
    'roundIndex': roundIndex,
    'bids': bids,
    'tricks': tricks,
    'blownTricks': blownTricks,
  };

  factory WizardRound.fromJson(Map<String, dynamic> json) {
    return WizardRound(
      roundIndex: json['roundIndex'] as int,
      bids: Map<String, int>.from(json['bids'] as Map),
      tricks: Map<String, int>.from(json['tricks'] as Map),
      blownTricks: json['blownTricks'] as int? ?? 0,
      playedDragon: Map<String, bool>.from(json['playedDragon'] ?? {}),
      playedFairy: Map<String, bool>.from(json['playedFairy'] ?? {}),
    );
  }

  WizardRound copyWith({
    int? roundIndex,
    Map<String, int>? bids,
    Map<String, int>? tricks,
    int? blownTricks,
    Map<String, bool>? playedDragon,
    Map<String, bool>? playedFairy,
  }) {
    return WizardRound(
      roundIndex: roundIndex ?? this.roundIndex,
      bids: bids ?? this.bids,
      tricks: tricks ?? this.tricks,
      blownTricks: blownTricks ?? this.blownTricks,
      playedDragon: playedDragon ?? this.playedDragon,
      playedFairy: playedFairy ?? this.playedFairy,
    );
  }
}

class WizardGameState {
  final List<WizardRound> rounds;
  final WizardScoringVariant scoringVariant;
  final bool ruleSticheDuertenNichtAufgehen;
  final int customStartRound;
  final int? customTotalRounds;
  final bool jesterTrumpRules;
  final bool anniversaryCards;
  final Map<String, int>? currentRoundBids;
  final bool canUndo;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const WizardGameState({
    this.rounds = const [],
    this.scoringVariant = WizardScoringVariant.standard,
    this.ruleSticheDuertenNichtAufgehen = false,
    this.customStartRound = 1,
    this.customTotalRounds,
    this.jesterTrumpRules = false,
    this.anniversaryCards = false,
    this.currentRoundBids,
    this.canUndo = false,
    this.startedAt,
    this.endedAt,
  });

  bool get isLenientScoring => scoringVariant == WizardScoringVariant.lenient;

  Map<String, dynamic> toJson() => {
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'scoringVariant': scoringVariant.name,
    'ruleSticheDuertenNichtAufgehen': ruleSticheDuertenNichtAufgehen,
    'customStartRound': customStartRound,
    'customTotalRounds': customTotalRounds,
    'jesterTrumpRules': jesterTrumpRules,
    'anniversaryCards': anniversaryCards,
    'currentRoundBids': currentRoundBids,
    'canUndo': canUndo,
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
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
      customTotalRounds: json['customTotalRounds'] as int?,
      jesterTrumpRules: json['jesterTrumpRules'] as bool? ?? false,
      currentRoundBids: json['currentRoundBids'] != null
          ? Map<String, int>.from(json['currentRoundBids'] as Map)
          : null,
      canUndo: json['canUndo'] as bool? ?? false,
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'] as String)
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
    );
  }

  WizardGameState copyWith({
    List<WizardRound>? rounds,
    WizardScoringVariant? scoringVariant,
    bool? ruleSticheDuertenNichtAufgehen,
    int? customStartRound,
    int? customTotalRounds,
    bool? jesterTrumpRules,
    bool? anniversaryCards,
    Map<String, int>? currentRoundBids,
    bool resetBids = false,
    bool? canUndo,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return WizardGameState(
      rounds: rounds ?? this.rounds,
      scoringVariant: scoringVariant ?? this.scoringVariant,
      ruleSticheDuertenNichtAufgehen:
          ruleSticheDuertenNichtAufgehen ?? this.ruleSticheDuertenNichtAufgehen,
      customStartRound: customStartRound ?? this.customStartRound,
      customTotalRounds: customTotalRounds ?? this.customTotalRounds,
      jesterTrumpRules: jesterTrumpRules ?? this.jesterTrumpRules,
      anniversaryCards: anniversaryCards ?? this.anniversaryCards,
      currentRoundBids: resetBids
          ? null
          : (currentRoundBids ?? this.currentRoundBids),
      canUndo: canUndo ?? this.canUndo,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
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

      int roundScore = 0;
      if (bid == trick) {
        roundScore = extreme ? (30 + trick * 10) : (20 + trick * 10);
      } else {
        final int diff = (bid - trick).abs();
        if (lenient) {
          roundScore = (trick * 10) - (diff * 10);
        } else if (extreme) {
          roundScore = -(diff * 20);
        } else {
          roundScore = -(diff * 10);
        }
      }

      // Anniversary Cards Scoring
      if (round.playedDragon[playerId] == true) {
        // Dragon: Win the trick = +10, lose = -10 (if part of bid)
        // Standard simplifies: If you played it and win the trick, usually it just helps your bid.
        // Anniversary rules: +10 if you win the trick with it.
        roundScore += 10;
      }
      if (round.playedFairy[playerId] == true) {
        roundScore -= 10; // Fairy: Often -10 points or similar.
      }

      totalScore += roundScore;
    }
    return totalScore;
  }

  /// Returns the IDs of the players with the highest score.
  List<String> getLeaders(List<String> playerIds) {
    if (playerIds.isEmpty) return [];
    int maxScore = -999999;
    final Map<String, int> scores = {};
    for (final pid in playerIds) {
      final score = calculatePlayerScore(
        pid,
        rounds,
        lenient: scoringVariant == WizardScoringVariant.lenient,
        extreme: scoringVariant == WizardScoringVariant.extreme,
      );
      scores[pid] = score;
      if (score > maxScore) maxScore = score;
    }
    return playerIds.where((pid) => scores[pid] == maxScore).toList();
  }
}
