import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/extras/models/darts_models.dart';

void main() {
  group('Darts Logic Tests', () {
    test('Straight start, single finish - normal scoring', () {
      var state = const DartPlayerState(
        startingScore: 301,
        startType: DartsStartType.straight,
        finishType: DartsFinishType.single,
      );

      // Round 1: 60 (20, 20, 20)
      state = state.copyWith(rounds: [
        const DartRound(throws: [
          DartThrow(score: 20),
          DartThrow(score: 20),
          DartThrow(score: 20),
        ]),
      ]);

      expect(state.currentScore, 241);
    });

    test('Double start requirement', () {
      var state = const DartPlayerState(
        startingScore: 301,
        startType: DartsStartType.double,
      );

      // Round 1: No double (20, 20, 20) -> Score should remain 301
      state = state.copyWith(rounds: [
        const DartRound(throws: [
          DartThrow(score: 20),
          DartThrow(score: 20),
          DartThrow(score: 20),
        ]),
      ]);
      expect(state.currentScore, 301);

      // Round 2: Double 20 on second throw -> (10, D20, 20) -> Score should be 301 - 40 - 20 = 241
      state = state.copyWith(rounds: [
        ...state.rounds,
        const DartRound(throws: [
          DartThrow(score: 10, multiplier: 1),
          DartThrow(score: 20, multiplier: 2),
          DartThrow(score: 20, multiplier: 1),
        ]),
      ]);
      expect(state.currentScore, 241);
    });

    test('Double finish requirement and Bust (exactly 1)', () {
      var state = const DartPlayerState(
        startingScore: 40,
        startType: DartsStartType.straight,
        finishType: DartsFinishType.double,
      );

      // Round 1: Single 20, Single 19 -> Remaining 1 -> BUST
      state = state.copyWith(rounds: [
        const DartRound(throws: [
          DartThrow(score: 20),
          DartThrow(score: 19),
        ]),
      ]);
      expect(state.currentScore, 40); // Reverts to 40 because of bust

      // Round 2: Double 20 -> FINISH
      state = state.copyWith(rounds: [
        const DartRound(throws: [
          DartThrow(score: 20, multiplier: 2),
        ]),
      ]);
      expect(state.currentScore, 0);
    });

    test('Double finish requirement - Bust (below 0)', () {
      var state = const DartPlayerState(
        startingScore: 20,
        startType: DartsStartType.straight,
        finishType: DartsFinishType.double,
      );

      // Round 1: Single 21 (impossible but for test) -> BUST
      state = state.copyWith(rounds: [
        const DartRound(throws: [
          DartThrow(score: 21),
        ]),
      ]);
      expect(state.currentScore, 20);
    });

    test('Master finish (Treble or Double)', () {
      var state = const DartPlayerState(
        startingScore: 60,
        startType: DartsStartType.straight,
        finishType: DartsFinishType.master,
      );

      // Finish with Treble 20
      state = state.copyWith(rounds: [
        const DartRound(throws: [
          DartThrow(score: 20, multiplier: 3),
        ]),
      ]);
      expect(state.currentScore, 0);

      // Reset and try with Double 30 (not possible but check multiplier)
      state = const DartPlayerState(
        startingScore: 40,
        startType: DartsStartType.straight,
        finishType: DartsFinishType.master,
      );
      state = state.copyWith(rounds: [
        const DartRound(throws: [
          DartThrow(score: 20, multiplier: 2),
        ]),
      ]);
      expect(state.currentScore, 0);
    });

    test('Bust reverts hasStarted if started in same round', () {
       var state = const DartPlayerState(
        startingScore: 301,
        startType: DartsStartType.double,
      );

      // Round 1: Double 20 (starts), then single 20, then throw that makes it 1 (Bust)
      // 301 - 40 - 20 - 240 = 1 (Bust)
      state = state.copyWith(rounds: [
        const DartRound(throws: [
          DartThrow(score: 20, multiplier: 2), // Starts
          DartThrow(score: 20),
          DartThrow(score: 240), // Bust (below 2)
        ]),
      ]);
      
      expect(state.currentScore, 301);
      
      // Next round: Single 20 should still not count because hasStarted was reverted
      state = state.copyWith(rounds: [
        ...state.rounds,
        const DartRound(throws: [
          DartThrow(score: 20),
        ]),
      ]);
      expect(state.currentScore, 301);
    });
  });
}
