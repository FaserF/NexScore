import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/extras/models/phase10_models.dart';

void main() {
  group('Phase10 Models – Phase10Phase descriptions', () {
    test('all 10 phases have non-empty title and description', () {
      for (final phase in Phase10Phase.values) {
        expect(
          phase.title,
          isNotEmpty,
          reason: '${phase.name} title should not be empty',
        );
        expect(
          phase.description,
          isNotEmpty,
          reason: '${phase.name} description should not be empty',
        );
      }
    });

    test('phase numbers are 1-indexed', () {
      expect(Phase10Phase.phase1.number, 1);
      expect(Phase10Phase.phase10.number, 10);
    });

    test('phase descriptions match official Phase 10 rules', () {
      expect(Phase10Phase.phase1.description, '2 sets of 3');
      expect(Phase10Phase.phase4.description, '1 run of 7');
      expect(Phase10Phase.phase7.description, '2 sets of 4');
      expect(Phase10Phase.phase8.description, '7 cards of one colour');
      expect(Phase10Phase.phase10.description, '1 set of 5 + 1 set of 3');
    });
  });

  group('Phase10 Models – Phase10Variant', () {
    test('all three variants exist', () {
      expect(Phase10Variant.values.length, 3);
      expect(Phase10Variant.values, contains(Phase10Variant.original));
      expect(Phase10Variant.values, contains(Phase10Variant.masters));
      expect(Phase10Variant.values, contains(Phase10Variant.duel));
    });
  });

  group('Phase10 Models – Phase10PlayerState', () {
    test('defaults to phase 1, score 0, empty completedPhases', () {
      const state = Phase10PlayerState();
      expect(state.currentPhase, 1);
      expect(state.totalScore, 0);
      expect(state.completedPhases, isEmpty);
    });

    test('hasCompletedAllPhases is false with < 10 completed', () {
      const state = Phase10PlayerState(
        completedPhases: {1, 2, 3, 4, 5, 6, 7, 8, 9},
      );
      expect(state.hasCompletedAllPhases, isFalse);
    });

    test('hasCompletedAllPhases is true with 10 completed', () {
      const state = Phase10PlayerState(
        completedPhases: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
      );
      expect(state.hasCompletedAllPhases, isTrue);
    });

    test('copyWith updates phase and score independently', () {
      const state = Phase10PlayerState(currentPhase: 3, totalScore: 50);
      final updated = state.copyWith(currentPhase: 4);
      expect(updated.currentPhase, 4);
      expect(updated.totalScore, 50); // unchanged
    });

    test('copyWith with completedPhases updates Masters tracking', () {
      const state = Phase10PlayerState(completedPhases: {1, 2, 3});
      final updated = state.copyWith(completedPhases: {1, 2, 3, 5});
      expect(updated.completedPhases, {1, 2, 3, 5});
    });

    test('serialization round-trips with completedPhases', () {
      const state = Phase10PlayerState(
        currentPhase: 6,
        totalScore: 130,
        completedPhases: {1, 3, 5},
      );
      final json = state.toJson();
      final restored = Phase10PlayerState.fromJson(json);
      expect(restored.currentPhase, 6);
      expect(restored.totalScore, 130);
      expect(restored.completedPhases, {1, 3, 5});
    });
  });

  group('Phase10 Models – Phase10GameState getLeaders', () {
    test('Original variant: sorts by currentPhase desc, score asc on tie', () {
      final state = Phase10GameState(
        playerStates: {
          'p1': const Phase10PlayerState(currentPhase: 5, totalScore: 100),
          'p2': const Phase10PlayerState(currentPhase: 5, totalScore: 50),
          'p3': const Phase10PlayerState(currentPhase: 8, totalScore: 200),
          'p4': const Phase10PlayerState(currentPhase: 2, totalScore: 0),
        },
        variant: Phase10Variant.original,
      );

      final leaders = state.getLeaders();
      expect(leaders[0], 'p3'); // highest phase
      expect(leaders[1], 'p2'); // tied phase 5, lower score wins
      expect(leaders[2], 'p1'); // tied phase 5, higher score
      expect(leaders[3], 'p4'); // lowest phase
    });

    test('Masters variant: sorts by completedPhases.length desc', () {
      final state = Phase10GameState(
        playerStates: {
          'p1': const Phase10PlayerState(
            currentPhase: 1,
            totalScore: 0,
            completedPhases: {1, 2, 3, 4, 5},
          ),
          'p2': const Phase10PlayerState(
            currentPhase: 1,
            totalScore: 0,
            completedPhases: {1, 2},
          ),
          'p3': const Phase10PlayerState(
            currentPhase: 1,
            totalScore: 0,
            completedPhases: {1, 2, 3, 4, 5, 6, 7},
          ),
        },
        variant: Phase10Variant.masters,
      );

      final leaders = state.getLeaders();
      expect(leaders[0], 'p3'); // 7 completed
      expect(leaders[1], 'p1'); // 5 completed
      expect(leaders[2], 'p2'); // 2 completed
    });

    test('returns empty for no players', () {
      const state = Phase10GameState();
      expect(state.getLeaders(), isEmpty);
    });
  });

  group('Phase10 Models – Phase10GameState serialization', () {
    test('serializes and deserializes with variant', () {
      final state = Phase10GameState(
        playerStates: {
          'p1': const Phase10PlayerState(
            currentPhase: 4,
            totalScore: 75,
            completedPhases: {1, 2, 3},
          ),
        },
        variant: Phase10Variant.masters,
      );

      final json = state.toJson();
      final restored = Phase10GameState.fromJson(json);

      expect(restored.variant, Phase10Variant.masters);
      expect(restored.playerStates['p1']!.currentPhase, 4);
      expect(restored.playerStates['p1']!.completedPhases, {1, 2, 3});
      expect(restored.playerStates['p1']!.totalScore, 75);
    });

    test('unknown variant defaults to original on fromJson', () {
      final json = {
        'playerStates': <String, dynamic>{},
        'variant': 'nonexistent',
      };
      final state = Phase10GameState.fromJson(json);
      expect(state.variant, Phase10Variant.original);
    });
  });
}
