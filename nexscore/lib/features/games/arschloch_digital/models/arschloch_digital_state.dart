import 'standard_card_models.dart';

/// Phase of the digital Arschloch game.
enum ArschlochDigitalPhase {
  setup, // Waiting to start
  playing, // Active trick round
  roundEnd, // Round finished, show rankings
  cardSwap, // Arschloch/Präsident card exchange
  finished, // Game over
}

/// Player rank titles in Arschloch.
enum ArschlochRank {
  praesident, // Best player
  vizePraesident, // 2nd best
  neutral, // Middle players
  vizeArschloch, // 2nd worst
  arschloch, // Worst player
}

/// State for a single player in the digital game.
class ArschlochDigitalPlayerState {
  final List<StandardCard> hand;
  final ArschlochRank? currentRank;
  final int finishOrder; // 0 = not finished yet, 1 = first out, etc.
  final int totalPoints;

  const ArschlochDigitalPlayerState({
    this.hand = const [],
    this.currentRank,
    this.finishOrder = 0,
    this.totalPoints = 0,
  });

  ArschlochDigitalPlayerState copyWith({
    List<StandardCard>? hand,
    ArschlochRank? currentRank,
    int? finishOrder,
    int? totalPoints,
  }) {
    return ArschlochDigitalPlayerState(
      hand: hand ?? this.hand,
      currentRank: currentRank ?? this.currentRank,
      finishOrder: finishOrder ?? this.finishOrder,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }
}

/// Full state of the digital Arschloch game.
class ArschlochDigitalState {
  final ArschlochDigitalPhase phase;
  final List<String> playerOrder;
  final Map<String, ArschlochDigitalPlayerState> playerStates;
  final List<StandardCard> currentPile; // Cards on the table
  final int currentPileRank; // Numeric rank of the top card(s)
  final int currentPileCount; // How many cards were last played (1, 2, 3, 4)
  final String? currentPlayerId;
  final int consecutivePasses;
  final int roundNumber;
  final int finishedCount; // How many players have gone out
  final List<String> finishOrder; // Order in which players finished

  const ArschlochDigitalState({
    this.phase = ArschlochDigitalPhase.setup,
    this.playerOrder = const [],
    this.playerStates = const {},
    this.currentPile = const [],
    this.currentPileRank = 0,
    this.currentPileCount = 0,
    this.currentPlayerId,
    this.consecutivePasses = 0,
    this.roundNumber = 0,
    this.finishedCount = 0,
    this.finishOrder = const [],
  });

  ArschlochDigitalState copyWith({
    ArschlochDigitalPhase? phase,
    List<String>? playerOrder,
    Map<String, ArschlochDigitalPlayerState>? playerStates,
    List<StandardCard>? currentPile,
    int? currentPileRank,
    int? currentPileCount,
    String? currentPlayerId,
    int? consecutivePasses,
    int? roundNumber,
    int? finishedCount,
    List<String>? finishOrder,
  }) {
    return ArschlochDigitalState(
      phase: phase ?? this.phase,
      playerOrder: playerOrder ?? this.playerOrder,
      playerStates: playerStates ?? this.playerStates,
      currentPile: currentPile ?? this.currentPile,
      currentPileRank: currentPileRank ?? this.currentPileRank,
      currentPileCount: currentPileCount ?? this.currentPileCount,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      consecutivePasses: consecutivePasses ?? this.consecutivePasses,
      roundNumber: roundNumber ?? this.roundNumber,
      finishedCount: finishedCount ?? this.finishedCount,
      finishOrder: finishOrder ?? this.finishOrder,
    );
  }
}
