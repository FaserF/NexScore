import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/extras/models/phase10_models.dart';

void main() {
  group('Phase 10 Models – Phase10Phase', () {
    test('Phase10Phase properties', () {
      const p = Phase10Phase(number: 1, description: '2 sets of 3');
      expect(p.number, 1);
      expect(p.title, 'Phase 1');
      expect(p.description, '2 sets of 3');
    });

    test('Phase10Phase.values returns original phases', () {
      final phases = Phase10Phase.values;
      expect(phases.length, 10);
      expect(phases[0].description, '2 sets of 3');
    });
  });

  group('Phase 10 Models – Phase10PlayerState', () {
    test('initial state', () {
      const state = Phase10PlayerState();
      expect(state.currentPhase, 1);
      expect(state.totalScore, 0);
      expect(state.completedPhases, isEmpty);
      expect(state.hasCompletedAllPhases, isFalse);
    });

    test('hasCompletedAllPhases works', () {
      final state = Phase10PlayerState(
        completedPhases: {1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
      );
      expect(state.hasCompletedAllPhases, isTrue);
    });

    test('serialization round-trips', () {
      final state = Phase10PlayerState(
        currentPhase: 5,
        totalScore: 150,
        completedPhases: {1, 2, 3},
      );
      final json = state.toJson();
      final restored = Phase10PlayerState.fromJson(json);
      expect(restored.currentPhase, 5);
      expect(restored.totalScore, 150);
      expect(restored.completedPhases, {1, 2, 3});
    });
  });

  group('Phase 10 Models – Phase10GameState', () {
    test('initial state variant is original', () {
      const gs = Phase10GameState();
      expect(gs.variant, Phase10Variant.original);
      expect(gs.activePhases.length, 10);
      expect(gs.activePhases[0].description, '2 sets of 3');
    });

    test('masters variant uses masters phases', () {
      const gs = Phase10GameState(variant: Phase10Variant.masters);
      expect(gs.activePhases[0].description, '4 Pairs');
    });

    test('getLeaders sorts correctly', () {
      final gs = Phase10GameState(
        variant: Phase10Variant.original,
        playerStates: {
          'p1': const Phase10PlayerState(currentPhase: 3, totalScore: 50),
          'p2': const Phase10PlayerState(currentPhase: 3, totalScore: 20),
          'p3': const Phase10PlayerState(currentPhase: 5, totalScore: 100),
        },
      );
      final leaders = gs.getLeaders();
      expect(leaders[0], 'p3'); // Highest phase
      expect(leaders[1], 'p2'); // Phase 3, lower score
      expect(leaders[2], 'p1'); // Phase 3, higher score
    });

    test('serialization round-trips', () {
      final gs = Phase10GameState(
        variant: Phase10Variant.masters,
        playerStates: {
          'p1': const Phase10PlayerState(currentPhase: 1, totalScore: 0),
        },
      );
      final json = gs.toJson();
      final restored = Phase10GameState.fromJson(json);
      expect(restored.variant, Phase10Variant.masters);
      expect(restored.playerStates.containsKey('p1'), isTrue);
    });
  });
}
