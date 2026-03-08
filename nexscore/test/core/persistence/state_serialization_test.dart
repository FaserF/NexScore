import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/wizard_digital/models/wizard_digital_state.dart';
import 'package:nexscore/features/games/kniffel_digital/models/kniffel_digital_engine.dart';
import 'package:nexscore/features/games/qwixx_digital/models/qwixx_digital_engine.dart';
import 'package:nexscore/features/games/arschloch_digital/models/arschloch_digital_state.dart';

void main() {
  group('State Serialization Tests', () {
    test('WizardDigitalState serializes correctly', () {
      final state = const WizardDigitalState(
        currentRound: 2,
        totalRounds: 10,
        playerOrder: ['p1', 'p2'],
        bids: {'p1': 1, 'p2': 0},
        tricksWon: {'p1': 1, 'p2': 0},
        totalScores: {'p1': 30, 'p2': 20},
        phase: WizardPhase.playing,
      );

      final map = state.toMap();
      final restored = WizardDigitalState.fromMap(map);

      expect(restored.currentRound, 2);
      expect(restored.totalRounds, 10);
      expect(restored.playerOrder, ['p1', 'p2']);
      expect(restored.bids['p1'], 1);
      expect(restored.tricksWon['p2'], 0);
      expect(restored.totalScores['p1'], 30);
      expect(restored.phase, WizardPhase.playing);
    });

    test('KniffelDigitalState serializes correctly', () {
      final state = KniffelDigitalState(
        playerOrder: const ['p1'],
        playerStates: {
          'p1': KniffelDigitalPlayerState(
            scores: {KniffelCategory.ones: 3, KniffelCategory.kniffel: 50},
            bonusKniffels: 1,
          ),
        },
        currentPlayerId: 'p1',
        phase: KniffelDigitalPhase.scoring,
        dice: const [2, 2, 3, 4, 5],
        held: const [true, true, false, false, false],
        rollsLeft: 1,
      );

      final map = state.toMap();
      final restored = KniffelDigitalState.fromMap(map);

      expect(restored.playerOrder, ['p1']);
      expect(restored.currentPlayerId, 'p1');
      expect(restored.phase, KniffelDigitalPhase.scoring);
      expect(restored.dice, [2, 2, 3, 4, 5]);
      expect(restored.held, [true, true, false, false, false]);
      expect(restored.rollsLeft, 1);
      expect(restored.playerStates['p1']?.scores[KniffelCategory.ones], 3);
      expect(restored.playerStates['p1']?.scores[KniffelCategory.kniffel], 50);
      expect(restored.playerStates['p1']?.bonusKniffels, 1);
    });

    test('QwixxDigitalState serializes correctly', () {
      final state = QwixxDigitalState(
        playerOrder: const ['p1'],
        playerStates: {
          'p1': QwixxDigitalPlayerState(
            rows: {
              QwixxColor.red: const QwixxRowState(
                color: QwixxColor.red,
                crossedNumbers: [2, 3],
                isLocked: false,
              ),
            },
            penalties: 1,
          ),
        },
        activePlayerId: 'p1',
        phase: QwixxDigitalPhase.colorChoice,
      );

      final map = state.toMap();
      final restored = QwixxDigitalState.fromMap(map);

      expect(restored.playerOrder, ['p1']);
      expect(restored.activePlayerId, 'p1');
      expect(restored.phase, QwixxDigitalPhase.colorChoice);
      expect(
        restored.playerStates['p1']?.rows[QwixxColor.red]?.crossedNumbers,
        [2, 3],
      );
      expect(restored.playerStates['p1']?.penalties, 1);
    });

    test('ArschlochDigitalState serializes correctly', () {
      final state = const ArschlochDigitalState(
        playerOrder: ['p1', 'p2', 'p3'],
        playerStates: {
          'p1': ArschlochDigitalPlayerState(
            currentRank: ArschlochRank.praesident,
            finishOrder: 1,
            totalPoints: 10,
          ),
        },
        phase: ArschlochDigitalPhase.playing,
        currentPlayerId: 'p2',
        roundNumber: 2,
        consecutivePasses: 1,
      );

      final map = state.toMap();
      final restored = ArschlochDigitalState.fromMap(map);

      expect(restored.playerOrder, ['p1', 'p2', 'p3']);
      expect(restored.phase, ArschlochDigitalPhase.playing);
      expect(restored.currentPlayerId, 'p2');
      expect(restored.roundNumber, 2);
      expect(restored.consecutivePasses, 1);
      expect(
        restored.playerStates['p1']?.currentRank,
        ArschlochRank.praesident,
      );
      expect(restored.playerStates['p1']?.finishOrder, 1);
      expect(restored.playerStates['p1']?.totalPoints, 10);
    });
  });
}
