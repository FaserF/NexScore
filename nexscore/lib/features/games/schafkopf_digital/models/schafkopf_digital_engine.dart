import 'dart:math';
import 'bavarian_card_models.dart';
import 'schafkopf_digital_state.dart';

/// Core game logic engine for digital Schafkopf.
/// Handles dealing, game type selection, trick evaluation, and scoring
/// for Sauspiel, Solo, and Wenz game types.
class SchafkopfDigitalEngine {
  final Random _random = Random();

  /// Initialize a new game with 4 players.
  SchafkopfDigitalState initializeGame(List<String> playerIds) {
    assert(playerIds.length == 4, 'Schafkopf requires exactly 4 players');
    return SchafkopfDigitalState(
      playerOrder: playerIds,
      currentDealerId: playerIds.first,
      totalScores: {for (final p in playerIds) p: 0},
      roundNumber: 1,
      phase: SchafkopfDigitalPhase.gameSelect,
    );
  }

  /// Deal 8 cards to each player and start game selection.
  SchafkopfDigitalState dealRound(SchafkopfDigitalState state) {
    final deck = BavarianDeckGenerator.generateFullDeck()..shuffle(_random);
    final hands = <String, List<BavarianCard>>{};
    for (int i = 0; i < 4; i++) {
      hands[state.playerOrder[i]] = deck.sublist(i * 8, (i + 1) * 8);
    }

    // First player after dealer starts game selection
    final dealerIdx = state.playerOrder.indexOf(state.currentDealerId!);
    final firstPlayerIdx = (dealerIdx + 1) % 4;

    return state.copyWith(
      hands: hands,
      phase: SchafkopfDigitalPhase.gameSelect,
      currentPlayerId: state.playerOrder[firstPlayerIdx],
      currentTrick: const SchafkopfTrick(),
      completedTricks: [],
      tricksWon: {for (final p in state.playerOrder) p: 0},
      pointsWon: {for (final p in state.playerOrder) p: 0},
    );
  }

  /// Player selects a game type. Returns updated state.
  /// If gameType is null, player passes.
  SchafkopfDigitalState selectGame(
    SchafkopfDigitalState state,
    String playerId,
    SchafkopfDigitalGameType? gameType, {
    BavarianSuit? calledSuit,
  }) {
    if (gameType != null) {
      // Player wants to play
      String? partnerId;

      // In Sauspiel, find the partner who holds the called Ace
      if (gameType == SchafkopfDigitalGameType.sauspiel && calledSuit != null) {
        for (final pid in state.playerOrder) {
          if (pid == playerId) continue;
          final hand = state.hands[pid] ?? [];
          if (hand.any(
            (c) => c.suit == calledSuit && c.rank == BavarianRank.ass,
          )) {
            partnerId = pid;
            break;
          }
        }
      }

      // Start playing — leader is player after dealer
      final dealerIdx = state.playerOrder.indexOf(state.currentDealerId!);
      final leaderIdx = (dealerIdx + 1) % 4;

      return state.copyWith(
        gameType: gameType,
        activePlayerId: playerId,
        partnerPlayerId: partnerId,
        calledSuit: calledSuit,
        phase: SchafkopfDigitalPhase.playing,
        currentPlayerId: state.playerOrder[leaderIdx],
        currentTrick: SchafkopfTrick(playOrder: state.playerOrder),
      );
    }

    // Player passes — move to next player
    final currentIdx = state.playerOrder.indexOf(playerId);
    final nextIdx = (currentIdx + 1) % 4;

    // If we've gone all the way around (back to first player after dealer),
    // nobody wants to play — re-deal
    final dealerIdx = state.playerOrder.indexOf(state.currentDealerId!);
    final firstPlayerIdx = (dealerIdx + 1) % 4;
    if (state.playerOrder[nextIdx] == state.playerOrder[firstPlayerIdx]) {
      // Nobody played — advance dealer and re-deal
      final nextDealerIdx = (dealerIdx + 1) % 4;
      return dealRound(
        state.copyWith(currentDealerId: state.playerOrder[nextDealerIdx]),
      );
    }

    return state.copyWith(currentPlayerId: state.playerOrder[nextIdx]);
  }

  /// Check if a card is a valid play.
  bool isValidPlay(
    SchafkopfDigitalState state,
    String playerId,
    BavarianCard card,
  ) {
    final hand = state.hands[playerId] ?? [];
    if (!hand.any((c) => c.id == card.id)) return false;

    // If first card in trick, anything goes
    if (state.currentTrick.playedCards.isEmpty) return true;

    // Determine lead card's effective suit
    final leadCard =
        state.currentTrick.playedCards[state.currentTrick.playOrder.firstWhere(
          (pid) => state.currentTrick.playedCards.containsKey(pid),
        )];
    if (leadCard == null) return true;

    final leadIsTrump = _isTrump(leadCard, state.gameType!);
    final cardIsTrump = _isTrump(card, state.gameType!);

    if (leadIsTrump) {
      // Trump was led — must play trump if you have it
      final hasTrump = hand.any((c) => _isTrump(c, state.gameType!));
      if (hasTrump) return cardIsTrump;
      return true; // No trump, play anything
    } else {
      // Non-trump suit was led — must follow suit
      final leadSuit = _effectiveSuit(leadCard, state.gameType!);
      final hasLeadSuit = hand.any(
        (c) =>
            !_isTrump(c, state.gameType!) &&
            _effectiveSuit(c, state.gameType!) == leadSuit,
      );
      if (hasLeadSuit) {
        return !cardIsTrump &&
            _effectiveSuit(card, state.gameType!) == leadSuit;
      }
      return true; // No cards of lead suit, play anything
    }
  }

  /// Play a card into the current trick.
  SchafkopfDigitalState playCard(
    SchafkopfDigitalState state,
    String playerId,
    BavarianCard card,
  ) {
    // Remove card from hand
    final updatedHands = Map<String, List<BavarianCard>>.from(
      state.hands.map((k, v) => MapEntry(k, List<BavarianCard>.from(v))),
    );
    updatedHands[playerId]!.removeWhere((c) => c.id == card.id);

    // Add card to trick
    final updatedTrick = state.currentTrick.addCard(playerId, card);

    // Check if trick is complete (4 cards played)
    if (updatedTrick.playedCards.length == 4) {
      final winnerId = evaluateTrickWinner(updatedTrick, state.gameType!);
      final updatedTricksWon = Map<String, int>.from(state.tricksWon);
      updatedTricksWon[winnerId] = (updatedTricksWon[winnerId] ?? 0) + 1;

      // Calculate points in this trick
      final trickPoints = updatedTrick.playedCards.values.fold<int>(
        0,
        (sum, card) => sum + card.points,
      );
      final updatedPointsWon = Map<String, int>.from(state.pointsWon);
      updatedPointsWon[winnerId] =
          (updatedPointsWon[winnerId] ?? 0) + trickPoints;

      // Check if all 8 tricks are played
      if (state.completedTricks.length + 1 == 8) {
        return _scoreRound(
          state.copyWith(
            hands: updatedHands,
            currentTrick: updatedTrick,
            completedTricks: [...state.completedTricks, updatedTrick],
            tricksWon: updatedTricksWon,
            pointsWon: updatedPointsWon,
          ),
        );
      }

      // Start next trick, winner leads
      return state.copyWith(
        hands: updatedHands,
        currentTrick: SchafkopfTrick(playOrder: state.playerOrder),
        completedTricks: [...state.completedTricks, updatedTrick],
        tricksWon: updatedTricksWon,
        pointsWon: updatedPointsWon,
        currentPlayerId: winnerId,
      );
    }

    // Next player's turn
    final currentIdx = state.playerOrder.indexOf(playerId);
    final nextIdx = (currentIdx + 1) % 4;

    return state.copyWith(
      hands: updatedHands,
      currentTrick: updatedTrick,
      currentPlayerId: state.playerOrder[nextIdx],
    );
  }

  /// Evaluate who wins a trick based on trump hierarchy and suits.
  String evaluateTrickWinner(
    SchafkopfTrick trick,
    SchafkopfDigitalGameType gameType,
  ) {
    String? winnerId;
    BavarianCard? winnerCard;

    for (final pid in trick.playOrder) {
      final card = trick.playedCards[pid];
      if (card == null) continue;

      if (winnerId == null) {
        winnerId = pid;
        winnerCard = card;
        continue;
      }

      if (_beats(card, winnerCard!, gameType)) {
        winnerId = pid;
        winnerCard = card;
      }
    }

    return winnerId ?? trick.playOrder.first;
  }

  /// Returns true if [challenger] beats [current] winner card.
  bool _beats(
    BavarianCard challenger,
    BavarianCard current,
    SchafkopfDigitalGameType gameType,
  ) {
    final challengerIsTrump = _isTrump(challenger, gameType);
    final currentIsTrump = _isTrump(current, gameType);

    if (challengerIsTrump && !currentIsTrump) return true;
    if (!challengerIsTrump && currentIsTrump) return false;

    if (challengerIsTrump && currentIsTrump) {
      return _trumpRank(challenger, gameType) > _trumpRank(current, gameType);
    }

    // Both non-trump: challenger only wins if same suit with higher rank
    if (challenger.suit == current.suit) {
      return _nonTrumpRank(challenger) > _nonTrumpRank(current);
    }

    return false; // Different suit, neither trump → first played wins
  }

  /// Check if a card is a trump card for the given game type.
  bool _isTrump(BavarianCard card, SchafkopfDigitalGameType gameType) {
    switch (gameType) {
      case SchafkopfDigitalGameType.wenz:
        // In Wenz, only Unters are trump
        return card.rank == BavarianRank.unter;

      case SchafkopfDigitalGameType.sauspiel:
        // In Sauspiel: all Obers, all Unters, and all Herz cards are trump
        if (card.rank == BavarianRank.ober) return true;
        if (card.rank == BavarianRank.unter) return true;
        if (card.suit == BavarianSuit.herz) return true;
        return false;

      case SchafkopfDigitalGameType.soloHerz:
        if (card.rank == BavarianRank.ober) return true;
        if (card.rank == BavarianRank.unter) return true;
        if (card.suit == BavarianSuit.herz) return true;
        return false;
      case SchafkopfDigitalGameType.soloEichel:
        if (card.rank == BavarianRank.ober) return true;
        if (card.rank == BavarianRank.unter) return true;
        if (card.suit == BavarianSuit.eichel) return true;
        return false;
      case SchafkopfDigitalGameType.soloGras:
        if (card.rank == BavarianRank.ober) return true;
        if (card.rank == BavarianRank.unter) return true;
        if (card.suit == BavarianSuit.gras) return true;
        return false;
      case SchafkopfDigitalGameType.soloSchellen:
        if (card.rank == BavarianRank.ober) return true;
        if (card.rank == BavarianRank.unter) return true;
        if (card.suit == BavarianSuit.schellen) return true;
        return false;
    }
  }

  /// Effective suit of a card (for follow-suit rules). Trumps don't count as their regular suit.
  BavarianSuit _effectiveSuit(
    BavarianCard card,
    SchafkopfDigitalGameType gameType,
  ) {
    // If the card is a trump, it has no "suit" for follow-suit purposes
    // This method should only be called for non-trump cards
    return card.suit;
  }

  /// Trump rank ordering. Higher = stronger.
  int _trumpRank(BavarianCard card, SchafkopfDigitalGameType gameType) {
    if (gameType == SchafkopfDigitalGameType.wenz) {
      // Wenz: only Unters, ordered by suit: Eichel > Gras > Herz > Schellen
      if (card.rank == BavarianRank.unter) {
        return switch (card.suit) {
          BavarianSuit.eichel => 4,
          BavarianSuit.gras => 3,
          BavarianSuit.herz => 2,
          BavarianSuit.schellen => 1,
        };
      }
      return 0;
    }

    // Solo / Sauspiel: Obers > Unters > trump suit cards
    if (card.rank == BavarianRank.ober) {
      return 100 +
          switch (card.suit) {
            BavarianSuit.eichel => 4,
            BavarianSuit.gras => 3,
            BavarianSuit.herz => 2,
            BavarianSuit.schellen => 1,
          };
    }

    if (card.rank == BavarianRank.unter) {
      return 50 +
          switch (card.suit) {
            BavarianSuit.eichel => 4,
            BavarianSuit.gras => 3,
            BavarianSuit.herz => 2,
            BavarianSuit.schellen => 1,
          };
    }

    // Trump suit cards: Ass > 10 > König > 9 > 8 > 7
    return _nonTrumpRank(card);
  }

  /// Non-trump rank ordering. Higher = stronger.
  /// Ass(11) > 10 > König(4) > Ober(3, but only when not trump) > Unter(2, but in non-trump context) > 9 > 8 > 7
  int _nonTrumpRank(BavarianCard card) {
    return switch (card.rank) {
      BavarianRank.ass => 8,
      BavarianRank.zehn => 7,
      BavarianRank.koenig => 6,
      BavarianRank.ober => 5,
      BavarianRank.unter => 4,
      BavarianRank.neun => 3,
      BavarianRank.acht => 2,
      BavarianRank.sieben => 1,
    };
  }

  /// Score a completed round.
  /// In Schafkopf, the active player (+ partner in Sauspiel) needs ≥61 points to win.
  SchafkopfDigitalState _scoreRound(SchafkopfDigitalState state) {
    final activePoints =
        (state.pointsWon[state.activePlayerId] ?? 0) +
        (state.partnerPlayerId != null
            ? (state.pointsWon[state.partnerPlayerId] ?? 0)
            : 0);

    final activeWon = activePoints >= 61;
    final schneider = activeWon ? activePoints > 90 : activePoints < 31;
    final schwarz = activeWon
        ? (state.tricksWon[state.activePlayerId]! +
                  (state.partnerPlayerId != null
                      ? state.tricksWon[state.partnerPlayerId]!
                      : 0)) ==
              8
        : (state.tricksWon[state.activePlayerId]! +
                  (state.partnerPlayerId != null
                      ? state.tricksWon[state.partnerPlayerId]!
                      : 0)) ==
              0;

    // Base value: 10 cents for Sauspiel, 50 for Solo, 50 for Wenz
    int baseValue;
    switch (state.gameType!) {
      case SchafkopfDigitalGameType.sauspiel:
        baseValue = 10;
        break;
      case SchafkopfDigitalGameType.wenz:
        baseValue = 50;
        break;
      default: // Solo
        baseValue = 50;
        break;
    }

    // Add schneider/schwarz bonuses
    int totalValue = baseValue;
    if (schneider) totalValue += 10;
    if (schwarz) totalValue += 10;

    final updatedScores = Map<String, int>.from(state.totalScores);
    for (final pid in state.playerOrder) {
      final isActive =
          pid == state.activePlayerId || pid == state.partnerPlayerId;
      if (state.gameType == SchafkopfDigitalGameType.sauspiel) {
        // Sauspiel: 2v2 — active team wins/loses the base value
        if (isActive) {
          updatedScores[pid] =
              (updatedScores[pid] ?? 0) +
              (activeWon ? totalValue : -totalValue);
        } else {
          updatedScores[pid] =
              (updatedScores[pid] ?? 0) +
              (activeWon ? -totalValue : totalValue);
        }
      } else {
        // Solo/Wenz: 1v3 — active player wins/loses 3× the value
        if (pid == state.activePlayerId) {
          updatedScores[pid] =
              (updatedScores[pid] ?? 0) +
              (activeWon ? totalValue * 3 : -totalValue * 3);
        } else {
          updatedScores[pid] =
              (updatedScores[pid] ?? 0) +
              (activeWon ? -totalValue : totalValue);
        }
      }
    }

    return state.copyWith(
      totalScores: updatedScores,
      phase: SchafkopfDigitalPhase.scoring,
    );
  }

  /// Advance to the next round.
  SchafkopfDigitalState startNextRound(SchafkopfDigitalState state) {
    final dealerIdx = state.playerOrder.indexOf(state.currentDealerId!);
    final nextDealerIdx = (dealerIdx + 1) % 4;

    final nextState = state.copyWith(
      roundNumber: state.roundNumber + 1,
      currentDealerId: state.playerOrder[nextDealerIdx],
      gameType: null,
      activePlayerId: null,
      partnerPlayerId: null,
      calledSuit: null,
    );

    return dealRound(nextState);
  }

  /// Start the game (deal first round).
  SchafkopfDigitalState startGame(SchafkopfDigitalState state) {
    return dealRound(state);
  }
}
