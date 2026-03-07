import 'dart:math';
import 'standard_card_models.dart';
import 'arschloch_digital_state.dart';

/// Core game engine for digital Arschloch (President).
/// Rules:
/// - Cards are dealt evenly. Players take turns playing cards.
/// - You must play equal or higher rank than the pile, or pass.
/// - Playing the same number of cards as the last play (singles, doubles, triples).
/// - When all pass, pile is cleared and last player who played leads.
/// - First player out = Präsident, last = Arschloch.
/// - After first round, Arschloch gives best cards to Präsident (card swap).
class ArschlochDigitalEngine {
  final Random _random = Random();

  /// Initialize a new game.
  ArschlochDigitalState initializeGame(List<String> playerIds) {
    return ArschlochDigitalState(
      playerOrder: playerIds,
      playerStates: {
        for (final p in playerIds) p: const ArschlochDigitalPlayerState(),
      },
      roundNumber: 1,
      phase: ArschlochDigitalPhase.playing,
    );
  }

  /// Deal cards evenly to all players.
  ArschlochDigitalState dealCards(ArschlochDigitalState state) {
    final deck = StandardDeckGenerator.generateFullDeck()..shuffle(_random);
    final playerCount = state.playerOrder.length;
    final cardsPerPlayer = deck.length ~/ playerCount;

    final newStates = <String, ArschlochDigitalPlayerState>{};
    for (int i = 0; i < playerCount; i++) {
      final hand = deck.sublist(i * cardsPerPlayer, (i + 1) * cardsPerPlayer);
      // Sort hand by rank
      hand.sort((a, b) => a.numericRank.compareTo(b.numericRank));
      newStates[state.playerOrder[i]] = state
          .playerStates[state.playerOrder[i]]!
          .copyWith(hand: hand, finishOrder: 0);
    }

    return state.copyWith(
      playerStates: newStates,
      phase: ArschlochDigitalPhase.playing,
      currentPlayerId: state.playerOrder.first,
      currentPile: [],
      currentPileRank: 0,
      currentPileCount: 0,
      consecutivePasses: 0,
      finishedCount: 0,
      finishOrder: [],
    );
  }

  /// Start the game.
  ArschlochDigitalState startGame(ArschlochDigitalState state) {
    return dealCards(state);
  }

  /// Get playable card groups for the current player.
  /// Returns groups of cards with same value that can be played.
  List<List<StandardCard>> getPlayableGroups(
    ArschlochDigitalState state,
    String playerId,
  ) {
    final hand = state.playerStates[playerId]?.hand ?? [];
    if (hand.isEmpty) return [];

    // Group cards by value
    final groups = <int, List<StandardCard>>{};
    for (final card in hand) {
      groups.putIfAbsent(card.numericRank, () => []).add(card);
    }

    final result = <List<StandardCard>>[];

    if (state.currentPileRank == 0) {
      // Leading: can play any group of 1, 2, 3, or 4 cards of same rank
      for (final group in groups.values) {
        for (int count = 1; count <= group.length; count++) {
          result.add(group.sublist(0, count));
        }
      }
    } else {
      // Must match count and beat rank
      final requiredCount = state.currentPileCount;
      for (final entry in groups.entries) {
        if (entry.key > state.currentPileRank &&
            entry.value.length >= requiredCount) {
          result.add(entry.value.sublist(0, requiredCount));
        }
      }
    }

    return result;
  }

  /// Play cards onto the pile.
  ArschlochDigitalState playCards(
    ArschlochDigitalState state,
    String playerId,
    List<StandardCard> cards,
  ) {
    if (cards.isEmpty) return state;

    // Remove cards from hand
    final newStates = Map<String, ArschlochDigitalPlayerState>.from(
      state.playerStates,
    );
    final hand = List<StandardCard>.from(newStates[playerId]!.hand);
    for (final card in cards) {
      hand.removeWhere((c) => c.id == card.id);
    }

    // Check if player has finished (hand empty)
    int newFinishedCount = state.finishedCount;
    final newFinishOrder = List<String>.from(state.finishOrder);
    int finishOrd = 0;

    if (hand.isEmpty) {
      newFinishedCount++;
      newFinishOrder.add(playerId);
      finishOrd = newFinishedCount;
    }

    newStates[playerId] = newStates[playerId]!.copyWith(
      hand: hand,
      finishOrder: finishOrd > 0 ? finishOrd : null,
    );

    // Check if round is over (only 1 or 0 players with cards left)
    final playersWithCards = state.playerOrder
        .where(
          (pid) =>
              newStates[pid]!.hand.isNotEmpty ||
              (pid == playerId && hand.isNotEmpty),
        )
        .toList();

    if (playersWithCards.length <= 1) {
      // Add the last remaining player to finish order
      if (playersWithCards.isNotEmpty &&
          !newFinishOrder.contains(playersWithCards.first)) {
        newFinishOrder.add(playersWithCards.first);
      }
      return _endRound(
        state.copyWith(
          playerStates: newStates,
          finishedCount: newFinishedCount,
          finishOrder: newFinishOrder,
        ),
      );
    }

    // Find next player who still has cards
    final nextPlayerId = _findNextActivePlayer(
      state.playerOrder,
      playerId,
      newStates,
    );

    return state.copyWith(
      playerStates: newStates,
      currentPile: cards,
      currentPileRank: cards.first.numericRank,
      currentPileCount: cards.length,
      currentPlayerId: nextPlayerId,
      consecutivePasses: 0,
      finishedCount: newFinishedCount,
      finishOrder: newFinishOrder,
    );
  }

  /// Player passes their turn.
  ArschlochDigitalState pass(ArschlochDigitalState state, String playerId) {
    final activeCount = state.playerOrder
        .where((pid) => state.playerStates[pid]!.hand.isNotEmpty)
        .length;
    final newPasses = state.consecutivePasses + 1;

    // If everyone has passed (all active players minus 1), clear pile
    if (newPasses >= activeCount - 1) {
      // Find the last player who actually played
      final nextPlayerId = _findNextActivePlayer(
        state.playerOrder,
        playerId,
        state.playerStates,
      );
      return state.copyWith(
        currentPile: [],
        currentPileRank: 0,
        currentPileCount: 0,
        currentPlayerId: nextPlayerId,
        consecutivePasses: 0,
      );
    }

    final nextPlayerId = _findNextActivePlayer(
      state.playerOrder,
      playerId,
      state.playerStates,
    );

    return state.copyWith(
      currentPlayerId: nextPlayerId,
      consecutivePasses: newPasses,
    );
  }

  /// Find the next player who still has cards in hand.
  String _findNextActivePlayer(
    List<String> playerOrder,
    String currentPlayerId,
    Map<String, ArschlochDigitalPlayerState> states,
  ) {
    final currentIdx = playerOrder.indexOf(currentPlayerId);
    for (int i = 1; i <= playerOrder.length; i++) {
      final nextIdx = (currentIdx + i) % playerOrder.length;
      final pid = playerOrder[nextIdx];
      if (states[pid]!.hand.isNotEmpty) return pid;
    }
    return currentPlayerId;
  }

  /// End the round, assign rankings.
  ArschlochDigitalState _endRound(ArschlochDigitalState state) {
    final rankings = state.finishOrder;
    final totalPlayers = state.playerOrder.length;

    final newStates = Map<String, ArschlochDigitalPlayerState>.from(
      state.playerStates,
    );
    for (int i = 0; i < rankings.length; i++) {
      final pid = rankings[i];
      ArschlochRank rank;
      if (i == 0) {
        rank = ArschlochRank.praesident;
      } else if (i == 1 && totalPlayers > 3) {
        rank = ArschlochRank.vizePraesident;
      } else if (i == rankings.length - 1) {
        rank = ArschlochRank.arschloch;
      } else if (i == rankings.length - 2 && totalPlayers > 3) {
        rank = ArschlochRank.vizeArschloch;
      } else {
        rank = ArschlochRank.neutral;
      }

      // Points: Präsident gets most points, Arschloch least
      final pts = totalPlayers - i;
      newStates[pid] = newStates[pid]!.copyWith(
        currentRank: rank,
        totalPoints: newStates[pid]!.totalPoints + pts,
      );
    }

    return state.copyWith(
      playerStates: newStates,
      phase: ArschlochDigitalPhase.roundEnd,
    );
  }

  /// Start next round (deals new cards).
  ArschlochDigitalState startNextRound(ArschlochDigitalState state) {
    final newState = state.copyWith(roundNumber: state.roundNumber + 1);
    return dealCards(newState);
  }
}
