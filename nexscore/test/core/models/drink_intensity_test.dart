import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/models/drink_intensity.dart';

void main() {
  group('DrinkIntensity calculations', () {
    test('Chill intensity halves sips and rounds down, minimum 1', () {
      expect(DrinkIntensity.chill.calculateSips(2), equals(1));
      expect(DrinkIntensity.chill.calculateSips(3), equals(1));
      expect(DrinkIntensity.chill.calculateSips(4), equals(2));
      expect(DrinkIntensity.chill.calculateSips(1), equals(1));
      expect(
        DrinkIntensity.chill.calculateSips(0),
        equals(0),
      ); // Rule-based exception
    });

    test('Normal intensity retains sips', () {
      expect(DrinkIntensity.normal.calculateSips(2), equals(2));
      expect(DrinkIntensity.normal.calculateSips(3), equals(3));
      expect(DrinkIntensity.normal.calculateSips(0), equals(0));
    });

    test('Extreme intensity doubles sips', () {
      expect(DrinkIntensity.extreme.calculateSips(2), equals(4));
      expect(DrinkIntensity.extreme.calculateSips(3), equals(6));
      expect(DrinkIntensity.extreme.calculateSips(0), equals(0));
    });

    test('Custom intensity applies multiplier and rounds down, minimum 1', () {
      expect(
        DrinkIntensity.custom.calculateSips(2, customMultiplier: 1.5),
        equals(3),
      );
      expect(
        DrinkIntensity.custom.calculateSips(2, customMultiplier: 0.1),
        equals(1),
      );
      expect(
        DrinkIntensity.custom.calculateSips(3, customMultiplier: 0.1),
        equals(1),
      );
      expect(
        DrinkIntensity.custom.calculateSips(5, customMultiplier: 1.5),
        equals(7),
      ); // 7.5 -> 7
      expect(
        DrinkIntensity.custom.calculateSips(1, customMultiplier: 0.1),
        equals(1),
      );
      expect(
        DrinkIntensity.custom.calculateSips(0, customMultiplier: 10.0),
        equals(0),
      );
    });
  });
}
