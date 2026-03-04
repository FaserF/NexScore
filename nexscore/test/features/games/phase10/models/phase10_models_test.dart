import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/extras/models/phase10_models.dart';

void main() {
  group('Phase 10 Models', () {
    test('Phase10PlayerState serializes and deserializes correctly', () {
      const state = Phase10PlayerState(
        currentPhase: 5,
        totalScore: 30,
        completedPhases: {1, 2, 3, 4},
      );

      final json = state.toJson();
      expect(json['currentPhase'], 5);
      expect(json['totalScore'], 30);
      expect((json['completedPhases'] as List).length, 4);

      final restored = Phase10PlayerState.fromJson(json);
      expect(restored.currentPhase, 5);
      expect(restored.totalScore, 30);
      expect(restored.completedPhases, {1, 2, 3, 4});
    });

    test('Phase10PlayerState hasCompletedAllPhases is true at 10', () {
      const state = Phase10PlayerState(
        completedPhases: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
      );
      expect(state.hasCompletedAllPhases, true);
    });

    test('Phase10GameState serializes and deserializes with variant', () {
      final gameState = Phase10GameState(
        playerStates: {
          'p1': const Phase10PlayerState(currentPhase: 3, totalScore: 15),
        },
        variant: Phase10Variant.masters,
      );

      final json = gameState.toJson();
      expect(json['variant'], 'masters');

      final restored = Phase10GameState.fromJson(json);
      expect(restored.variant, Phase10Variant.masters);
      expect(restored.playerStates['p1']!.currentPhase, 3);
    });

    test(
      'getLeaders sorts by phase (highest) then score (lowest) in original mode',
      () {
        final gameState = Phase10GameState(
          playerStates: {
            'p1': const Phase10PlayerState(currentPhase: 5, totalScore: 20),
            'p2': const Phase10PlayerState(currentPhase: 7, totalScore: 10),
            'p3': const Phase10PlayerState(currentPhase: 5, totalScore: 10),
          },
        );

        final leaders = gameState.getLeaders();
        expect(leaders.first, 'p2'); // Highest phase
        expect(leaders[1], 'p3'); // Same phase as p1 but lower score
        expect(leaders.last, 'p1');
      },
    );

    test('getLeaders in masters mode sorts by completedPhases count', () {
      final gameState = Phase10GameState(
        variant: Phase10Variant.masters,
        playerStates: {
          'p1': const Phase10PlayerState(completedPhases: {1, 2, 3}),
          'p2': const Phase10PlayerState(completedPhases: {1, 2, 3, 4, 5}),
        },
      );
      final leaders = gameState.getLeaders();
      expect(leaders.first, 'p2');
    });

    test(
      'Phase10GameState fromJson falls back to original variant for unknown string',
      () {
        final json = {
          'playerStates': <String, dynamic>{},
          'variant': 'nonexistentVariant',
        };
        final state = Phase10GameState.fromJson(json);
        expect(state.variant, Phase10Variant.original);
      },
    );

    test('all Phase10Phase values have non-empty title and description', () {
      for (final phase in Phase10Phase.values) {
        expect(
          phase.title.isNotEmpty,
          true,
          reason: '${phase.name} has empty title',
        );
        expect(
          phase.description.isNotEmpty,
          true,
          reason: '${phase.name} has empty description',
        );
        expect(phase.number, phase.index + 1);
      }
    });

    test('Phase10Variant includes original, masters, and duel', () {
      final names = Phase10Variant.values.map((v) => v.name).toSet();
      expect(names, containsAll(['original', 'masters', 'duel']));
    });
  });
}
