import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/qwixx_digital/models/qwixx_digital_engine.dart';

void main() {
  late QwixxDigitalEngine engine;

  setUp(() {
    engine = QwixxDigitalEngine();
  });

  group('QwixxDigitalEngine - Basic Setup', () {
    test('initializeGame sets up rows and colors correctly', () {
      final state = engine.initializeGame(['p1', 'p2']);
      expect(state.playerOrder, ['p1', 'p2']);
      expect(state.activePlayerId, 'p1');
      expect(state.phase, QwixxDigitalPhase.rolling);

      final p1State = state.playerStates['p1']!;
      expect(p1State.rows[QwixxColor.red]!.color, QwixxColor.red);
      expect(p1State.rows[QwixxColor.red]!.crossedNumbers.isEmpty, true);
    });
  });

  group('QwixxDigitalEngine - Rolling & Scoring', () {
    test('rollDice updates whiteSum and colorSums', () {
      var state = engine.initializeGame(['p1']);
      state = engine.rollDice(state);
      expect(state.whiteDice.length, 2);
      expect(state.colorDice.length, 4);
      expect(state.whiteSum, state.whiteDice[0] + state.whiteDice[1]);
      expect(state.phase, QwixxDigitalPhase.whiteChoice);
    });

    test('crossWhiteSum adds whiteSum to the correct colored row if valid', () {
      var state = engine.initializeGame(['p1']);
      state = state.copyWith(whiteDice: [3, 4]); // whiteSum = 7
      state = engine.crossWhiteSum(state, 'p1', QwixxColor.red);

      final redRow = state.playerStates['p1']!.rows[QwixxColor.red]!;
      expect(redRow.crossedNumbers, [7]);
    });

    test('addPenalty increases player penalties', () {
      var state = engine.initializeGame(['p1']);
      state = engine.addPenalty(state, 'p1');
      expect(state.playerStates['p1']!.penalties, 1);
      expect(state.playerStates['p1']!.totalScore, -5);
    });
  });
}
