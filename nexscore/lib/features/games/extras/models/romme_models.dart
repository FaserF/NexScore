class RommeRound {
  final int roundIndex;
  final Map<String, int> penaltyPoints; // Player ID -> Points
  final String winnerId;
  final bool isHandRomme;

  const RommeRound({
    required this.roundIndex,
    required this.penaltyPoints,
    required this.winnerId,
    this.isHandRomme = false,
  });

  Map<String, dynamic> toJson() => {
    'roundIndex': roundIndex,
    'penaltyPoints': penaltyPoints,
    'winnerId': winnerId,
    'isHandRomme': isHandRomme,
  };

  factory RommeRound.fromJson(Map<String, dynamic> json) {
    return RommeRound(
      roundIndex: json['roundIndex'] as int,
      penaltyPoints: Map<String, int>.from(json['penaltyPoints'] as Map),
      winnerId: json['winnerId'] as String? ?? '',
      isHandRomme: json['isHandRomme'] as bool? ?? false,
    );
  }
}

class RommeGameState {
  final List<RommeRound> rounds;
  final int firstMeldPoints; // e.g. 0, 30, 40
  final bool doubleOnHandRomme;
  final bool canUndo;

  const RommeGameState({
    this.rounds = const [],
    this.firstMeldPoints = 40,
    this.doubleOnHandRomme = true,
    this.canUndo = false,
  });

  RommeGameState copyWith({
    List<RommeRound>? rounds,
    int? firstMeldPoints,
    bool? doubleOnHandRomme,
    bool? canUndo,
  }) {
    return RommeGameState(
      rounds: rounds ?? this.rounds,
      firstMeldPoints: firstMeldPoints ?? this.firstMeldPoints,
      doubleOnHandRomme: doubleOnHandRomme ?? this.doubleOnHandRomme,
      canUndo: canUndo ?? this.canUndo,
    );
  }

  int getPlayerScore(String playerId) {
    return rounds.fold(0, (sum, round) {
      int points = round.penaltyPoints[playerId] ?? 0;
      return sum + points;
    });
  }

  List<String> getLeaders(List<String> allPlayerIds) {
    if (rounds.isEmpty || allPlayerIds.isEmpty) return [];

    final scores = {for (var pid in allPlayerIds) pid: getPlayerScore(pid)};
    final sortedPlayerIds = scores.keys.toList()
      ..sort(
        (a, b) => scores[a]!.compareTo(scores[b]!),
      ); // Lowest score is best

    return sortedPlayerIds;
  }

  Map<String, dynamic> toJson() => {
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'firstMeldPoints': firstMeldPoints,
    'doubleOnHandRomme': doubleOnHandRomme,
    'canUndo': canUndo,
  };

  factory RommeGameState.fromJson(Map<String, dynamic> json) {
    return RommeGameState(
      rounds:
          (json['rounds'] as List?)
              ?.map((r) => RommeRound.fromJson(r))
              .toList() ??
          [],
      firstMeldPoints: json['firstMeldPoints'] as int? ?? 40,
      doubleOnHandRomme: json['doubleOnHandRomme'] as bool? ?? true,
      canUndo: json['canUndo'] as bool? ?? false,
    );
  }
}
