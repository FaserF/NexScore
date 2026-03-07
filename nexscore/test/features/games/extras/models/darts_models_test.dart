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

    test('average is 0 when no rounds played', () {
      final state = DartPlayerState(startingScore: 501);
      expect(state.averagePerDart, 0.0);
    });

    test('serialization round-trips correctly', () {
      final state = DartPlayerState(
        startingScore: 701,
        rounds: [
          DartRound(throws: [const DartThrow(score: 100, multiplier: 1)]),
        ],
      );
      final json = state.toJson();
      final restored = DartPlayerState.fromJson(json);
      expect(restored.startingScore, 701);
      expect(restored.rounds.length, 1);
      expect(restored.rounds[0].throws[0].score, 100);
    });
  });

  group('Darts Models – DartsGameState', () {
    test('copyWith updates targetScore', () {
      const gs = DartsGameState(targetScore: 301);
      final updated = gs.copyWith(targetScore: 501);
      expect(updated.targetScore, 501);
      expect(updated.playerStates, isEmpty);
    });

    test('serialization round-trips', () {
      final gs = DartsGameState(
        targetScore: 501,
        playerStates: {
          'p1': DartPlayerState(
            startingScore: 501,
            rounds: [
              DartRound(throws: [const DartThrow(score: 60)]),
            ],
          ),
        },
      );
      final json = gs.toJson();
      final restored = DartsGameState.fromJson(json);
      expect(restored.targetScore, 501);
      expect(restored.playerStates['p1']!.currentScore, 441);
    });
  });
}
