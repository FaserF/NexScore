import 'dart:math';
import '../models/card_models.dart';
import '../models/wizard_digital_state.dart';

/// Core game logic engine for the digital Wizard-like trick-taking game.
/// Handles deck shuffling, dealing, trick evaluation, scoring, and valid move checks.
class WizardEngine {
  final Random _random = Random();

  /// Shuffles the full deck and deals [cardsPerPlayer] to each player.
  /// Returns the updated state with hands, trump card, and trump suit set.
  WizardDigitalState dealRound(WizardDigitalState state) {
    final deck = DeckGenerator.generateFullDeck()..shuffle(_random);
    final numPlayers = state.playerOrder.length;
    final cardsPerPlayer = state.currentRound;

    final hands = <String, List<GameCard>>{};
    int cardIndex = 0;
    for (final playerId in state.playerOrder) {
      hands[playerId] = deck.sublist(cardIndex, cardIndex + cardsPerPlayer);
      cardIndex += cardsPerPlayer;
    }

    // Reveal trump card (next card after dealing)
    GameCard? trumpCard;
    CardSuit? trumpSuit;
    if (cardIndex < deck.length) {
      trumpCard = deck[cardIndex];
      if (trumpCard.type == CardType.normal) {
        trumpSuit = trumpCard.suit;
      } else if (trumpCard.type == CardType.wizard) {
        // Wizard as trump: the dealer chooses the trump suit.
        // For simplicity in the engine, we default to flame — the UI will override.
        trumpSuit = CardSuit.flame;
      }
      // Jester as trump: no trump this round (trumpSuit stays null)
    }

    // Determine first bidder: player after dealer
    final dealerIndex = state.playerOrder.indexOf(state.currentDealerId!);
    final firstBidderIndex = (dealerIndex + 1) % numPlayers;

    return state.copyWith(
      hands: hands,
      trumpCard: trumpCard,
      trumpSuit: trumpSuit,
      bids: {},
      tricksWon: {for (final p in state.playerOrder) p: 0},
      currentTrick: const Trick(),
      completedTricks: [],
      currentPlayerId: state.playerOrder[firstBidderIndex],
      phase: WizardPhase.bidding,
    );
  }

  /// Place a bid for the current player.
  WizardDigitalState placeBid(
    WizardDigitalState state,
    String playerId,
    int bid,
  ) {
    final updatedBids = {...state.bids, playerId: bid};
    final allBidsPlaced = updatedBids.length == state.playerOrder.length;

    // Next bidder
    final currentIndex = state.playerOrder.indexOf(playerId);
    final nextIndex = (currentIndex + 1) % state.playerOrder.length;

    if (allBidsPlaced) {
      // Move to playing phase; first player after dealer leads
      final dealerIndex = state.playerOrder.indexOf(state.currentDealerId!);
      final leaderIndex = (dealerIndex + 1) % state.playerOrder.length;
      return state.copyWith(
        bids: updatedBids,
        phase: WizardPhase.playing,
        currentPlayerId: state.playerOrder[leaderIndex],
        currentTrick: Trick(playOrder: state.playerOrder),
      );
    }

    return state.copyWith(
      bids: updatedBids,
      currentPlayerId: state.playerOrder[nextIndex],
    );
  }

  /// Check if a card is a valid play from the player's hand.
  bool isValidPlay(WizardDigitalState state, String playerId, GameCard card) {
    final hand = state.hands[playerId] ?? [];
    if (!hand.any((c) => c.id == card.id)) return false;

    // Wizards and Jesters can always be played
    if (card.type == CardType.wizard || card.type == CardType.jester) {
      return true;
    }

    // If this is the first card in the trick, anything goes
    if (state.currentTrick.playedCards.isEmpty) return true;

    // Must follow suit of the lead card (first non-Jester, non-Wizard card)
    CardSuit? leadSuit;
    for (final pid in state.currentTrick.playOrder) {
      final played = state.currentTrick.playedCards[pid];
      if (played != null && played.type == CardType.normal) {
        leadSuit = played.suit;
        break;
      }
    }

    // If no lead suit established (all Wizards/Jesters so far), anything goes
    if (leadSuit == null) return true;

    // If the player has a card of the lead suit, they must follow
    final hasLeadSuit = hand.any(
      (c) => c.type == CardType.normal && c.suit == leadSuit,
    );
    if (hasLeadSuit && card.suit != leadSuit) return false;

    return true;
  }

  /// Play a card into the current trick.
  WizardDigitalState playCard(
    WizardDigitalState state,
    String playerId,
    GameCard card,
  ) {
    // Remove card from hand
    final updatedHands = Map<String, List<GameCard>>.from(
      state.hands.map((k, v) => MapEntry(k, List<GameCard>.from(v))),
    );
    updatedHands[playerId]!.removeWhere((c) => c.id == card.id);

    // Add card to trick
    final updatedTrick = state.currentTrick.addCard(playerId, card);

    // Check if trick is complete
    final allPlayed =
        updatedTrick.playedCards.length == state.playerOrder.length;

    if (allPlayed) {
      // Evaluate the trick winner
      final winnerId = evaluateTrickWinner(updatedTrick, state.trumpSuit);
      final updatedTricksWon = Map<String, int>.from(state.tricksWon);
      updatedTricksWon[winnerId] = (updatedTricksWon[winnerId] ?? 0) + 1;

      final allTricksPlayed =
          state.completedTricks.length + 1 == state.currentRound;

      if (allTricksPlayed) {
        // Round is over — score it
        return _scoreRound(
          state.copyWith(
            hands: updatedHands,
            currentTrick: updatedTrick,
            completedTricks: [...state.completedTricks, updatedTrick],
            tricksWon: updatedTricksWon,
          ),
        );
      }

      // Start next trick, winner leads
      return state.copyWith(
        hands: updatedHands,
        currentTrick: Trick(playOrder: state.playerOrder),
        completedTricks: [...state.completedTricks, updatedTrick],
        tricksWon: updatedTricksWon,
        currentPlayerId: winnerId,
      );
    }

    // Next player's turn
    final currentIndex = state.playerOrder.indexOf(playerId);
    final nextIndex = (currentIndex + 1) % state.playerOrder.length;

    return state.copyWith(
      hands: updatedHands,
      currentTrick: updatedTrick,
      currentPlayerId: state.playerOrder[nextIndex],
    );
  }

  /// Evaluate who wins the trick based on Wizard rules.
  String evaluateTrickWinner(Trick trick, CardSuit? trumpSuit) {
    String? winnerId;
    CardSuit? leadSuit;

    for (final pid in trick.playOrder) {
      final card = trick.playedCards[pid];
      if (card == null) continue;

      // First Wizard played always wins
      if (card.type == CardType.wizard) {
        // Wizard overrides any non-wizard winner; first wizard keeps priority
        final currentWinnerCard = winnerId != null
            ? trick.playedCards[winnerId]
            : null;
        if (currentWinnerCard == null ||
            currentWinnerCard.type != CardType.wizard) {
          winnerId = pid;
        }
        continue;
      }

      // Jesters never win
      if (card.type == CardType.jester) continue;

      // Establish lead suit from first normal card
      leadSuit ??= card.suit;

      if (winnerId == null) {
        winnerId = pid;
        continue;
      }

      // Check if current winner has a wizard — if so, skip
      final winnerCard = trick.playedCards[winnerId]!;
      if (winnerCard.type == CardType.wizard) continue;

      // Compare cards
      if (_beats(card, winnerCard, leadSuit, trumpSuit)) {
        winnerId = pid;
      }
    }

    // Fallback: if all jesters, first player "wins"
    return winnerId ?? trick.playOrder.first;
  }

  /// Returns true if [challenger] beats [current] winner card.
  bool _beats(
    GameCard challenger,
    GameCard current,
    CardSuit? leadSuit,
    CardSuit? trumpSuit,
  ) {
    // Trump beats non-trump
    if (trumpSuit != null) {
      final challengerIsTrump = challenger.suit == trumpSuit;
      final currentIsTrump = current.suit == trumpSuit;

      if (challengerIsTrump && !currentIsTrump) return true;
      if (!challengerIsTrump && currentIsTrump) return false;
      if (challengerIsTrump && currentIsTrump) {
        return challenger.value! > current.value!;
      }
    }

    // Same suit: higher value wins
    if (challenger.suit == current.suit) {
      return challenger.value! > current.value!;
    }

    // Different suit, not trump: lead suit wins
    if (leadSuit != null &&
        challenger.suit == leadSuit &&
        current.suit != leadSuit) {
      return true;
    }

    return false;
  }

  /// Score the round using standard Wizard scoring:
  /// Correct bid: 20 + 10 per trick won
  /// Incorrect bid: -10 per trick off
  WizardDigitalState _scoreRound(WizardDigitalState state) {
    final updatedScores = Map<String, int>.from(state.totalScores);

    for (final playerId in state.playerOrder) {
      final bid = state.bids[playerId] ?? 0;
      final won = state.tricksWon[playerId] ?? 0;

      if (bid == won) {
        updatedScores[playerId] =
            (updatedScores[playerId] ?? 0) + 20 + (10 * won);
      } else {
        updatedScores[playerId] =
            (updatedScores[playerId] ?? 0) - (10 * (bid - won).abs());
      }
    }

    final isLastRound = state.currentRound >= state.totalRounds;

    return state.copyWith(
      totalScores: updatedScores,
      phase: isLastRound ? WizardPhase.finished : WizardPhase.scoring,
    );
  }

  /// Advance to the next round after scoring.
  WizardDigitalState startNextRound(WizardDigitalState state) {
    final nextRound = state.currentRound + 1;
    final dealerIndex = state.playerOrder.indexOf(state.currentDealerId!);
    final nextDealerIndex = (dealerIndex + 1) % state.playerOrder.length;

    final nextState = state.copyWith(
      currentRound: nextRound,
      currentDealerId: state.playerOrder[nextDealerIndex],
    );

    return dealRound(nextState);
  }

  /// Initialize a brand new game.
  WizardDigitalState initializeGame(List<String> playerIds) {
    final totalRounds = 60 ~/ playerIds.length;

    final state = WizardDigitalState(
      currentRound: 1,
      totalRounds: totalRounds,
      playerOrder: playerIds,
      currentDealerId: playerIds.first,
      totalScores: {for (final p in playerIds) p: 0},
    );

    return dealRound(state);
  }
}
