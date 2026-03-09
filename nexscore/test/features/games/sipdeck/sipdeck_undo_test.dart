import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/sipdeck/providers/sipdeck_provider.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:flutter/widgets.dart';

// Mock AppLocalizations for testing
class MockAppLocalizations extends AppLocalizations {
  MockAppLocalizations() : super(const Locale('en'));
  @override
  String get(String key) => key;
  @override
  String getWith(String key, List<String> args) => key;
}

void main() {
  group('SipDeckStateNotifier Undo Tests', () {
    late ProviderContainer container;
    final players = [
      Player(
        id: 'p1',
        name: 'Player 1',
        avatarColor: '#FF0000',
        ownerUid: null,
      ),
      Player(
        id: 'p2',
        name: 'Player 2',
        avatarColor: '#00FF00',
        ownerUid: null,
      ),
    ];

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Undo after drawNextCard', () {
      final notifier = container.read(sipDeckStateProvider.notifier);
      final l10n = MockAppLocalizations();

      notifier.drawNextCard(players, l10n);
      expect(container.read(sipDeckStateProvider).playedCards, isNotEmpty);
      expect(container.read(sipDeckStateProvider).canUndo, isTrue);

      notifier.undo();
      expect(container.read(sipDeckStateProvider).playedCards, isEmpty);
      expect(container.read(sipDeckStateProvider).playerSips, isEmpty);
    });

    test('Undo after manual sip increment', () {
      final notifier = container.read(sipDeckStateProvider.notifier);

      notifier.incrementSips('p1', 5);
      expect(container.read(sipDeckStateProvider).playerSips['p1'], 5);

      notifier.undo();
      expect(container.read(sipDeckStateProvider).playerSips['p1'], isNull);
    });

    test('Undo after completeCard (sip recording)', () {
      final notifier = container.read(sipDeckStateProvider.notifier);
      final l10n = MockAppLocalizations();

      // Draw a card
      notifier.drawNextCard(players, l10n);
      final card = container.read(sipDeckStateProvider).playedCards.last;

      // Complete it (records sips)
      notifier.completeCard(false);
      if (card.sips > 0 && card.targetIds.isNotEmpty) {
        expect(
          container
              .read(sipDeckStateProvider)
              .playerSips
              .values
              .any((v) => v > 0),
          isTrue,
        );
      }

      notifier.undo(); // Undo completion
      expect(
        container
            .read(sipDeckStateProvider)
            .playerSips
            .values
            .every((v) => v == 0),
        isTrue,
      );

      notifier.undo(); // Undo draw
      expect(container.read(sipDeckStateProvider).playedCards, isEmpty);
    });
  });
}
