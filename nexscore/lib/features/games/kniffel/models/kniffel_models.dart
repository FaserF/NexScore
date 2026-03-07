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
