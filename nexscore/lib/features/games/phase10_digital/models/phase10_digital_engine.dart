import 'dart:math';

/// Phase definitions for Phase 10 game (the 10 phases).
class Phase10PhaseDefinition {
  final int number;
  final String description;
  final String descriptionDe;
  final List<Phase10Requirement> requirements;

  const Phase10PhaseDefinition({
    required this.number,
    required this.description,
    required this.descriptionDe,
    required this.requirements,
  });

  static const List<Phase10PhaseDefinition> allPhases = [
    Phase10PhaseDefinition(
      number: 1,
      description: '2 sets of 3',
      descriptionDe: '2 Drillinge',
      requirements: [Phase10Requirement.set3, Phase10Requirement.set3],
    ),
    Phase10PhaseDefinition(
      number: 2,
      description: '1 set of 3 + 1 run of 4',
      descriptionDe: '1 Drilling + 1 Viererfolge',
      requirements: [Phase10Requirement.set3, Phase10Requirement.run4],
    ),
    Phase10PhaseDefinition(
      number: 3,
      description: '1 set of 4 + 1 run of 4',
      descriptionDe: '1 Vierling + 1 Viererfolge',
      requirements: [Phase10Requirement.set4, Phase10Requirement.run4],
    ),
    Phase10PhaseDefinition(
      number: 4,
      description: '1 run of 7',
      descriptionDe: '1 Siebenerfolge',
      requirements: [Phase10Requirement.run7],
    ),
    Phase10PhaseDefinition(
      number: 5,
      description: '1 run of 8',
      descriptionDe: '1 Achterfolge',
      requirements: [Phase10Requirement.run8],
    ),
    Phase10PhaseDefinition(
      number: 6,
      description: '1 run of 9',
      descriptionDe: '1 Neunerfolge',
      requirements: [Phase10Requirement.run9],
    ),
    Phase10PhaseDefinition(
      number: 7,
      description: '2 sets of 4',
      descriptionDe: '2 Vierlinge',
      requirements: [Phase10Requirement.set4, Phase10Requirement.set4],
    ),
    Phase10PhaseDefinition(
      number: 8,
      description: '7 cards of one color',
      descriptionDe: '7 Karten einer Farbe',
      requirements: [Phase10Requirement.color7],
    ),
    Phase10PhaseDefinition(
      number: 9,
      description: '1 set of 5 + 1 set of 2',
      descriptionDe: '1 Fünfling + 1 Zwilling',
      requirements: [Phase10Requirement.set5, Phase10Requirement.set2],
    ),
    Phase10PhaseDefinition(
      number: 10,
      description: '1 set of 5 + 1 set of 3',
      descriptionDe: '1 Fünfling + 1 Drilling',
      requirements: [Phase10Requirement.set5, Phase10Requirement.set3],
    ),
  ];
}

enum Phase10Requirement {
  set2,
  set3,
  set4,
  set5,
  run4,
  run7,
  run8,
  run9,
  color7,
}

/// A Phase 10 card (values 1-12 in 4 colors + Skip + Wild).
class Phase10Card {
  final String id;
  final int value; // 1-12, 0=Wild, 13=Skip
  final int colorIdx; // 0-3 (Red, Blue, Green, Yellow)
  final bool isWild;
  final bool isSkip;

  const Phase10Card({
    required this.id,
    required this.value,
    required this.colorIdx,
    this.isWild = false,
    this.isSkip = false,
  });

  int get points {
    if (isSkip) return 15;
    if (isWild) return 25;
    if (value >= 10) return 10;
    return 5;
  }

  String get shortLabel {
    if (isWild) return 'W';
    if (isSkip) return 'S';
    return '$value';
  }

  /// Color index for display purposes (0=Red, 1=Blue, 2=Green, 3=Yellow).
  int get colorIndex => colorIdx;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Phase10Card && id == other.id;
  @override
  int get hashCode => id.hashCode;
}

/// Phase 10 game phases.
enum Phase10DigitalPhase { setup, playing, finished }

/// Player state.
class Phase10DigitalPlayerState {
  final List<Phase10Card> hand;
  final int currentPhase; // 1-10
  final bool hasLaidPhase; // Has laid down phase this round?
  final bool hasDrawn;
  final int totalPoints;

  const Phase10DigitalPlayerState({
    this.hand = const [],
    this.currentPhase = 1,
    this.hasLaidPhase = false,
    this.hasDrawn = false,
    this.totalPoints = 0,
  });

  Phase10DigitalPlayerState copyWith({
    List<Phase10Card>? hand,
    int? currentPhase,
    bool? hasLaidPhase,
    bool? hasDrawn,
    int? totalPoints,
  }) {
    return Phase10DigitalPlayerState(
      hand: hand ?? this.hand,
      currentPhase: currentPhase ?? this.currentPhase,
      hasLaidPhase: hasLaidPhase ?? this.hasLaidPhase,
      hasDrawn: hasDrawn ?? this.hasDrawn,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

/// Full game state.
class Phase10DigitalState {
  final Phase10DigitalPhase phase;
  final List<String> playerOrder;
  final Map<String, Phase10DigitalPlayerState> playerStates;
  final List<Phase10Card> drawPile;
  final List<Phase10Card> discardPile;
  final String? currentPlayerId;
  final int currentPlayerIndex;
  final int roundNumber;

  const Phase10DigitalState({
    this.phase = Phase10DigitalPhase.setup,
    this.playerOrder = const [],
    this.playerStates = const {},
    this.drawPile = const [],
    this.discardPile = const [],
    this.currentPlayerId,
    this.currentPlayerIndex = 0,
    this.roundNumber = 1,
  });

  Phase10DigitalState copyWith({
    Phase10DigitalPhase? phase,
    List<String>? playerOrder,
    Map<String, Phase10DigitalPlayerState>? playerStates,
    List<Phase10Card>? drawPile,
    List<Phase10Card>? discardPile,
    String? currentPlayerId,
    int? currentPlayerIndex,
    int? roundNumber,
  }) {
    return Phase10DigitalState(
      phase: phase ?? this.phase,
      playerOrder: playerOrder ?? this.playerOrder,
      playerStates: playerStates ?? this.playerStates,
      drawPile: drawPile ?? this.drawPile,
      discardPile: discardPile ?? this.discardPile,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      roundNumber: roundNumber ?? this.roundNumber,
    );
  }
}

/// Core Phase 10 engine.
class Phase10DigitalEngine {
  final Random _random = Random();

  /// Generate a Phase 10 deck (108 cards).
  List<Phase10Card> _generateDeck() {
    final cards = <Phase10Card>[];
    int idx = 0;
    // 2 of each number 1-12 in each of 4 colors
    for (int copy = 0; copy < 2; copy++) {
      for (int color = 0; color < 4; color++) {
        for (int val = 1; val <= 12; val++) {
          cards.add(
            Phase10Card(id: 'p10_${idx++}', value: val, colorIdx: color),
          );
        }
      }
    }
    // 8 Wild cards
    for (int i = 0; i < 8; i++) {
      cards.add(
        Phase10Card(id: 'p10_w${idx++}', value: 0, colorIdx: 0, isWild: true),
      );
    }
    // 4 Skip cards
    for (int i = 0; i < 4; i++) {
      cards.add(
        Phase10Card(id: 'p10_s${idx++}', value: 13, colorIdx: 0, isSkip: true),
      );
    }
    return cards;
  }

  Phase10DigitalState initializeGame(List<String> playerIds) {
    return Phase10DigitalState(
      playerOrder: playerIds,
      playerStates: {
        for (final p in playerIds) p: const Phase10DigitalPlayerState(),
      },
    );
  }

  Phase10DigitalState dealRound(Phase10DigitalState state) {
    final deck = _generateDeck()..shuffle(_random);

    final newStates = <String, Phase10DigitalPlayerState>{};
    int cardIndex = 0;
    for (final pid in state.playerOrder) {
      final hand = deck.sublist(cardIndex, cardIndex + 10);
      hand.sort((a, b) {
        if (a.isWild && !b.isWild) return 1;
        if (!a.isWild && b.isWild) return -1;
        if (a.isSkip && !b.isSkip) return 1;
        if (!a.isSkip && b.isSkip) return -1;
        return a.value.compareTo(b.value);
      });
      newStates[pid] = state.playerStates[pid]!.copyWith(
        hand: hand,
        hasLaidPhase: false,
        hasDrawn: false,
      );
      cardIndex += 10;
    }

    return state.copyWith(
      playerStates: newStates,
      drawPile: deck.sublist(cardIndex + 1),
      discardPile: [deck[cardIndex]],
      currentPlayerId: state.playerOrder.first,
      currentPlayerIndex: 0,
      phase: Phase10DigitalPhase.playing,
    );
  }

  Phase10DigitalState startGame(Phase10DigitalState state) {
    return dealRound(state);
  }

  Phase10DigitalState drawFromPile(Phase10DigitalState state, String playerId) {
    if (state.drawPile.isEmpty) return state;
    final pState = state.playerStates[playerId]!;
    if (pState.hasDrawn) return state;

    final card = state.drawPile.first;
    final newStates = Map<String, Phase10DigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(
      hand: [...pState.hand, card],
      hasDrawn: true,
    );

    return state.copyWith(
      playerStates: newStates,
      drawPile: state.drawPile.sublist(1),
    );
  }

  Phase10DigitalState drawFromDiscard(
    Phase10DigitalState state,
    String playerId,
  ) {
    if (state.discardPile.isEmpty) return state;
    final pState = state.playerStates[playerId]!;
    if (pState.hasDrawn) return state;

    final card = state.discardPile.last;
    final newStates = Map<String, Phase10DigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(
      hand: [...pState.hand, card],
      hasDrawn: true,
    );

    return state.copyWith(
      playerStates: newStates,
      discardPile: state.discardPile.sublist(0, state.discardPile.length - 1),
    );
  }

  /// Discard a card and end turn.
  Phase10DigitalState discardCard(
    Phase10DigitalState state,
    String playerId,
    Phase10Card card,
  ) {
    final pState = state.playerStates[playerId]!;
    if (!pState.hasDrawn) return state;

    final newHand = List<Phase10Card>.from(pState.hand)
      ..removeWhere((c) => c.id == card.id);

    final newStates = Map<String, Phase10DigitalPlayerState>.from(
      state.playerStates,
    );

    // Check if player won the round
    if (newHand.isEmpty) {
      // Advance phase if they laid it
      int nextPhase = pState.currentPhase;
      if (pState.hasLaidPhase && nextPhase < 10) {
        nextPhase++;
      }

      // score penalty points for other players
      for (final pid in state.playerOrder) {
        if (pid == playerId) {
          newStates[pid] = pState.copyWith(
            hand: newHand,
            hasDrawn: false,
            currentPhase: nextPhase,
          );
        } else {
          final other = newStates[pid] ?? state.playerStates[pid]!;
          final penalty = other.hand.fold<int>(0, (s, c) => s + c.points);
          newStates[pid] = other.copyWith(
            totalPoints: other.totalPoints + penalty,
            hasDrawn: false,
          );
        }
      }

      // Check if someone completed Phase 10
      bool gameOver = nextPhase > 10;
      return state.copyWith(
        playerStates: newStates,
        discardPile: [...state.discardPile, card],
        phase: gameOver
            ? Phase10DigitalPhase.finished
            : Phase10DigitalPhase.playing,
        roundNumber: state.roundNumber + 1,
      );
    }

    newStates[playerId] = pState.copyWith(hand: newHand, hasDrawn: false);

    final nextIdx = (state.currentPlayerIndex + 1) % state.playerOrder.length;
    return state.copyWith(
      playerStates: newStates,
      discardPile: [...state.discardPile, card],
      currentPlayerIndex: nextIdx,
      currentPlayerId: state.playerOrder[nextIdx],
    );
  }

  /// Lay down phase cards. Simplified: marks as laid.
  Phase10DigitalState layPhase(
    Phase10DigitalState state,
    String playerId,
    List<Phase10Card> cards,
  ) {
    final pState = state.playerStates[playerId]!;
    if (pState.hasLaidPhase) return state;

    final newHand = List<Phase10Card>.from(pState.hand);
    for (final card in cards) {
      newHand.removeWhere((c) => c.id == card.id);
    }

    final newStates = Map<String, Phase10DigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(hand: newHand, hasLaidPhase: true);

    return state.copyWith(playerStates: newStates);
  }

  Phase10DigitalState startNextRound(Phase10DigitalState state) {
    return dealRound(state.copyWith(roundNumber: state.roundNumber + 1));
  }
}
