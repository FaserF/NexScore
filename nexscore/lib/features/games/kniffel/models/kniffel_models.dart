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

  const YahtzeePlayerSheet({this.scores = const {}});

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
    return sum;
  }

  int get totalScore => upperSectionSum + upperSectionBonus + lowerSectionSum;

  YahtzeePlayerSheet copyWith({Map<YahtzeeCategory, int>? scores}) {
    return YahtzeePlayerSheet(scores: scores ?? this.scores);
  }
}
