import 'dart:math';

/// Phase of a digital Rommé game.
enum RommeDigitalPhase {
  setup,
  playing, // Active player's turn: draw, meld, lay off, discard
  finished,
}

/// A standard playing card for Rommé (2 decks of 52 + 2 jokers = 108 cards).
class RommeCard {
  final String id;
  final int suit; // 0-3 for ♣♠♥♦, 4 for joker
  final int rank; // 1(Ace)-13(King), 0 for joker

  const RommeCard({required this.id, required this.suit, required this.rank});

  bool get isJoker => suit == 4;

  int get points {
    if (isJoker) return 20;
    if (rank == 1) return 11; // Ace
    if (rank >= 10) return 10; // 10, J, Q, K
    return rank; // 2-9
  }

  String get shortLabel {
    if (isJoker) return '🃏';
    final suitChar = ['♣', '♠', '♥', '♦'][suit];
    final rankChar = [
      '',
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
    ][rank];
    return '$suitChar$rankChar';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RommeCard && id == other.id;
  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {'id': id, 'suit': suit, 'rank': rank};

  factory RommeCard.fromMap(Map<String, dynamic> map) =>
      RommeCard(id: map['id'], suit: map['suit'], rank: map['rank']);
}

/// A meld (Auslage) in Rommé — either a set (same rank) or a run (same suit sequence).
class RommeMeld {
  final List<RommeCard> cards;

  const RommeMeld({required this.cards});

  /// Check if this is a valid set (3-4 cards of same rank, different suits).
  bool get isValidSet {
    if (cards.length < 3 || cards.length > 4) return false;
    final nonJokers = cards.where((c) => !c.isJoker).toList();
    if (nonJokers.isEmpty) return false;
    final targetRank = nonJokers.first.rank;
    final suits = <int>{};
    for (final c in nonJokers) {
      if (c.rank != targetRank) return false;
      suits.add(c.suit);
    }
    return suits.length == nonJokers.length; // No duplicate suits
  }

  /// Check if this is a valid run (3+ cards of same suit in sequence).
  bool get isValidRun {
    if (cards.length < 3) return false;
    final nonJokers = cards.where((c) => !c.isJoker).toList();
    if (nonJokers.isEmpty) return false;
    final targetSuit = nonJokers.first.suit;
    if (nonJokers.any((c) => c.suit != targetSuit)) return false;

    // Sort by rank and check sequence
    final sorted = List<RommeCard>.from(cards)
      ..sort(
        (a, b) => a.isJoker ? 99 : a.rank.compareTo(b.isJoker ? 99 : b.rank),
      );

    int expectedRank = sorted.firstWhere((c) => !c.isJoker).rank;
    for (final card in sorted) {
      if (!card.isJoker) {
        if (card.rank != expectedRank) return false;
      }
      expectedRank++;
    }
    return true;
  }

  bool get isValid => isValidSet || isValidRun;

  int get totalPoints => cards.fold(0, (s, c) => s + c.points);

  Map<String, dynamic> toMap() => {
    'cards': cards.map((c) => c.toMap()).toList(),
  };

  factory RommeMeld.fromMap(Map<String, dynamic> map) => RommeMeld(
    cards: (map['cards'] as List? ?? [])
        .map((c) => RommeCard.fromMap(c as Map<String, dynamic>))
        .toList(),
  );
}

/// Player state.
class RommeDigitalPlayerState {
  final List<RommeCard> hand;
  final List<RommeMeld> melds;
  final bool hasDrawn;
  final int deadwoodPoints;

  const RommeDigitalPlayerState({
    this.hand = const [],
    this.melds = const [],
    this.hasDrawn = false,
    this.deadwoodPoints = 0,
  });

  RommeDigitalPlayerState copyWith({
    List<RommeCard>? hand,
    List<RommeMeld>? melds,
    bool? hasDrawn,
    int? deadwoodPoints,
  }) {
    return RommeDigitalPlayerState(
      hand: hand ?? this.hand,
      melds: melds ?? this.melds,
      hasDrawn: hasDrawn ?? this.hasDrawn,
      deadwoodPoints: deadwoodPoints ?? this.deadwoodPoints,
    );
  }

  Map<String, dynamic> toMap() => {
    'hand': hand.map((c) => c.toMap()).toList(),
    'melds': melds.map((m) => m.toMap()).toList(),
    'hasDrawn': hasDrawn,
    'deadwoodPoints': deadwoodPoints,
  };

  factory RommeDigitalPlayerState.fromMap(Map<String, dynamic> map) =>
      RommeDigitalPlayerState(
        hand: (map['hand'] as List? ?? [])
            .map((c) => RommeCard.fromMap(c as Map<String, dynamic>))
            .toList(),
        melds: (map['melds'] as List? ?? [])
            .map((m) => RommeMeld.fromMap(m as Map<String, dynamic>))
            .toList(),
        hasDrawn: map['hasDrawn'] ?? false,
        deadwoodPoints: map['deadwoodPoints'] ?? 0,
      );
}

/// Full game state.
class RommeDigitalState {
  final RommeDigitalPhase phase;
  final List<String> playerOrder;
  final Map<String, RommeDigitalPlayerState> playerStates;
  final List<RommeCard> drawPile;
  final List<RommeCard> discardPile;
  final String? currentPlayerId;
  final int currentPlayerIndex;
  final int roundNumber;
  final Map<String, int> totalScores;
  final bool canUndo;

  const RommeDigitalState({
    this.phase = RommeDigitalPhase.setup,
    this.playerOrder = const [],
    this.playerStates = const {},
    this.drawPile = const [],
    this.discardPile = const [],
    this.currentPlayerId,
    this.currentPlayerIndex = 0,
    this.roundNumber = 1,
    this.totalScores = const {},
    this.canUndo = false,
  });

  RommeDigitalState copyWith({
    RommeDigitalPhase? phase,
    List<String>? playerOrder,
    Map<String, RommeDigitalPlayerState>? playerStates,
    List<RommeCard>? drawPile,
    List<RommeCard>? discardPile,
    String? currentPlayerId,
    int? currentPlayerIndex,
    int? roundNumber,
    Map<String, int>? totalScores,
    bool? canUndo,
  }) {
    return RommeDigitalState(
      phase: phase ?? this.phase,
      playerOrder: playerOrder ?? this.playerOrder,
      playerStates: playerStates ?? this.playerStates,
      drawPile: drawPile ?? this.drawPile,
      discardPile: discardPile ?? this.discardPile,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      roundNumber: roundNumber ?? this.roundNumber,
      totalScores: totalScores ?? this.totalScores,
      canUndo: canUndo ?? this.canUndo,
    );
  }

  Map<String, dynamic> toMap() => {
    'phase': phase.name,
    'playerOrder': playerOrder,
    'playerStates': playerStates.map((k, v) => MapEntry(k, v.toMap())),
    'drawPile': drawPile.map((c) => c.toMap()).toList(),
    'discardPile': discardPile.map((c) => c.toMap()).toList(),
    'currentPlayerId': currentPlayerId,
    'currentPlayerIndex': currentPlayerIndex,
    'roundNumber': roundNumber,
    'totalScores': totalScores,
    'canUndo': canUndo,
  };

  factory RommeDigitalState.fromMap(Map<String, dynamic> map) =>
      RommeDigitalState(
        phase: RommeDigitalPhase.values.firstWhere(
          (e) => e.name == map['phase'],
          orElse: () => RommeDigitalPhase.setup,
        ),
        playerOrder: List<String>.from(map['playerOrder'] ?? []),
        playerStates: (map['playerStates'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            k,
            RommeDigitalPlayerState.fromMap(v as Map<String, dynamic>),
          ),
        ),
        drawPile: (map['drawPile'] as List? ?? [])
            .map((c) => RommeCard.fromMap(c as Map<String, dynamic>))
            .toList(),
        discardPile: (map['discardPile'] as List? ?? [])
            .map((c) => RommeCard.fromMap(c as Map<String, dynamic>))
            .toList(),
        currentPlayerId: map['currentPlayerId'],
        currentPlayerIndex: map['currentPlayerIndex'] ?? 0,
        roundNumber: map['roundNumber'] ?? 1,
        totalScores: Map<String, int>.from(map['totalScores'] ?? {}),
        canUndo: map['canUndo'] ?? false,
      );
}

/// Core Rommé engine.
class RommeDigitalEngine {
  final Random _random = Random();

  /// Generate a double deck (108 cards: 2×52 + 4 jokers).
  List<RommeCard> _generateDeck() {
    final cards = <RommeCard>[];
    for (int deck = 0; deck < 2; deck++) {
      for (int suit = 0; suit < 4; suit++) {
        for (int rank = 1; rank <= 13; rank++) {
          cards.add(
            RommeCard(id: 'd${deck}_s${suit}_r$rank', suit: suit, rank: rank),
          );
        }
      }
      cards.add(RommeCard(id: 'd${deck}_joker1', suit: 4, rank: 0));
      cards.add(RommeCard(id: 'd${deck}_joker2', suit: 4, rank: 0));
    }
    return cards;
  }

  RommeDigitalState initializeGame(List<String> playerIds) {
    return RommeDigitalState(
      playerOrder: playerIds,
      totalScores: {for (final p in playerIds) p: 0},
      roundNumber: 1,
    );
  }

  RommeDigitalState dealRound(RommeDigitalState state) {
    final deck = _generateDeck()..shuffle(_random);
    final cardsPerPlayer = state.playerOrder.length <= 3 ? 13 : 11;

    final newStates = <String, RommeDigitalPlayerState>{};
    int cardIndex = 0;
    for (final pid in state.playerOrder) {
      final hand = deck.sublist(cardIndex, cardIndex + cardsPerPlayer);
      hand.sort((a, b) {
        if (a.isJoker) return 1;
        if (b.isJoker) return -1;
        if (a.suit != b.suit) return a.suit.compareTo(b.suit);
        return a.rank.compareTo(b.rank);
      });
      newStates[pid] = RommeDigitalPlayerState(hand: hand);
      cardIndex += cardsPerPlayer;
    }

    return state.copyWith(
      playerStates: newStates,
      drawPile: deck.sublist(cardIndex + 1),
      discardPile: [deck[cardIndex]],
      currentPlayerId: state.playerOrder.first,
      currentPlayerIndex: 0,
      phase: RommeDigitalPhase.playing,
    );
  }

  RommeDigitalState startGame(RommeDigitalState state) {
    return dealRound(state);
  }

  /// Draw a card from the draw pile.
  RommeDigitalState drawFromPile(RommeDigitalState state, String playerId) {
    if (state.drawPile.isEmpty) return state;
    final pState = state.playerStates[playerId]!;
    if (pState.hasDrawn) return state;

    final card = state.drawPile.first;
    final newHand = [...pState.hand, card];
    final newStates = Map<String, RommeDigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(hand: newHand, hasDrawn: true);

    return state.copyWith(
      playerStates: newStates,
      drawPile: state.drawPile.sublist(1),
    );
  }

  /// Draw the top card from discard pile.
  RommeDigitalState drawFromDiscard(RommeDigitalState state, String playerId) {
    if (state.discardPile.isEmpty) return state;
    final pState = state.playerStates[playerId]!;
    if (pState.hasDrawn) return state;

    final card = state.discardPile.last;
    final newHand = [...pState.hand, card];
    final newStates = Map<String, RommeDigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(hand: newHand, hasDrawn: true);

    return state.copyWith(
      playerStates: newStates,
      discardPile: state.discardPile.sublist(0, state.discardPile.length - 1),
    );
  }

  /// Meld cards from hand.
  RommeDigitalState meldCards(
    RommeDigitalState state,
    String playerId,
    List<RommeCard> cards,
  ) {
    final meld = RommeMeld(cards: cards);
    if (!meld.isValid) return state;

    final pState = state.playerStates[playerId]!;
    final newHand = List<RommeCard>.from(pState.hand);
    for (final card in cards) {
      newHand.removeWhere((c) => c.id == card.id);
    }

    final newStates = Map<String, RommeDigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(
      hand: newHand,
      melds: [...pState.melds, meld],
    );

    return state.copyWith(playerStates: newStates);
  }

  /// Discard a card and end turn.
  RommeDigitalState discardCard(
    RommeDigitalState state,
    String playerId,
    RommeCard card,
  ) {
    final pState = state.playerStates[playerId]!;
    if (!pState.hasDrawn) return state;

    final newHand = List<RommeCard>.from(pState.hand);
    newHand.removeWhere((c) => c.id == card.id);

    final newStates = Map<String, RommeDigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(hand: newHand, hasDrawn: false);

    // Check if player has won
    if (newHand.isEmpty) {
      // Score: other players' hand points count against them
      final newScores = Map<String, int>.from(state.totalScores);
      for (final pid in state.playerOrder) {
        if (pid == playerId) continue;
        final deadwood = newStates[pid]!.hand.fold<int>(
          0,
          (s, c) => s + c.points,
        );
        newScores[pid] = (newScores[pid] ?? 0) + deadwood;
      }
      return state.copyWith(
        playerStates: newStates,
        discardPile: [...state.discardPile, card],
        totalScores: newScores,
        phase: RommeDigitalPhase.finished,
      );
    }

    // Advance to next player
    final nextIdx = (state.currentPlayerIndex + 1) % state.playerOrder.length;
    return state.copyWith(
      playerStates: newStates,
      discardPile: [...state.discardPile, card],
      currentPlayerIndex: nextIdx,
      currentPlayerId: state.playerOrder[nextIdx],
    );
  }

  /// Start next round.
  RommeDigitalState startNextRound(RommeDigitalState state) {
    return dealRound(state.copyWith(roundNumber: state.roundNumber + 1));
  }
}
