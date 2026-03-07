import 'dart:math';

enum DrinkIntensity { chill, normal, extreme, custom }

extension DrinkIntensityExtension on DrinkIntensity {
  int calculateSips(int baseSips, {double customMultiplier = 1.0}) {
    if (baseSips <= 0) return baseSips; // Rule-based or sip-less cards
    switch (this) {
      case DrinkIntensity.chill:
        final sips = (baseSips * 0.5).floor();
        return max(1, sips); // Ensure at least 1 sip if it's a drinking card
      case DrinkIntensity.normal:
        return baseSips;
      case DrinkIntensity.extreme:
        return baseSips * 2;
      case DrinkIntensity.custom:
        final sips = (baseSips * customMultiplier).floor();
        return max(1, sips);
    }
  }
}
