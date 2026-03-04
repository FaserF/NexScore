import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/wizard/models/wizard_models.dart';

void main() {
  group('Wizard Models', () {
    test('Standard scoring: correct bid gives +20 + tricks×10', () {
      final rounds = [
        WizardRound(
          roundIndex: 1,
          bids: {'p1': 3, 'p2': 1},
          tricks: {'p1': 3, 'p2': 0},
        ),
      ];
      expect(WizardGameState.calculatePlayerScore('p1', rounds), 50); // 20+30
      expect(
        WizardGameState.calculatePlayerScore('p2', rounds),
        -10,
      ); // -(1×10)
    });

    test('Lenient scoring: wrong bid offsets tricks', () {
      final rounds = [
        WizardRound(
          roundIndex: 1,
          bids: {'p1': 3, 'p2': 0},
          tricks: {'p1': 3, 'p2': 1},
        ),
      ];
      expect(
        WizardGameState.calculatePlayerScore('p1', rounds, lenient: true),
        50,
      );
      // p2: (1×10) - (1×10) = 0
      expect(
        WizardGameState.calculatePlayerScore('p2', rounds, lenient: true),
        0,
      );
    });

    test('Extreme scoring: correct bid gives +30 + tricks×10', () {
      final rounds = [
        WizardRound(roundIndex: 1, bids: {'p1': 2}, tricks: {'p1': 2}),
      ];
      // 30 + 2*10 = 50
      expect(
        WizardGameState.calculatePlayerScore('p1', rounds, extreme: true),
        50,
      );
    });

    test('Extreme scoring: wrong bid gives double penalty', () {
      final rounds = [
        WizardRound(roundIndex: 1, bids: {'p1': 3}, tricks: {'p1': 1}),
      ];
      // diff=2, extreme: -(2×20) = -40
      expect(
        WizardGameState.calculatePlayerScore('p1', rounds, extreme: true),
        -40,
      );
    });

    test('Returns 0 for player not found in round', () {
      final rounds = [WizardRound(roundIndex: 1, bids: {}, tricks: {})];
      expect(WizardGameState.calculatePlayerScore('ghost', rounds), 0);
    });

    test('Bid of 0 tricks = success: +20', () {
      final rounds = [
        WizardRound(roundIndex: 1, bids: {'p1': 0}, tricks: {'p1': 0}),
      ];
      expect(WizardGameState.calculatePlayerScore('p1', rounds), 20);
    });

    test('WizardRound serialization round-trips correctly', () {
      final round = WizardRound(
        roundIndex: 3,
        bids: {'p1': 2},
        tricks: {'p1': 2},
      );
      final restored = WizardRound.fromJson(round.toJson());
      expect(restored.roundIndex, 3);
      expect(restored.bids['p1'], 2);
    });

    test('WizardGameState serialization preserves scoringVariant', () {
      final state = WizardGameState(
        rounds: [
          WizardRound(roundIndex: 1, bids: {'p1': 1}, tricks: {'p1': 1}),
        ],
        scoringVariant: WizardScoringVariant.extreme,
        ruleSticheDuertenNichtAufgehen: true,
      );
      final restored = WizardGameState.fromJson(state.toJson());
      expect(restored.scoringVariant, WizardScoringVariant.extreme);
      expect(restored.ruleSticheDuertenNichtAufgehen, true);
    });

    test('WizardGameState isLenientScoring getter works correctly', () {
      final state = WizardGameState(
        scoringVariant: WizardScoringVariant.lenient,
      );
      expect(state.isLenientScoring, true);
      final standard = WizardGameState(
        scoringVariant: WizardScoringVariant.standard,
      );
      expect(standard.isLenientScoring, false);
    });
  });
}
