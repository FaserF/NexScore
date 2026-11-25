import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/core/models/drink_intensity.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/features/games/sipdeck/models/sipdeck_models.dart';
import 'package:nexscore/features/games/sipdeck/providers/sipdeck_provider.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));
  final twoPlayers = [
    Player(id: 'p1', name: 'Alice', avatarColor: '#FF0000'),
    Player(id: 'p2', name: 'Bob', avatarColor: '#00FF00'),
  ];
  final threePlayers = [
    ...twoPlayers,
    Player(id: 'p3', name: 'Charlie', avatarColor: '#0000FF'),
  ];

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

  group('SipDeck Shuffle-Bag & 2-Player Optimization (#70)', () {
    test('drawNextCard draws all eligible cards without repeating before reshuffle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(sipDeckStateProvider.notifier);
      notifier.toggleHydrationCards(false);
      notifier.toggleFilterMultiplayerOnly(true);

      final eligible = getSipDeckDatabase(l10n)
          .where(
            (c) =>
                container.read(sipDeckStateProvider).selectedCategories.contains(c.category) &&
                c.minPlayers <= 2,
          )
          .toList();

      final drawnIds = <String>[];
      for (var i = 0; i < eligible.length; i++) {
        notifier.drawNextCard(twoPlayers, l10n);
        drawnIds.add(container.read(sipDeckStateProvider).currentCard!.id);
      }

      expect(drawnIds.length, equals(eligible.length));
      expect(drawnIds.toSet().length, equals(eligible.length));

      // Reshuffling after exhaustion must not immediately repeat the last card
      final lastBeforeReshuffle = drawnIds.last;
      notifier.drawNextCard(twoPlayers, l10n);
      final firstAfterReshuffle = container.read(sipDeckStateProvider).currentCard!.id;
      expect(firstAfterReshuffle, isNot(equals(lastBeforeReshuffle)));
    });

    test('filterMultiplayerOnly filters out minPlayers > 2 for 2 players', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(sipDeckStateProvider.notifier);
      notifier.toggleHydrationCards(false);
      for (final cat in SipDeckCategory.values) {
        if (!container.read(sipDeckStateProvider).selectedCategories.contains(cat)) {
          notifier.toggleCategory(cat);
        }
      }
      notifier.toggleFilterMultiplayerOnly(true);

      final dbById = {for (final c in getSipDeckDatabase(l10n)) c.id: c};
      final twoPlayerEligibleCount = dbById.values.where((c) => c.minPlayers <= 2).length;

      for (var i = 0; i < twoPlayerEligibleCount; i++) {
        notifier.drawNextCard(twoPlayers, l10n);
        final cardId = container.read(sipDeckStateProvider).currentCard!.id;
        expect(
          dbById[cardId]!.minPlayers,
          lessThanOrEqualTo(2),
          reason: 'Card $cardId requires >2 players in 2-player mode',
        );
      }
    });

    test('3-player game excludes cards requiring 4+ players', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(sipDeckStateProvider.notifier);
      notifier.toggleHydrationCards(false);
      notifier.toggleFilterMultiplayerOnly(false);
      for (final cat in SipDeckCategory.values) {
        if (!container.read(sipDeckStateProvider).selectedCategories.contains(cat)) {
          notifier.toggleCategory(cat);
        }
      }

      final dbById = {for (final c in getSipDeckDatabase(l10n)) c.id: c};
      final threePlayerCount = dbById.values.where((c) => c.minPlayers <= 3).length;

      for (var i = 0; i < threePlayerCount; i++) {
        notifier.drawNextCard(threePlayers, l10n);
        final cardId = container.read(sipDeckStateProvider).currentCard!.id;
        expect(dbById[cardId]!.minPlayers, lessThanOrEqualTo(3));
      }
    });

    test('undo restores shuffle-bag seenCardIds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(sipDeckStateProvider.notifier);
      notifier.toggleHydrationCards(false);

      notifier.drawNextCard(twoPlayers, l10n);
      final firstId = container.read(sipDeckStateProvider).currentCard!.id;
      expect(container.read(sipDeckStateProvider).seenCardIds, contains(firstId));

      notifier.undo();
      expect(container.read(sipDeckStateProvider).seenCardIds, isEmpty);
    });
  });
}
