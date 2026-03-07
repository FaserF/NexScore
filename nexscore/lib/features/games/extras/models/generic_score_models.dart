/// State of a generic scoreboard session.
class GenericScoreState {
  final List<String> playerIds;
  final List<List<int>> rounds; // [roundIndex][playerIndex]
  final Map<String, int> playerTotals;

  const GenericScoreState({
    this.playerIds = const [],
    this.rounds = const [],
    this.playerTotals = const {},
  });

  GenericScoreState copyWith({
    List<String>? playerIds,
    List<List<int>>? rounds,
    Map<String, int>? playerTotals,
  }) {
    return GenericScoreState(
      playerIds: playerIds ?? this.playerIds,
      rounds: rounds ?? this.rounds,
      playerTotals: playerTotals ?? this.playerTotals,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerIds': playerIds,
    'rounds': rounds,
    'playerTotals': playerTotals,
  };

  factory GenericScoreState.fromJson(Map<String, dynamic> json) {
    return GenericScoreState(
      playerIds: List<String>.from(json['playerIds'] ?? []),
      rounds: (json['rounds'] as List? ?? [])
          .map((r) => List<int>.from(r as List))
          .toList(),
      playerTotals: Map<String, int>.from(json['playerTotals'] ?? {}),
    );
  }
}
