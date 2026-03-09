import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/volleyball/models/volleyball_models.dart';
import 'package:nexscore/features/games/volleyball/providers/volleyball_provider.dart';

void main() {
  group('Volleyball Rules', () {
    test('Indoor rules (DVV) are correct', () {
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

    test('BVV rules are correct', () {
      final rules = VolleyballRules.bvv();
      expect(rules.setsToWin, 2);
      expect(rules.pointsPerSet, 25);
      expect(rules.decidingSetPoints, 25);
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

    test('state has timestamps after setup', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.setupMatch(
        type: VolleyballType.indoor,
        teamA: 'A',
        teamB: 'B',
        pA: [],
        pB: [],
      );
      final state = container.read(volleyballStateProvider);
      expect(state.matchStartedAt, isNotNull);
      expect(state.sets[0].startedAt, isNotNull);
    });

    test('BVV league points calculation (3:0)', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.setupMatch(
        type: VolleyballType.indoor,
        teamA: 'A',
        teamB: 'B',
        pA: [],
        pB: [],
        ruleSet: VolleyballRuleSet.bvv,
      );

      // Win 2 sets to 0 (BVV is best of 3, so 2 sets to win)
      for (int s = 0; s < 2; s++) {
        for (int i = 0; i < 25; i++) {
          notifier.addPoint('A');
        }
      }

      final state = container.read(volleyballStateProvider);
      expect(state.matchFinished, isTrue);
      expect(state.setsWonA, 2);
      expect(state.setsWonB, 0);

      final (lpA, lpB) = state.leaguePoints;
      expect(lpA, 3);
      expect(lpB, 0);
    });

    test('BVV league points calculation (2:1)', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.setupMatch(
        type: VolleyballType.indoor,
        teamA: 'A',
        teamB: 'B',
        pA: [],
        pB: [],
        ruleSet: VolleyballRuleSet
            .bvv, // BVV: set finish triggers pendingContinue if sets remaining
      );

      // Set 1: A wins
      for (int i = 0; i < 25; i++) {
        notifier.addPoint('A');
      }
      // Set 2: B wins
      for (int i = 0; i < 25; i++) {
        notifier.addPoint('B');
      }

      // Winner determined (1:1 is not enough, need 2)
      // Actually BVV is best of 3. So 1:1 means 3rd set is mandatory.

      // Set 3: A wins
      for (int i = 0; i < 25; i++) {
        notifier.addPoint('A');
      }

      final state = container.read(volleyballStateProvider);
      expect(state.matchFinished, isTrue);
      expect(state.setsWonA, 2);
      expect(state.setsWonB, 1);

      final (lpA, lpB) = state.leaguePoints;
      expect(lpA, 2);
      expect(lpB, 1);
    });

    test('DVV league points calculation (3:2)', () {
      final notifier = container.read(volleyballStateProvider.notifier);
      notifier.setupMatch(
        type: VolleyballType.indoor,
        teamA: 'A',
        teamB: 'B',
        ruleSet: VolleyballRuleSet.dvv,
        setsToWin: 3,
        pA: [],
        pB: [],
      );

      // 2:2
      for (int s = 0; s < 2; s++) {
        for (int i = 0; i < 25; i++) {
          notifier.addPoint('A');
        }
        for (int i = 0; i < 25; i++) {
          notifier.addPoint('B');
        }
      }

      // Set 5 (Deciding): A wins
      for (int i = 0; i < 15; i++) {
        notifier.addPoint('A');
      }

      final state = container.read(volleyballStateProvider);
      expect(state.setsWonA, 3);
      expect(state.setsWonB, 2);

      final (lpA, lpB) = state.leaguePoints;
      expect(lpA, 2);
      expect(lpB, 1);
    });

    test(
      'pendingContinue flow when winner determined early but sets remain',
      () {
        final notifier = container.read(volleyballStateProvider.notifier);
        notifier.setupMatch(
          type: VolleyballType.indoor,
          teamA: 'A',
          teamB: 'B',
          ruleSet: VolleyballRuleSet.dvv,
          setsToWin: 2, // Best of 3
          pA: [],
          pB: [],
        );

        // A wins 2:0
        for (int s = 0; s < 2; s++) {
          for (int i = 0; i < 25; i++) {
            notifier.addPoint('A');
          }
        }

        var state = container.read(volleyballStateProvider);
        expect(state.matchFinished, isTrue);
        expect(
          state.pendingContinue,
          isTrue,
        ); // Should be true because 3rd set could be played

        // User decides to continue
        notifier.continuePlayingRemainingSets();
        state = container.read(volleyballStateProvider);
        expect(state.matchFinished, isFalse);
        expect(state.currentSetIndex, 2);

        // Finish last set
        for (int i = 0; i < 25; i++) {
          notifier.addPoint('B');
        }
        state = container.read(volleyballStateProvider);
        expect(state.matchFinished, isTrue);
        expect(state.pendingContinue, isFalse); // All sets played
        expect(state.allSetsPlayed, isTrue);
      },
    );

    test('Timestamps are recorded for each set', () {
      final notifier = container.read(volleyballStateProvider.notifier);

      // Set 1 finishes
      for (int i = 0; i < 25; i++) {
        notifier.addPoint('A');
      }

      final state = container.read(volleyballStateProvider);
      expect(state.sets[0].endedAt, isNotNull);
      expect(state.sets[1].startedAt, isNotNull);
    });
  });
}
