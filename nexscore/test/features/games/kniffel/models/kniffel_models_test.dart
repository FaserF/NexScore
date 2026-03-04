import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/kniffel/models/kniffel_models.dart';

void main() {
  group('Kniffel Models – upper section', () {
    test('upper section sum and bonus when exactly 63', () {
      final sheet = YahtzeePlayerSheet(
        scores: {
          YahtzeeCategory.ones: 3,
          YahtzeeCategory.twos: 6,
          YahtzeeCategory.threes: 9,
          YahtzeeCategory.fours: 12,
          YahtzeeCategory.fives: 15,
          YahtzeeCategory.sixes: 18,
        },
      );
      // 3+6+9+12+15+18 = 63 → bonus = 35
      expect(sheet.upperSectionSum, 63);
      expect(sheet.upperSectionBonus, 35);
    });

    test('no bonus when upper section sum is 62', () {
      final sheet = YahtzeePlayerSheet(
        scores: {
          YahtzeeCategory.ones: 2, // 62 total
          YahtzeeCategory.twos: 6,
          YahtzeeCategory.threes: 9,
          YahtzeeCategory.fours: 12,
          YahtzeeCategory.fives: 15,
          YahtzeeCategory.sixes: 18,
        },
      );
      expect(sheet.upperSectionSum, 62);
      expect(sheet.upperSectionBonus, 0);
    });

    test('bonus when upper section sum exceeds 63', () {
      final sheet = YahtzeePlayerSheet(
        scores: {
          YahtzeeCategory.ones: 5,
          YahtzeeCategory.twos: 10,
          YahtzeeCategory.threes: 15,
          YahtzeeCategory.fours: 20,
          YahtzeeCategory.fives: 25,
          YahtzeeCategory.sixes: 30,
        },
      );
      expect(sheet.upperSectionBonus, 35);
    });
  });

  group('Kniffel Models – lower section fixed scores', () {
    test('Full House is always 25', () {
      final sheet = YahtzeePlayerSheet(scores: {YahtzeeCategory.fullHouse: 25});
      expect(sheet.lowerSectionSum, 25);
    });

    test('Small Straight is always 30', () {
      final sheet = YahtzeePlayerSheet(
        scores: {YahtzeeCategory.smallStraight: 30},
      );
      expect(sheet.lowerSectionSum, 30);
    });

    test('Large Straight is always 40', () {
      final sheet = YahtzeePlayerSheet(
        scores: {YahtzeeCategory.largeStraight: 40},
      );
      expect(sheet.lowerSectionSum, 40);
    });

    test('Yahtzee/Kniffel is always 50', () {
      final sheet = YahtzeePlayerSheet(scores: {YahtzeeCategory.yahtzee: 50});
      expect(sheet.lowerSectionSum, 50);
    });

    test('3-of-a-kind stores sum of all dice (variable)', () {
      // 5×5 = 25 stored as variable
      final sheet = YahtzeePlayerSheet(
        scores: {YahtzeeCategory.threeOfAKind: 25},
      );
      expect(sheet.lowerSectionSum, 25);
    });

    test('Chance stores sum of all dice', () {
      final sheet = YahtzeePlayerSheet(scores: {YahtzeeCategory.chance: 28});
      expect(sheet.lowerSectionSum, 28);
    });
  });

  group('Kniffel Models – totalScore', () {
    test('totalScore = upper + bonus + lower', () {
      final sheet = YahtzeePlayerSheet(
        scores: {
          YahtzeeCategory.ones: 3,
          YahtzeeCategory.twos: 6,
          YahtzeeCategory.threes: 9,
          YahtzeeCategory.fours: 12,
          YahtzeeCategory.fives: 15,
          YahtzeeCategory.sixes: 18, // upper=63, bonus=35
          YahtzeeCategory.fullHouse: 25,
          YahtzeeCategory.smallStraight: 30,
          YahtzeeCategory.largeStraight: 40,
          YahtzeeCategory.yahtzee: 50,
          YahtzeeCategory.threeOfAKind: 20,
          YahtzeeCategory.fourOfAKind: 18,
          YahtzeeCategory.chance: 22,
        },
      );
      // upper=63, bonus=35, lower=25+30+40+50+20+18+22=205
      // total = 63+35+205 = 303
      expect(sheet.totalScore, 303);
    });

    test('perfect zeros give 0 total', () {
      const sheet = YahtzeePlayerSheet(scores: {});
      expect(sheet.totalScore, 0);
    });
  });

  group('Kniffel Models – copyWith', () {
    test('copyWith replaces scores map', () {
      final original = YahtzeePlayerSheet(scores: {YahtzeeCategory.ones: 3});
      final updated = original.copyWith(
        scores: {YahtzeeCategory.ones: 3, YahtzeeCategory.yahtzee: 50},
      );
      expect(updated.lowerSectionSum, 50);
      expect(updated.upperSectionSum, 3);
    });
  });
}
