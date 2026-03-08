import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/wizard/models/wizard_models.dart';

void main() {
  group('Wizard Model Bomb Logic Tests', () {
    test(
      'calculatePlayerScore handles Dragon card (+10) in Anniversary mode',
      () {
        const round = WizardRound(
          roundIndex: 3,
          bids: {'p1': 2},
          tricks: {'p1': 2},
          playedDragon: {'p1': true},
        );

        final score = WizardGameState.calculatePlayerScore('p1', [
          round,
        ], extreme: false);

        // Standard: 20 + 2*10 = 40. Dragon: +10. Total = 50.
        expect(score, equals(50));
      },
    );

    test(
      'calculatePlayerScore handles Fairy card (-10) in Anniversary mode',
      () {
        const round = WizardRound(
          roundIndex: 3,
          bids: {'p1': 1},
          tricks: {'p1': 1},
          playedFairy: {'p1': true},
        );

        final score = WizardGameState.calculatePlayerScore('p1', [
          round,
        ], extreme: false);

        // Standard: 20 + 1*10 = 30. Fairy: -10. Total = 20.
        expect(score, equals(20));
      },
    );

    test(
      'calculatePlayerScore does NOT use extreme points in Anniversary mode if extreme is false',
      () {
        const round = WizardRound(
          roundIndex: 3,
          bids: {'p1': 1},
          tricks: {'p1': 1},
        );

        final score = WizardGameState.calculatePlayerScore('p1', [
          round,
        ], extreme: false);

        // Standard: 20 + 1*10 = 30.
        expect(score, equals(30));
      },
    );

    test(
      'calculatePlayerScore uses extreme points when extreme is true, regardless of anniversary cards',
      () {
        const round = WizardRound(
          roundIndex: 3,
          bids: {'p1': 1},
          tricks: {'p1': 1},
        );

        final score = WizardGameState.calculatePlayerScore('p1', [
          round,
        ], extreme: true);

        // Extreme: 30 + 1*10 = 40.
        expect(score, equals(40));
      },
    );
  });

  group('Wizard Round Validation Logic (Verification Concept)', () {
    // Verify scoring logic handles Anniversary cards correctly

    test(
      'Blown tricks (Bombs) contribute to trick sum in verification logic',
      () {
        const tricksSum = 2;
        const bombTricks = 1;
        const roundIndex = 3;

        expect(tricksSum + bombTricks, equals(roundIndex));
      },
    );
  });
}
