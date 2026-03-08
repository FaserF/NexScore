import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/features/games/factquest/models/factquest_models.dart';
import 'package:nexscore/features/games/factquest/models/factquest_database.dart';
import 'package:nexscore/features/games/factquest/providers/factquest_provider.dart';

void main() {
  group('FactQuestCard model', () {
    test('toJson / fromJson round-trips correctly', () {
      const card = FactQuestCard(
        id: 'test1',
        text: 'Test fact',
        explanation: 'Test explanation',
        sourceUrl: 'https://example.com',
        emoji: '🧪',
        category: FactQuestCategory.randomFacts,
      );

      final json = card.toJson();
      final restored = FactQuestCard.fromJson(json);

      expect(restored.id, 'test1');
      expect(restored.text, 'Test fact');
      expect(restored.explanation, 'Test explanation');
      expect(restored.sourceUrl, 'https://example.com');
      expect(restored.emoji, '🧪');
      expect(restored.category, FactQuestCategory.randomFacts);
    });

    test('textKey and explanationKey are computed correctly', () {
      const card = FactQuestCard(
        id: 'rf001',
        text: 'x',
        explanation: 'y',
        sourceUrl: 'z',
        category: FactQuestCategory.randomFacts,
      );
      expect(card.textKey, 'fq_card_rf001_text');
      expect(card.explanationKey, 'fq_card_rf001_expl');
    });
  });

  group('FactQuestGameState model', () {
    test('copyWith preserves unchanged fields', () {
      const state = FactQuestGameState();
      final updated = state.copyWith(activePlayerIds: ['a', 'b']);

      expect(updated.activePlayerIds, ['a', 'b']);
      expect(updated.selectedCategories, state.selectedCategories);
      expect(updated.playedCards, isEmpty);
    });

    test('toMap / fromMap round-trips correctly', () {
      const card = FactQuestCard(
        id: 'test',
        text: 'T',
        explanation: 'E',
        sourceUrl: 'U',
        emoji: '🎯',
        category: FactQuestCategory.dumbWaysToDie,
      );
      final state = FactQuestGameState(
        activePlayerIds: const ['p1'],
        selectedCategories: const [FactQuestCategory.dumbWaysToDie],
        playedCards: [card],
      );
      final map = state.toMap();
      final restored = FactQuestGameState.fromMap(map);

      expect(restored.activePlayerIds, ['p1']);
      expect(restored.selectedCategories, [FactQuestCategory.dumbWaysToDie]);
      expect(restored.playedCards.length, 1);
      expect(restored.playedCards.first.id, 'test');
    });

    test('currentCard returns last played card', () {
      const state = FactQuestGameState();
      expect(state.currentCard, isNull);

      const card = FactQuestCard(
        id: 'c1',
        text: 'X',
        explanation: 'Y',
        sourceUrl: 'Z',
        category: FactQuestCategory.randomFacts,
      );
      final withCards = state.copyWith(playedCards: [card]);
      expect(withCards.currentCard?.id, 'c1');
    });
  });

  group('FactQuest database', () {
    test('contains at least 20 cards', () {
      expect(factQuestDatabase.length, greaterThanOrEqualTo(20));
    });

    test('every card has a non-empty sourceUrl', () {
      for (final card in factQuestDatabase) {
        expect(
          card.sourceUrl,
          isNotEmpty,
          reason: 'Card ${card.id} must have a sourceUrl',
        );
        expect(
          card.sourceUrl.startsWith('http'),
          isTrue,
          reason: 'Card ${card.id} sourceUrl must be a valid URL',
        );
      }
    });

    test('all card IDs are unique', () {
      final ids = factQuestDatabase.map((c) => c.id).toSet();
      expect(ids.length, factQuestDatabase.length);
    });

    test('both categories are represented', () {
      final cats = factQuestDatabase.map((c) => c.category).toSet();
      expect(cats, contains(FactQuestCategory.randomFacts));
      expect(cats, contains(FactQuestCategory.dumbWaysToDie));
    });
  });

  group('FactQuestStateNotifier (via ProviderContainer)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has both categories and no played cards', () {
      final state = container.read(factQuestStateProvider);
      expect(state.selectedCategories, hasLength(2));
      expect(state.playedCards, isEmpty);
    });

    test('toggleCategory removes a category (keeps at least 1)', () {
      final notifier = container.read(factQuestStateProvider.notifier);

      // Remove randomFacts – should succeed since dumbWaysToDie remains
      notifier.toggleCategory(FactQuestCategory.randomFacts);
      final s1 = container.read(factQuestStateProvider);
      expect(s1.selectedCategories, [FactQuestCategory.dumbWaysToDie]);

      // Try to remove the last one – should NOT remove
      notifier.toggleCategory(FactQuestCategory.dumbWaysToDie);
      final s2 = container.read(factQuestStateProvider);
      expect(s2.selectedCategories, [FactQuestCategory.dumbWaysToDie]);
    });

    test('toggleCategory adds a category back', () {
      final notifier = container.read(factQuestStateProvider.notifier);
      notifier.toggleCategory(FactQuestCategory.randomFacts);
      notifier.toggleCategory(FactQuestCategory.randomFacts);
      final state = container.read(factQuestStateProvider);
      expect(state.selectedCategories, hasLength(2));
    });

    test('resetGame clears played cards', () {
      final notifier = container.read(factQuestStateProvider.notifier);
      notifier.resetGame();
      final state = container.read(factQuestStateProvider);
      expect(state.playedCards, isEmpty);
    });

    test('initPlayers sets activePlayerIds', () {
      final notifier = container.read(factQuestStateProvider.notifier);
      notifier.initPlayers(['p1', 'p2']);
      final state = container.read(factQuestStateProvider);
      expect(state.activePlayerIds, ['p1', 'p2']);
    });

    test('undo reverts to previous state after drawing a card', () {
      final notifier = container.read(factQuestStateProvider.notifier);

      // Initial state: 0 cards
      expect(container.read(factQuestStateProvider).playedCards, isEmpty);

      // Draw first card
      notifier.drawNextCard(AppLocalizations(const Locale('en')));
      expect(container.read(factQuestStateProvider).playedCards, hasLength(1));
      final firstCard = container
          .read(factQuestStateProvider)
          .playedCards
          .first;

      // Draw second card
      notifier.drawNextCard(AppLocalizations(const Locale('en')));
      expect(container.read(factQuestStateProvider).playedCards, hasLength(2));

      // Undo
      notifier.undo();
      final stateAfterUndo = container.read(factQuestStateProvider);
      expect(stateAfterUndo.playedCards, hasLength(1));
      expect(stateAfterUndo.playedCards.first.id, firstCard.id);
    });

    test('undo reverts category toggle', () {
      final notifier = container.read(factQuestStateProvider.notifier);

      // Initial: both categories
      expect(
        container.read(factQuestStateProvider).selectedCategories,
        hasLength(2),
      );

      // Toggle one off
      notifier.toggleCategory(FactQuestCategory.randomFacts);
      expect(container.read(factQuestStateProvider).selectedCategories, [
        FactQuestCategory.dumbWaysToDie,
      ]);

      // Undo
      notifier.undo();
      expect(
        container.read(factQuestStateProvider).selectedCategories,
        hasLength(2),
      );
    });

    test('history is limited (smoke test for _pushState)', () {
      final notifier = container.read(factQuestStateProvider.notifier);
      for (int i = 0; i < 25; i++) {
        notifier.toggleCategory(FactQuestCategory.randomFacts);
      }
      // No crash, and we can still undo
      expect(notifier.canUndo, isTrue);
      notifier.undo();
      expect(notifier.canUndo, isTrue);
    });
  });
}
