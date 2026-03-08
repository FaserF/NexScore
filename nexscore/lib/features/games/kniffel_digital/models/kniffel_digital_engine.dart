import 'dart:math';

/// Phase of the digital Kniffel game.
enum KniffelDigitalPhase {
  setup, // Waiting to start
  rolling, // Player is rolling dice
  scoring, // Player choosing a category
  roundEnd, // All players done, show scores
  finished, // Game over
}

/// Scoring categories for Kniffel / Yahtzee.
enum KniffelCategory {
  ones,
  twos,
  threes,
  fours,
  fives,
  sixes,
  threeOfAKind,
  fourOfAKind,
  fullHouse,
  smallStraight,
  largeStraight,
  kniffel,
  chance,
}

/// State for a single player in digital Kniffel.
class KniffelDigitalPlayerState {
  final Map<KniffelCategory, int?> scores;
  final int bonusKniffels;

  const KniffelDigitalPlayerState({
    this.scores = const {},
    this.bonusKniffels = 0,
  });

  KniffelDigitalPlayerState copyWith({
    Map<KniffelCategory, int?>? scores,
    int? bonusKniffels,
  }) {
    return KniffelDigitalPlayerState(
      scores: scores ?? this.scores,
      bonusKniffels: bonusKniffels ?? this.bonusKniffels,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scores': scores.map((k, v) => MapEntry(k.name, v)),
      'bonusKniffels': bonusKniffels,
    };
  }

  factory KniffelDigitalPlayerState.fromMap(Map<String, dynamic> map) {
    final scoresMap = (map['scores'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(
        KniffelCategory.values.firstWhere((e) => e.name == k),
        v as int?,
      ),
    );
    return KniffelDigitalPlayerState(
      scores: scoresMap,
      bonusKniffels: map['bonusKniffels'] ?? 0,
    );
  }

  /// Upper section sum (ones through sixes).
  int get upperSum {
    int total = 0;
    for (final cat in [
      KniffelCategory.ones,
      KniffelCategory.twos,
      KniffelCategory.threes,
      KniffelCategory.fours,
      KniffelCategory.fives,
      KniffelCategory.sixes,
    ]) {
      total += scores[cat] ?? 0;
    }
    return total;
  }

  /// Upper section bonus (35 if sum >= 63).
  int get upperBonus => upperSum >= 63 ? 35 : 0;

  /// Lower section sum.
  int get lowerSum {
    int total = 0;
    for (final cat in [
      KniffelCategory.threeOfAKind,
      KniffelCategory.fourOfAKind,
      KniffelCategory.fullHouse,
      KniffelCategory.smallStraight,
      KniffelCategory.largeStraight,
      KniffelCategory.kniffel,
      KniffelCategory.chance,
    ]) {
      total += scores[cat] ?? 0;
    }
    return total;
  }

  /// Total score.
  int get totalScore =>
      upperSum + upperBonus + lowerSum + (bonusKniffels * 100);

  /// Whether all categories are filled.
  bool get isComplete =>
      scores.length == KniffelCategory.values.length &&
      scores.values.every((v) => v != null);
}

/// Full state of the digital Kniffel game.
class KniffelDigitalState {
  final KniffelDigitalPhase phase;
  final List<String> playerOrder;
  final Map<String, KniffelDigitalPlayerState> playerStates;
  final String? currentPlayerId;
  final List<int> dice; // Current 5 dice values (1-6)
  final List<bool> held; // Which dice are held
  final int rollsLeft; // 3 rolls per turn
  final int currentPlayerIndex;
  final int roundNumber; // 1-13 (13 categories)

  const KniffelDigitalState({
    this.phase = KniffelDigitalPhase.setup,
    this.playerOrder = const [],
    this.playerStates = const {},
    this.currentPlayerId,
    this.dice = const [1, 1, 1, 1, 1],
    this.held = const [false, false, false, false, false],
    this.rollsLeft = 3,
    this.currentPlayerIndex = 0,
    this.roundNumber = 1,
  });

  KniffelDigitalState copyWith({
    KniffelDigitalPhase? phase,
    List<String>? playerOrder,
    Map<String, KniffelDigitalPlayerState>? playerStates,
    String? currentPlayerId,
    List<int>? dice,
    List<bool>? held,
    int? rollsLeft,
    int? currentPlayerIndex,
    int? roundNumber,
  }) {
    return KniffelDigitalState(
      phase: phase ?? this.phase,
      playerOrder: playerOrder ?? this.playerOrder,
      playerStates: playerStates ?? this.playerStates,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      dice: dice ?? this.dice,
      held: held ?? this.held,
      rollsLeft: rollsLeft ?? this.rollsLeft,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      roundNumber: roundNumber ?? this.roundNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase.name,
      'playerOrder': playerOrder,
      'playerStates': playerStates.map((k, v) => MapEntry(k, v.toMap())),
      'currentPlayerId': currentPlayerId,
      'dice': dice,
      'held': held,
      'rollsLeft': rollsLeft,
      'currentPlayerIndex': currentPlayerIndex,
      'roundNumber': roundNumber,
    };
  }

  factory KniffelDigitalState.fromMap(Map<String, dynamic> map) {
    return KniffelDigitalState(
      phase: KniffelDigitalPhase.values.firstWhere(
        (e) => e.name == map['phase'],
        orElse: () => KniffelDigitalPhase.setup,
      ),
      playerOrder: List<String>.from(map['playerOrder'] ?? []),
      playerStates: (map['playerStates'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          KniffelDigitalPlayerState.fromMap(v as Map<String, dynamic>),
        ),
      ),
      currentPlayerId: map['currentPlayerId'],
      dice: List<int>.from(map['dice'] ?? [1, 1, 1, 1, 1]),
      held: List<bool>.from(map['held'] ?? [false, false, false, false, false]),
      rollsLeft: map['rollsLeft'] ?? 3,
      currentPlayerIndex: map['currentPlayerIndex'] ?? 0,
      roundNumber: map['roundNumber'] ?? 1,
    );
  }
}

/// Core game engine for digital Kniffel (Yahtzee).
class KniffelDigitalEngine {
  final Random _random = Random();

  /// Initialize a new game.
  KniffelDigitalState initializeGame(List<String> playerIds) {
    return KniffelDigitalState(
      playerOrder: playerIds,
      playerStates: {
        for (final p in playerIds) p: const KniffelDigitalPlayerState(),
      },
      currentPlayerId: playerIds.first,
      phase: KniffelDigitalPhase.rolling,
      rollsLeft: 3,
    );
  }

  /// Roll the dice (un-held dice get re-rolled).
  KniffelDigitalState rollDice(KniffelDigitalState state) {
    if (state.rollsLeft <= 0) return state;

    final newDice = List<int>.from(state.dice);
    for (int i = 0; i < 5; i++) {
      if (!state.held[i]) {
        newDice[i] = _random.nextInt(6) + 1;
      }
    }

    return state.copyWith(
      dice: newDice,
      rollsLeft: state.rollsLeft - 1,
      phase: KniffelDigitalPhase.scoring,
    );
  }

  /// Toggle hold status of a die.
  KniffelDigitalState toggleHold(KniffelDigitalState state, int index) {
    if (state.rollsLeft >= 3) return state; // Can't hold before first roll
    final newHeld = List<bool>.from(state.held);
    newHeld[index] = !newHeld[index];
    return state.copyWith(held: newHeld);
  }

  /// Score the current dice in a category.
  KniffelDigitalState scoreCategory(
    KniffelDigitalState state,
    KniffelCategory category,
  ) {
    final pid = state.currentPlayerId!;
    final pState = state.playerStates[pid]!;

    // Can't score in already-filled category
    if (pState.scores.containsKey(category)) return state;

    final score = calculateScore(state.dice, category);

    // Check for bonus Kniffel
    int bonusCount = pState.bonusKniffels;
    if (_isKniffel(state.dice) &&
        pState.scores.containsKey(KniffelCategory.kniffel) &&
        pState.scores[KniffelCategory.kniffel]! > 0) {
      bonusCount++;
    }

    final newScores = Map<KniffelCategory, int?>.from(pState.scores);
    newScores[category] = score;

    final newStates = Map<String, KniffelDigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[pid] = pState.copyWith(
      scores: newScores,
      bonusKniffels: bonusCount,
    );

    // Move to next player or next round
    return _advanceTurn(state.copyWith(playerStates: newStates));
  }

  /// Advance to next player's turn or next round.
  KniffelDigitalState _advanceTurn(KniffelDigitalState state) {
    final nextPlayerIndex = state.currentPlayerIndex + 1;

    if (nextPlayerIndex < state.playerOrder.length) {
      // Next player in this round
      return state.copyWith(
        currentPlayerIndex: nextPlayerIndex,
        currentPlayerId: state.playerOrder[nextPlayerIndex],
        dice: [1, 1, 1, 1, 1],
        held: [false, false, false, false, false],
        rollsLeft: 3,
        phase: KniffelDigitalPhase.rolling,
      );
    }

    // All players have played this round
    final nextRound = state.roundNumber + 1;
    if (nextRound > 13) {
      // Game is over
      return state.copyWith(phase: KniffelDigitalPhase.finished);
    }

    return state.copyWith(
      roundNumber: nextRound,
      currentPlayerIndex: 0,
      currentPlayerId: state.playerOrder.first,
      dice: [1, 1, 1, 1, 1],
      held: [false, false, false, false, false],
      rollsLeft: 3,
      phase: KniffelDigitalPhase.rolling,
    );
  }

  /// Calculate the score for a given set of dice in a category.
  int calculateScore(List<int> dice, KniffelCategory category) {
    final sorted = List<int>.from(dice)..sort();
    final counts = <int, int>{};
    for (final d in dice) {
      counts[d] = (counts[d] ?? 0) + 1;
    }
    final sum = dice.fold<int>(0, (s, d) => s + d);

    switch (category) {
      case KniffelCategory.ones:
        return dice.where((d) => d == 1).fold(0, (s, _) => s + 1);
      case KniffelCategory.twos:
        return dice.where((d) => d == 2).fold(0, (s, _) => s + 2);
      case KniffelCategory.threes:
        return dice.where((d) => d == 3).fold(0, (s, _) => s + 3);
      case KniffelCategory.fours:
        return dice.where((d) => d == 4).fold(0, (s, _) => s + 4);
      case KniffelCategory.fives:
        return dice.where((d) => d == 5).fold(0, (s, _) => s + 5);
      case KniffelCategory.sixes:
        return dice.where((d) => d == 6).fold(0, (s, _) => s + 6);
      case KniffelCategory.threeOfAKind:
        return counts.values.any((c) => c >= 3) ? sum : 0;
      case KniffelCategory.fourOfAKind:
        return counts.values.any((c) => c >= 4) ? sum : 0;
      case KniffelCategory.fullHouse:
        return (counts.values.contains(3) && counts.values.contains(2))
            ? 25
            : 0;
      case KniffelCategory.smallStraight:
        return _hasSmallStraight(sorted) ? 30 : 0;
      case KniffelCategory.largeStraight:
        return _hasLargeStraight(sorted) ? 40 : 0;
      case KniffelCategory.kniffel:
        return _isKniffel(dice) ? 50 : 0;
      case KniffelCategory.chance:
        return sum;
    }
  }

  bool _isKniffel(List<int> dice) => dice.every((d) => d == dice.first);

  bool _hasSmallStraight(List<int> sorted) {
    final unique = sorted.toSet().toList()..sort();
    for (int i = 0; i <= unique.length - 4; i++) {
      if (unique[i + 1] == unique[i] + 1 &&
          unique[i + 2] == unique[i] + 2 &&
          unique[i + 3] == unique[i] + 3) {
        return true;
      }
    }
    return false;
  }

  bool _hasLargeStraight(List<int> sorted) {
    final unique = sorted.toSet().toList()..sort();
    if (unique.length < 5) return false;
    for (int i = 0; i < 4; i++) {
      if (unique[i + 1] != unique[i] + 1) return false;
    }
    return true;
  }

  /// Get available categories for a player.
  List<KniffelCategory> getAvailableCategories(
    KniffelDigitalState state,
    String playerId,
  ) {
    final pState = state.playerStates[playerId]!;
    return KniffelCategory.values
        .where((cat) => !pState.scores.containsKey(cat))
        .toList();
  }
}
