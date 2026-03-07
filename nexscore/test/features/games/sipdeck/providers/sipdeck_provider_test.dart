import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/models/drink_intensity.dart';
import 'package:nexscore/features/games/sipdeck/providers/sipdeck_provider.dart';

void main() {
  group('SipDeck DrinkIntensity Setting', () {
    test('State correctly updates intensity mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(sipDeckStateProvider.notifier);

      notifier.toggleIntensity(DrinkIntensity.chill);
      expect(notifier.state.intensity, equals(DrinkIntensity.chill));

      notifier.setCustomIntensity(7.0);
      expect(notifier.state.customIntensityMultiplier, equals(7.0));
    });
  });
}
