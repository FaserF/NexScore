import 'package:flutter_test/flutter_test.dart';

import 'package:nexscore/features/games/buzztap/providers/buzztap_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/core/models/drink_intensity.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:flutter/widgets.dart';

void main() {
  group('BuzzTap 2-Player Filter', () {
    test('drawNextCard respects 2-player optimization toggle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(buzzTapStateProvider.notifier);

      // Initialize state with optimization ON
      notifier.toggle2PlayerOptimization(true);

      final players = [
        const Player(id: '1', name: 'Alice', avatarColor: '#FFFFFF'),
        const Player(id: '2', name: 'Bob', avatarColor: '#FFFFFF'),
      ];

      final l10n = AppLocalizations(const Locale('en'));

      // Draw 50 cards to statistically ensure no 3+ player cards slip through
      for (int i = 0; i < 50; i++) {
        notifier.drawNextCard(players, l10n);

        final currentCard = notifier.state.currentCard;
        if (currentCard != null) {
          expect(
            currentCard.minPlayers,
            lessThanOrEqualTo(2),
            reason:
                'Card \${currentCard.id} requires \${currentCard.minPlayers} players but optimization for 2 players is ON.',
          );
        }
      }
    });
  });

  group('BuzzTap DrinkIntensity Setting', () {
    test('State correctly updates intensity mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(buzzTapStateProvider.notifier);

      notifier.toggleIntensity(DrinkIntensity.extreme);
      expect(notifier.state.intensity, equals(DrinkIntensity.extreme));

      notifier.setCustomIntensity(3.5);
      expect(notifier.state.customIntensityMultiplier, equals(3.5));
    });
  });
}
