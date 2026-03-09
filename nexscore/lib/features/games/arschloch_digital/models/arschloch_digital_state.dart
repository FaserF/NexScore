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

  Map<String, dynamic> toMap() {
    return {
      'hand': hand.map((e) => e.toMap()).toList(),
      'currentRank': currentRank?.name,
      'finishOrder': finishOrder,
      'totalPoints': totalPoints,
    };
  }

  factory ArschlochDigitalPlayerState.fromMap(Map<String, dynamic> map) {
    return ArschlochDigitalPlayerState(
      hand: (map['hand'] as List? ?? [])
          .map((e) => StandardCard.fromMap(e as Map<String, dynamic>))
          .toList(),
      currentRank: map['currentRank'] != null
          ? ArschlochRank.values.firstWhere((e) => e.name == map['currentRank'])
          : null,
      finishOrder: map['finishOrder'] ?? 0,
      totalPoints: map['totalPoints'] ?? 0,
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
  final bool canUndo;
  final DateTime? startedAt;
  final DateTime? endedAt;

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
    this.canUndo = false,
    this.startedAt,
    this.endedAt,
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
    bool? canUndo,
    DateTime? startedAt,
    DateTime? endedAt,
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
      canUndo: canUndo ?? this.canUndo,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phase': phase.name,
      'playerOrder': playerOrder,
      'playerStates': playerStates.map((k, v) => MapEntry(k, v.toMap())),
      'currentPile': currentPile.map((e) => e.toMap()).toList(),
      'currentPileRank': currentPileRank,
      'currentPileCount': currentPileCount,
      'currentPlayerId': currentPlayerId,
      'consecutivePasses': consecutivePasses,
      'roundNumber': roundNumber,
      'finishedCount': finishedCount,
      'finishOrder': finishOrder,
      'canUndo': canUndo,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory ArschlochDigitalState.fromMap(Map<String, dynamic> map) {
    return ArschlochDigitalState(
      phase: ArschlochDigitalPhase.values.firstWhere(
        (e) => e.name == map['phase'],
        orElse: () => ArschlochDigitalPhase.setup,
      ),
      playerOrder: List<String>.from(map['playerOrder'] ?? []),
      playerStates: (map['playerStates'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          ArschlochDigitalPlayerState.fromMap(v as Map<String, dynamic>),
        ),
      ),
      currentPile: (map['currentPile'] as List? ?? [])
          .map((e) => StandardCard.fromMap(e as Map<String, dynamic>))
          .toList(),
      currentPileRank: map['currentPileRank'] ?? 0,
      currentPileCount: map['currentPileCount'] ?? 0,
      currentPlayerId: map['currentPlayerId'],
      consecutivePasses: map['consecutivePasses'] ?? 0,
      roundNumber: map['roundNumber'] ?? 0,
      finishedCount: map['finishedCount'] ?? 0,
      finishOrder: List<String>.from(map['finishOrder'] ?? []),
      canUndo: map['canUndo'] ?? false,
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'] as String)
          : null,
      endedAt: map['endedAt'] != null
          ? DateTime.parse(map['endedAt'] as String)
          : null,
    );
  }
}
