import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/extras/models/darts_models.dart';

void main() {
  group('Darts Models – DartThrow', () {
    test('single throw total equals score', () {
      const t = DartThrow(score: 20, multiplier: 1);
      expect(t.total, 20);
    });

    test('double throw doubles score', () {
      const t = DartThrow(score: 20, multiplier: 2);
      expect(t.total, 40);
    });

    test('treble multiplier works', () {
      const t = DartThrow(score: 20, multiplier: 3);
      expect(t.total, 60);
    });

    test('serialization round-trips', () {
      const t = DartThrow(score: 16, multiplier: 2);
      final json = t.toJson();
      final restored = DartThrow.fromJson(json);
      expect(restored.score, 16);
      expect(restored.multiplier, 2);
      expect(restored.total, 32);
    });
  });

  group('Darts Models – DartRound', () {
    test('roundTotal sums all throw totals', () {
      final round = DartRound(
        throws: [
          const DartThrow(score: 20, multiplier: 3), // 60
          const DartThrow(score: 19, multiplier: 3), // 57
          const DartThrow(score: 18, multiplier: 1), // 18
        ],
      );
      expect(round.roundTotal, 135);
    });

    test('empty round total is 0', () {
      final round = DartRound();
      expect(round.roundTotal, 0);
    });
  });

  group('Darts Models – DartPlayerState bust logic', () {
    test('correct X01 subtraction without bust', () {
      final state = DartPlayerState(
        startingScore: 301,
        rounds: [
          DartRound(throws: [const DartThrow(score: 100)]), // 201
          DartRound(throws: [const DartThrow(score: 151)]), // 50
          DartRound(
            throws: [const DartThrow(score: 25, multiplier: 2)],
          ), // 0 (win on D25/Bull)
        ],
      );
      expect(state.currentScore, 0);
    });

    test('bust: score stays unchanged when would go below 0', () {
      final state = DartPlayerState(
        startingScore: 301,
        rounds: [
          DartRound(throws: [const DartThrow(score: 100)]), // 201
          DartRound(throws: [const DartThrow(score: 150)]), // 51
          DartRound(
            throws: [const DartThrow(score: 60)],
          ), // BUST (51-60<0) – stays 51
        ],
      );
      expect(state.currentScore, 51);
    });

    test('bust: score stays unchanged when would reach exactly 1', () {
      // Score = 2, tries to score 1, arrives at 1 (which is a bust – can't finish on 1)
      final state = DartPlayerState(
        startingScore: 301,
        rounds: [
          DartRound(throws: [const DartThrow(score: 299)]), // 2
          DartRound(
            throws: [const DartThrow(score: 1)],
          ), // Bust (would leave 1)
        ],
      );
      expect(state.currentScore, 2);
    });

    test('bust: reaching exactly 0 but no double is a bust', () {
      final state = DartPlayerState(
        startingScore: 301,
        rounds: [
          DartRound(
            throws: [const DartThrow(score: 301, multiplier: 1)],
          ), // Bust
        ],
      );
      expect(state.currentScore, 301);
    });

    test('501 starting score works with double finish', () {
      final state = DartPlayerState(
        startingScore: 501,
        rounds: [
          // Impossible in one round but for testing model logic:
          DartRound(
            throws: [
              const DartThrow(score: 20, multiplier: 3), // 60
              const DartThrow(score: 20, multiplier: 3), // 120
            ],
          ), // 381
          DartRound(
            throws: [const DartThrow(score: 25, multiplier: 2)],
          ), // Not zero yet, just testing rounds
        ],
      );
      expect(state.currentScore, 331);
    });

    test('average per dart calculated correctly', () {
      final state = DartPlayerState(
        startingScore: 501,
        rounds: [
          // 3 throws scoring 60 each = 180 total
          DartRound(
            throws: [
              const DartThrow(score: 20, multiplier: 3), // 60
              const DartThrow(score: 20, multiplier: 3), // 60
              const DartThrow(score: 20, multiplier: 3), // 60
            ],
          ),
        ],
      );
      // 180 scored in 3 darts → avg = 60
      expect(state.averagePerDart, closeTo(60.0, 0.01));
    });

    test('straight start works immediately', () {
      const state = DartPlayerState(
        startingScore: 301,
        startType: DartsStartType.straight,
        rounds: [
          DartRound(throws: [DartThrow(score: 20)]),
        ],
      );
      expect(state.currentScore, 281);
    });

    test('double in: score only starts after a double', () {
      const state = DartPlayerState(
        startingScore: 301,
        startType: DartsStartType.double,
        rounds: [
          DartRound(throws: [DartThrow(score: 20)]), // No start
          DartRound(
            throws: [DartThrow(score: 20, multiplier: 2)],
          ), // Starts! (40)
          DartRound(throws: [DartThrow(score: 20)]), // Counts (20)
        ],
      );
      // 301 - 40 - 20 = 241
      expect(state.currentScore, 241);
    });

    test('master in: score starts after double or treble', () {
      const state = DartPlayerState(
        startingScore: 301,
        startType: DartsStartType.master,
        rounds: [
          DartRound(throws: [DartThrow(score: 20)]), // No start
          DartRound(
            throws: [DartThrow(score: 20, multiplier: 3)],
          ), // Starts! (60)
          DartRound(throws: [DartThrow(score: 20)]), // Counts (20)
        ],
      );
      // 301 - 60 - 20 = 221
      expect(state.currentScore, 221);
    });

    test('single out: allows finishing on single', () {
      const state = DartPlayerState(
        startingScore: 20,
        finishType: DartsFinishType.single,
        rounds: [
          DartRound(throws: [DartThrow(score: 20)]),
        ],
      );
      expect(state.currentScore, 0);
    });

    test('master out: allows finishing on treble', () {
      const state = DartPlayerState(
        startingScore: 60,
        finishType: DartsFinishType.master,
        rounds: [
          DartRound(throws: [DartThrow(score: 20, multiplier: 3)]),
        ],
      );
      expect(state.currentScore, 0);
    });

    test('double in bust: reverts hasStarted flag if busted in same round', () {
      const state = DartPlayerState(
        startingScore: 301,
        startType: DartsStartType.double,
        rounds: [
          DartRound(
            throws: [
              DartThrow(score: 20, multiplier: 2), // Starts (261)
              DartThrow(
                score: 261,
              ), // Bust! (should revert to 301 and not started)
            ],
          ),
          DartRound(throws: [DartThrow(score: 20)]), // Should not count
        ],
      );
      expect(state.currentScore, 301);
    });

    test('average is 0 when no rounds played', () {
      final state = DartPlayerState(startingScore: 501);
      expect(state.averagePerDart, 0.0);
    });

    test('serialization round-trips correctly', () {
      final state = DartPlayerState(
        startingScore: 701,
        finishType: DartsFinishType.master,
        startType: DartsStartType.double,
        rounds: [
          DartRound(throws: [const DartThrow(score: 100, multiplier: 1)]),
        ],
      );
      final json = state.toJson();
      final restored = DartPlayerState.fromJson(json);
      expect(restored.startingScore, 701);
      expect(restored.finishType, DartsFinishType.master);
      expect(restored.startType, DartsStartType.double);
    });
  });

  group('Darts Models – DartsGameState', () {
    test('copyWith updates variant types', () {
      const gs = DartsGameState(
        targetScore: 301,
        finishType: DartsFinishType.double,
        startType: DartsStartType.straight,
      );
      final updated = gs.copyWith(
        targetScore: 501,
        finishType: DartsFinishType.master,
        startType: DartsStartType.double,
      );
      expect(updated.targetScore, 501);
      expect(updated.finishType, DartsFinishType.master);
      expect(updated.startType, DartsStartType.double);
    });

    test('serialization round-trips', () {
      final gs = DartsGameState(
        targetScore: 501,
        finishType: DartsFinishType.master,
        startType: DartsStartType.double,
        playerStates: {
          'p1': DartPlayerState(
            startingScore: 501,
            finishType: DartsFinishType.master,
            startType: DartsStartType.double,
            rounds: [
              DartRound(throws: [const DartThrow(score: 20, multiplier: 2)]),
            ],
          ),
        },
      );
      final json = gs.toJson();
      final restored = DartsGameState.fromJson(json);
      expect(restored.targetScore, 501);
      expect(restored.finishType, DartsFinishType.master);
      expect(restored.startType, DartsStartType.double);
      expect(restored.playerStates['p1']!.currentScore, 461);
    });
  });
}
