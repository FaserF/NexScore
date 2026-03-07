import 'bavarian_card_models.dart';

/// Phase of the digital Schafkopf game.
enum SchafkopfDigitalPhase {
  setup, // Waiting to start
  gameSelect, // Players choose game type or pass
  playing, // Trick-taking phase
  scoring, // Round results
  finished, // Game over
}

/// State model for the digital Schafkopf game.
class SchafkopfDigitalState {
  final SchafkopfDigitalPhase phase;
  final List<String> playerOrder; // Always 4 players
  final Map<String, List<BavarianCard>> hands;
  final SchafkopfDigitalGameType? gameType;
  final String? activePlayerId; // Who called the game
  final String?
  partnerPlayerId; // Partner in Sauspiel (determined by called Ace)
  final BavarianSuit? calledSuit; // Which Ace was called in Sauspiel
  final SchafkopfTrick currentTrick;
  final List<SchafkopfTrick> completedTricks;
  final Map<String, int> tricksWon;
  final Map<String, int> pointsWon;
  final String? currentPlayerId;
  final String? currentDealerId;
  final int roundNumber;
  final Map<String, int> totalScores; // Running game scores (cents)

  const SchafkopfDigitalState({
    this.phase = SchafkopfDigitalPhase.setup,
    this.playerOrder = const [],
    this.hands = const {},
    this.gameType,
    this.activePlayerId,
    this.partnerPlayerId,
    this.calledSuit,
    this.currentTrick = const SchafkopfTrick(),
    this.completedTricks = const [],
    this.tricksWon = const {},
    this.pointsWon = const {},
    this.currentPlayerId,
    this.currentDealerId,
    this.roundNumber = 0,
    this.totalScores = const {},
  });

  SchafkopfDigitalState copyWith({
    SchafkopfDigitalPhase? phase,
    List<String>? playerOrder,
    Map<String, List<BavarianCard>>? hands,
    SchafkopfDigitalGameType? gameType,
    String? activePlayerId,
    String? partnerPlayerId,
    BavarianSuit? calledSuit,
    SchafkopfTrick? currentTrick,
    List<SchafkopfTrick>? completedTricks,
    Map<String, int>? tricksWon,
    Map<String, int>? pointsWon,
    String? currentPlayerId,
    String? currentDealerId,
    int? roundNumber,
    Map<String, int>? totalScores,
  }) {
    return SchafkopfDigitalState(
      phase: phase ?? this.phase,
      playerOrder: playerOrder ?? this.playerOrder,
      hands: hands ?? this.hands,
      gameType: gameType ?? this.gameType,
      activePlayerId: activePlayerId ?? this.activePlayerId,
      partnerPlayerId: partnerPlayerId ?? this.partnerPlayerId,
      calledSuit: calledSuit ?? this.calledSuit,
      currentTrick: currentTrick ?? this.currentTrick,
      completedTricks: completedTricks ?? this.completedTricks,
      tricksWon: tricksWon ?? this.tricksWon,
      pointsWon: pointsWon ?? this.pointsWon,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      currentDealerId: currentDealerId ?? this.currentDealerId,
      roundNumber: roundNumber ?? this.roundNumber,
      totalScores: totalScores ?? this.totalScores,
    );
  }

  Map<String, dynamic> toMap() => {
    'phase': phase.name,
    'playerOrder': playerOrder,
    'hands': hands.map((k, v) => MapEntry(k, v.map((c) => c.toMap()).toList())),
    'gameType': gameType?.name,
    'activePlayerId': activePlayerId,
    'partnerPlayerId': partnerPlayerId,
    'calledSuit': calledSuit?.name,
    'currentTrick': currentTrick.toMap(),
    'completedTricks': completedTricks.map((t) => t.toMap()).toList(),
    'tricksWon': tricksWon,
    'pointsWon': pointsWon,
    'currentPlayerId': currentPlayerId,
    'currentDealerId': currentDealerId,
    'roundNumber': roundNumber,
    'totalScores': totalScores,
  };

  factory SchafkopfDigitalState.fromMap(Map<String, dynamic> map) {
    final handsMap = (map['hands'] as Map<String, dynamic>?) ?? {};
    return SchafkopfDigitalState(
      phase: SchafkopfDigitalPhase.values.firstWhere(
        (p) => p.name == map['phase'],
        orElse: () => SchafkopfDigitalPhase.setup,
      ),
      playerOrder: List<String>.from(map['playerOrder'] ?? []),
      hands: handsMap.map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((c) => BavarianCard.fromMap(c as Map<String, dynamic>))
              .toList(),
        ),
      ),
      gameType: map['gameType'] != null
          ? SchafkopfDigitalGameType.values.firstWhere(
              (g) => g.name == map['gameType'],
              orElse: () => SchafkopfDigitalGameType.sauspiel,
            )
          : null,
      activePlayerId: map['activePlayerId'] as String?,
      partnerPlayerId: map['partnerPlayerId'] as String?,
      calledSuit: map['calledSuit'] != null
          ? BavarianSuit.values.firstWhere((s) => s.name == map['calledSuit'])
          : null,
      currentTrick: map['currentTrick'] != null
          ? SchafkopfTrick.fromMap(map['currentTrick'] as Map<String, dynamic>)
          : const SchafkopfTrick(),
      completedTricks:
          (map['completedTricks'] as List?)
              ?.map((t) => SchafkopfTrick.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      tricksWon: Map<String, int>.from(map['tricksWon'] ?? {}),
      pointsWon: Map<String, int>.from(map['pointsWon'] ?? {}),
      currentPlayerId: map['currentPlayerId'] as String?,
      currentDealerId: map['currentDealerId'] as String?,
      roundNumber: map['roundNumber'] as int? ?? 0,
      totalScores: Map<String, int>.from(map['totalScores'] ?? {}),
    );
  }
}
