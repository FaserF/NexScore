import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/wayquest/models/wayquest_models.dart';
import 'package:nexscore/features/games/wayquest/providers/wayquest_provider.dart';

void main() {
  group('WayQuestStateNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is correct', () {
      final state = container.read(wayQuestStateProvider);
      expect(state.selectedCategories.length, 2);
      expect(state.selectedCategories.contains(WayQuestCategory.deepTalks), isTrue);
      expect(state.selectedCategories.contains(WayQuestCategory.wouldYouRather), isTrue);
      expect(state.playedCards, isEmpty);
      expect(state.canUndo, isFalse);
      expect(state.scores, isEmpty);
      expect(state.lastWinnerId, isNull);
    });

    test('toggleCategory works correctly', () {
      final notifier = container.read(wayQuestStateProvider.notifier);
      
      // Initially deepTalks is present
      expect(container.read(wayQuestStateProvider).selectedCategories.contains(WayQuestCategory.deepTalks), isTrue);
      
      // Toggle to remove
      notifier.toggleCategory(WayQuestCategory.deepTalks);
      expect(container.read(wayQuestStateProvider).selectedCategories.contains(WayQuestCategory.deepTalks), isFalse);

      // Toggle to add
      notifier.toggleCategory(WayQuestCategory.deepTalks);
      expect(container.read(wayQuestStateProvider).selectedCategories.contains(WayQuestCategory.deepTalks), isTrue);
    });

    test('resetGame resets state correctly including scores', () {
      final notifier = container.read(wayQuestStateProvider.notifier);
      
      // Modify state
      notifier.recordWinner('player1', 1);
      
      var state = container.read(wayQuestStateProvider);
      expect(state.scores.isNotEmpty, isTrue);

      // Reset
      notifier.resetGame();
      
      state = container.read(wayQuestStateProvider);
      expect(state.playedCards, isEmpty);
      expect(state.canUndo, isFalse);
      expect(state.scores, isEmpty);
      expect(state.lastWinnerId, isNull);
    });

    test('recordWinner correctly updates scores', () {
      final notifier = container.read(wayQuestStateProvider.notifier);
      
      notifier.recordWinner('player1', 1);
      var state = container.read(wayQuestStateProvider);
      
      expect(state.scores['player1'], 1);
      expect(state.lastWinnerId, 'player1');

      // Add another win
      notifier.recordWinner('player1', 2);
      state = container.read(wayQuestStateProvider);
      
      expect(state.scores['player1'], 3);
      expect(state.lastWinnerId, 'player1');
      
      // Different player
      notifier.recordWinner('player2', 1);
      state = container.read(wayQuestStateProvider);
      
      expect(state.scores['player2'], 1);
      expect(state.lastWinnerId, 'player2');
    });

    test('fromJson and toJson maintain scores and lastWinnerId', () {
      final state = const WayQuestGameState(
        scores: {'p1': 5, 'p2': 3},
        lastWinnerId: 'p1',
        canUndo: true,
      );
      
      final json = state.toMap();
      final newState = WayQuestGameState.fromMap(json);
      
      expect(newState.scores['p1'], 5);
      expect(newState.scores['p2'], 3);
      expect(newState.lastWinnerId, 'p1');
      expect(newState.canUndo, isTrue);
    });
  });
}
