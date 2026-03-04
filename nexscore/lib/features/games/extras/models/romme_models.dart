class RommeRound {
  final int roundIndex;
  final Map<String, int> penaltyPoints; // Player ID -> Points

  const RommeRound({required this.roundIndex, required this.penaltyPoints});

  Map<String, dynamic> toJson() => {
    'roundIndex': roundIndex,
    'penaltyPoints': penaltyPoints,
  };

  factory RommeRound.fromJson(Map<String, dynamic> json) {
    return RommeRound(
      roundIndex: json['roundIndex'] as int,
      penaltyPoints: Map<String, int>.from(json['penaltyPoints'] as Map),
    );
  }
}

class RommeGameState {
  final List<RommeRound> rounds;

  const RommeGameState({this.rounds = const []});

  RommeGameState copyWith({List<RommeRound>? rounds}) {
    return RommeGameState(rounds: rounds ?? this.rounds);
  }

  int getPlayerScore(String playerId) {
    return rounds.fold(
      0,
      (sum, round) => sum + (round.penaltyPoints[playerId] ?? 0),
    );
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
  };

  factory RommeGameState.fromJson(Map<String, dynamic> json) {
    return RommeGameState(
      rounds:
          (json['rounds'] as List?)
              ?.map((r) => RommeRound.fromJson(r))
              .toList() ??
          [],
    );
  }
}
