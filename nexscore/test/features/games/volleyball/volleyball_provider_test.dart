import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/volleyball/models/volleyball_models.dart';
import 'package:nexscore/features/games/volleyball/providers/volleyball_provider.dart';

void main() {
  group('Volleyball Rules', () {
    test('Indoor rules are correct', () {
      final rules = VolleyballRules.indoor();
      expect(rules.setsToWin, 3);
      expect(rules.pointsPerSet, 25);
      expect(rules.decidingSetPoints, 15);
    });

    test('Beach rules are correct', () {
      final rules = VolleyballRules.beach();
      expect(rules.setsToWin, 2);
      expect(rules.pointsPerSet, 21);
      expect(rules.switchSidesEvery, 7);
    });
  });

  group('VolleyballStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is default', () {
      final state = container.read(volleyballStateProvider);
      expect(state.teamAName, 'Team A');
      expect(state.sets, hasLength(1));
    });

    test('setupMatch configures the game', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.setupMatch(
        type: VolleyballType.beach,
        teamA: 'Eagles',
        teamB: 'Sharks',
        pA: ['P1', 'P2'],
        pB: ['P3', 'P4'],
      );

      final state = container.read(volleyballStateProvider);
      expect(state.type, VolleyballType.beach);
      expect(state.teamAName, 'Eagles');
      expect(state.rules.setsToWin, 2);
    });

    test('addPoint increments score and sets server', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.addPoint('A');

      final state = container.read(volleyballStateProvider);
      expect(state.currentSet.scoreA, 1);
      expect(state.server, 'A');
    });

    test('set transition occurs when target is reached', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.setupMatch(
        type: VolleyballType.beach, // 21 points
        teamA: 'A',
        teamB: 'B',
        pA: [],
        pB: [],
      );

      // Score 20-20
      for (int i = 0; i < 20; i++) {
        notifier.addPoint('A');
        notifier.addPoint('B');
      }

      // Next point to A (21-20) - Should not finish (need 2 points lead)
      notifier.addPoint('A');
      expect(container.read(volleyballStateProvider).currentSetIndex, 0);
      expect(
        container.read(volleyballStateProvider).sets[0].isFinished,
        isFalse,
      );

      // Next point to A (22-20) - Should finish set
      notifier.addPoint('A');
      final state = container.read(volleyballStateProvider);
      expect(state.sets[0].isFinished, isTrue);
      expect(state.currentSetIndex, 1);
      expect(state.setsWonA, 1);
    });

    test('match finishes when setsToWin is reached', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.setupMatch(
        type: VolleyballType.beach, // 2 sets to win
        teamA: 'A',
        teamB: 'B',
        pA: [],
        pB: [],
      );

      // Win 2 sets for A
      // Set 1
      for (int i = 0; i < 21; i++) notifier.addPoint('A');
      // Set 2
      for (int i = 0; i < 21; i++) notifier.addPoint('A');

      final state = container.read(volleyballStateProvider);
      expect(state.matchFinished, isTrue);
      expect(state.setsWonA, 2);
    });

    test('undo reverts scores', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.addPoint('A');
      expect(container.read(volleyballStateProvider).currentSet.scoreA, 1);

      notifier.undo();
      expect(container.read(volleyballStateProvider).currentSet.scoreA, 0);
    });
  });
}
