import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/qwixx/models/qwixx_models.dart';

void main() {
  group('Qwixx Models', () {
    test('score for line calculates correctly', () {
      const sheet = QwixxPlayerSheet();

      // score for 1 cross
      expect(sheet.calculateRowScore(1), 1);

      // score for 2 crosses
      expect(sheet.calculateRowScore(2), 3);

      // score for 5 crosses
      expect(sheet.calculateRowScore(5), 15);

      // score for 10 crosses
      expect(sheet.calculateRowScore(10), 55);

      // score for > 12 crosses (capped at 12 logic normally, but array max is 12)
      expect(sheet.calculateRowScore(12), 78);
    });

    test('total score calculates correctly with properties and penalties', () {
      // 3 red (6pts), 4 yellow (10pts), 2 green (3pts), 5 blue (15pts), 2 penalties (-10 points)
      final sheet = QwixxPlayerSheet(
        red: [2, 3, 4],
        yellow: [2, 3, 4, 5],
        green: [12, 11],
        blue: [12, 11, 10, 9, 8],
        penalties: 2,
      );

      // 6 + 10 + 3 + 15 - 10 = 24
      expect(sheet.totalScore, 24);
    });
  });
}
