import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/kniffel_digital/models/kniffel_digital_engine.dart';

void main() {
  late KniffelDigitalEngine engine;

  setUp(() {
    engine = KniffelDigitalEngine();
  });

  group('KniffelDigitalEngine - Initialization', () {
    test('initializeGame sets up correct players and initial state', () {
      final state = engine.initializeGame(['p1', 'p2']);
      expect(state.playerOrder, ['p1', 'p2']);
      expect(state.currentPlayerId, 'p1');
      expect(state.rollsLeft, 3);
      expect(state.phase, KniffelDigitalPhase.rolling);
    });
  });

  group('KniffelDigitalEngine - Rolls & Holds', () {
    test('rollDice reduces rollsLeft and changes dice values', () {
      var state = engine.initializeGame(['p1']);
      state = engine.rollDice(state);
      expect(state.rollsLeft, 2);
      expect(state.phase, KniffelDigitalPhase.scoring);
    });

    test('toggleHold locks a die from being re-rolled', () {
      var state = engine.initializeGame(['p1']);
      state = engine.rollDice(state);
      final initialDieVal = state.dice[0];

      // Hold the first die
      state = engine.toggleHold(state, 0);
      expect(state.held[0], true);

      // Roll again
      state = engine.rollDice(state);
      expect(state.dice[0], initialDieVal); // First die is untouched
    });
  });

  group('KniffelDigitalEngine - Scores', () {
    test('scoreCategory advances turn and assigns points', () {
      var state = engine.initializeGame(['p1', 'p2']);
      state = engine.rollDice(state);
      state = engine.scoreCategory(state, KniffelCategory.chance);

      expect(state.playerStates['p1']!.scores[KniffelCategory.chance], isNotNull);
      expect(state.currentPlayerId, 'p2'); // Advanced to p2
      expect(state.rollsLeft, 3);
    });

    test('calculateScore calculates Kniffel and Large Straight correctly', () {
      expect(engine.calculateScore([5, 5, 5, 5, 5], KniffelCategory.kniffel), 50);
      expect(engine.calculateScore([1, 2, 3, 4, 5], KniffelCategory.largeStraight), 40);
      expect(engine.calculateScore([1, 2, 3, 4, 6], KniffelCategory.smallStraight), 30);
    });
  });
}
