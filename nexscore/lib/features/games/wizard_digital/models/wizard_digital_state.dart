import 'card_models.dart';

/// Represents a single trick (one card played per player in order)
class Trick {
  final Map<String, GameCard> playedCards; // playerId -> card
  final List<String> playOrder; // order of play

  const Trick({this.playedCards = const {}, this.playOrder = const []});

  bool get isComplete =>
      playedCards.length == playOrder.length && playOrder.isNotEmpty;

  Trick addCard(String playerId, GameCard card) {
    return Trick(
      playedCards: {...playedCards, playerId: card},
      playOrder: playOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playedCards': playedCards.map((k, v) => MapEntry(k, v.toMap())),
      'playOrder': playOrder,
    };
  }

  factory Trick.fromMap(Map<String, dynamic> map) {
    final cards = (map['playedCards'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, GameCard.fromMap(v as Map<String, dynamic>)),
    );
    return Trick(
      playedCards: cards,
      playOrder: List<String>.from(map['playOrder'] ?? []),
    );
  }
}

/// Full state of the digital Wizard game
class WizardDigitalState {
  final int currentRound; // 1-indexed
  final int totalRounds;
  final List<String> playerOrder; // player IDs in seating order
  final String? currentDealerId; // who deals this round
  final String? currentPlayerId; // whose turn it is
  final GameCard? trumpCard; // the revealed trump card
  final CardSuit? trumpSuit; // the active trump suit

  final Map<String, List<GameCard>> hands; // playerId -> cards in hand
  final Map<String, int> bids; // playerId -> predicted tricks this round
  final Map<String, int> tricksWon; // playerId -> tricks won this round
  final Map<String, int> totalScores; // playerId -> cumulative score

  final Trick currentTrick;
  final List<Trick> completedTricks;

  final WizardPhase phase;
  final bool canUndo;
  final DateTime? startedAt;
  final DateTime? endedAt;

  const WizardDigitalState({
    this.currentRound = 1,
    this.totalRounds = 10,
    this.playerOrder = const [],
    this.currentDealerId,
    this.currentPlayerId,
    this.trumpCard,
    this.trumpSuit,
    this.hands = const {},
    this.bids = const {},
    this.tricksWon = const {},
    this.totalScores = const {},
    this.currentTrick = const Trick(),
    this.completedTricks = const [],
    this.phase = WizardPhase.setup,
    this.canUndo = false,
    this.startedAt,
    this.endedAt,
  });

  WizardDigitalState copyWith({
    int? currentRound,
    int? totalRounds,
    List<String>? playerOrder,
    String? currentDealerId,
    String? currentPlayerId,
    GameCard? trumpCard,
    CardSuit? trumpSuit,
    Map<String, List<GameCard>>? hands,
    Map<String, int>? bids,
    Map<String, int>? tricksWon,
    Map<String, int>? totalScores,
    Trick? currentTrick,
    List<Trick>? completedTricks,
    WizardPhase? phase,
    bool? canUndo,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return WizardDigitalState(
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds ?? this.totalRounds,
      playerOrder: playerOrder ?? this.playerOrder,
      currentDealerId: currentDealerId ?? this.currentDealerId,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      trumpCard: trumpCard ?? this.trumpCard,
      trumpSuit: trumpSuit ?? this.trumpSuit,
      hands: hands ?? this.hands,
      bids: bids ?? this.bids,
      tricksWon: tricksWon ?? this.tricksWon,
      totalScores: totalScores ?? this.totalScores,
      currentTrick: currentTrick ?? this.currentTrick,
      completedTricks: completedTricks ?? this.completedTricks,
      phase: phase ?? this.phase,
      canUndo: canUndo ?? this.canUndo,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currentRound': currentRound,
      'totalRounds': totalRounds,
      'playerOrder': playerOrder,
      'currentDealerId': currentDealerId,
      'currentPlayerId': currentPlayerId,
      'trumpCard': trumpCard?.toMap(),
      'trumpSuit': trumpSuit?.name,
      'hands': hands.map(
        (k, v) => MapEntry(k, v.map((c) => c.toMap()).toList()),
      ),
      'bids': bids,
      'tricksWon': tricksWon,
      'totalScores': totalScores,
      'currentTrick': currentTrick.toMap(),
      'completedTricks': completedTricks.map((t) => t.toMap()).toList(),
      'phase': phase.name,
      'canUndo': canUndo,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  factory WizardDigitalState.fromMap(Map<String, dynamic> map) {
    return WizardDigitalState(
      currentRound: map['currentRound'] ?? 1,
      totalRounds: map['totalRounds'] ?? 10,
      playerOrder: List<String>.from(map['playerOrder'] ?? []),
      currentDealerId: map['currentDealerId'],
      currentPlayerId: map['currentPlayerId'],
      trumpCard: map['trumpCard'] != null
          ? GameCard.fromMap(map['trumpCard'] as Map<String, dynamic>)
          : null,
      trumpSuit: map['trumpSuit'] != null
          ? CardSuit.values.firstWhere((e) => e.name == map['trumpSuit'])
          : null,
      hands: (map['hands'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((c) => GameCard.fromMap(c as Map<String, dynamic>))
              .toList(),
        ),
      ),
      bids: Map<String, int>.from(map['bids'] ?? {}),
      tricksWon: Map<String, int>.from(map['tricksWon'] ?? {}),
      totalScores: Map<String, int>.from(map['totalScores'] ?? {}),
      currentTrick: map['currentTrick'] != null
          ? Trick.fromMap(map['currentTrick'] as Map<String, dynamic>)
          : const Trick(),
      completedTricks: (map['completedTricks'] as List? ?? [])
          .map((t) => Trick.fromMap(t as Map<String, dynamic>))
          .toList(),
      phase: WizardPhase.values.firstWhere(
        (e) => e.name == map['phase'],
        orElse: () => WizardPhase.setup,
      ),
      canUndo: map['canUndo'] as bool? ?? false,
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'] as String)
          : null,
      endedAt: map['endedAt'] != null
          ? DateTime.parse(map['endedAt'] as String)
          : null,
    );
  }
}

enum WizardPhase {
  setup, // Players joining, game not started
  bidding, // Players placing their bids
  playing, // Cards being played in tricks
  scoring, // Round ended, showing scores
  finished, // All rounds complete
}
