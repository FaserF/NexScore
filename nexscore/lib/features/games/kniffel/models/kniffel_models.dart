enum YahtzeeCategory {
  ones,
  twos,
  threes,
  fours,
  fives,
  sixes,
  threeOfAKind,
  fourOfAKind,
  fullHouse,
  smallStraight,
  largeStraight,
  yahtzee,
  chance,
}

class YahtzeePlayerSheet {
  final Map<YahtzeeCategory, int> scores;
  final int
  bonusYahtzees; // Count of additional Yahtzees after the first 50-pt one

  const YahtzeePlayerSheet({this.scores = const {}, this.bonusYahtzees = 0});

  int get upperSectionSum {
    int sum = 0;
    for (var cat in [
      YahtzeeCategory.ones,
      YahtzeeCategory.twos,
      YahtzeeCategory.threes,
      YahtzeeCategory.fours,
      YahtzeeCategory.fives,
      YahtzeeCategory.sixes,
    ]) {
      sum += scores[cat] ?? 0;
    }
    return sum;
  }

  int get upperSectionBonus => upperSectionSum >= 63 ? 35 : 0;

  int get lowerSectionSum {
    int sum = 0;
    for (var cat in [
      YahtzeeCategory.threeOfAKind,
      YahtzeeCategory.fourOfAKind,
      YahtzeeCategory.fullHouse,
      YahtzeeCategory.smallStraight,
      YahtzeeCategory.largeStraight,
      YahtzeeCategory.yahtzee,
      YahtzeeCategory.chance,
    ]) {
      sum += scores[cat] ?? 0;
    }
    // Add multiple yahtzee bonuses (+50 each)
    sum += bonusYahtzees * 50;
    return sum;
  }

  int get totalScore => upperSectionSum + upperSectionBonus + lowerSectionSum;

  YahtzeePlayerSheet copyWith({
    Map<YahtzeeCategory, int>? scores,
    int? bonusYahtzees,
  }) {
    return YahtzeePlayerSheet(
      scores: scores ?? this.scores,
      bonusYahtzees: bonusYahtzees ?? this.bonusYahtzees,
    );
  }

  Map<String, dynamic> toJson() => {
    'scores': scores.map((k, v) => MapEntry(k.name, v)),
    'bonusYahtzees': bonusYahtzees,
  };

  factory YahtzeePlayerSheet.fromJson(Map<String, dynamic> json) {
    return YahtzeePlayerSheet(
      scores: (json['scores'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          YahtzeeCategory.values.firstWhere((e) => e.name == k),
          v as int,
        ),
      ),
      bonusYahtzees: json['bonusYahtzees'] as int? ?? 0,
    );
  }
}

class KniffelGameState {
  final Map<String, YahtzeePlayerSheet> playerSheets;
  final bool canUndo;

  const KniffelGameState({this.playerSheets = const {}, this.canUndo = false});

  KniffelGameState copyWith({
    Map<String, YahtzeePlayerSheet>? playerSheets,
    bool? canUndo,
  }) {
    return KniffelGameState(
      playerSheets: playerSheets ?? this.playerSheets,
      canUndo: canUndo ?? this.canUndo,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerSheets': playerSheets.map((k, v) => MapEntry(k, v.toJson())),
    'canUndo': canUndo,
  };

  factory KniffelGameState.fromJson(Map<String, dynamic> json) {
    return KniffelGameState(
      playerSheets: (json['playerSheets'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, YahtzeePlayerSheet.fromJson(v)),
      ),
      canUndo: json['canUndo'] as bool? ?? false,
    );
  }

  /// Returns the IDs of the players with the highest score.
  List<String> getLeaders() {
    if (playerSheets.isEmpty) return [];
    int maxScore = -1;
    for (final s in playerSheets.values) {
      if (s.totalScore > maxScore) maxScore = s.totalScore;
    }
    return playerSheets.entries
        .where((e) => e.value.totalScore == maxScore)
        .map((e) => e.key)
        .toList();
  }
}
