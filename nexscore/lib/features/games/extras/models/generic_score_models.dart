/// State of a generic scoreboard session.
class GenericScoreState {
  final List<String> playerIds;
  final List<List<int>> rounds; // [roundIndex][playerIndex]
  final Map<String, int> playerTotals;
  final bool canUndo;

  const GenericScoreState({
    this.playerIds = const [],
    this.rounds = const [],
    this.playerTotals = const {},
    this.canUndo = false,
  });

  GenericScoreState copyWith({
    List<String>? playerIds,
    List<List<int>>? rounds,
    Map<String, int>? playerTotals,
    bool? canUndo,
  }) {
    return GenericScoreState(
      playerIds: playerIds ?? this.playerIds,
      rounds: rounds ?? this.rounds,
      playerTotals: playerTotals ?? this.playerTotals,
      canUndo: canUndo ?? this.canUndo,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerIds': playerIds,
    'rounds': rounds,
    'playerTotals': playerTotals,
    'canUndo': canUndo,
  };

  factory GenericScoreState.fromJson(Map<String, dynamic> json) {
    return GenericScoreState(
      playerIds: List<String>.from(json['playerIds'] ?? []),
      rounds: (json['rounds'] as List? ?? [])
          .map((r) => List<int>.from(r as List))
          .toList(),
      playerTotals: Map<String, int>.from(json['playerTotals'] ?? {}),
      canUndo: json['canUndo'] ?? false,
    );
  }
}
