import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/schafkopf/models/schafkopf_models.dart';

void main() {
  // Payout formula (corrected, official Bavarian rules):
  // Sauspiel: gameValue = baseTariff (0.10). No premium.
  //   Schneider adds baseTariff, Schwarz adds baseTariff.
  //   Laufende: only if runners >= 3. Each runner adds baseTariff.
  //   Active team: each member earns +/- gameValue.
  //
  // Solo variants (Wenz, Solo, Geier, etc.):
  //   gameValue = baseTariff * 2 (double base).
  //   Schneider/Schwarz/Laufende same additions.
  //   Solo player earns/loses gameValue * 3.

  group('Schafkopf Models', () {
    test(
      'calculatePayouts Sauspiel with Schneider and 2 runners (runners < 3, ignored)',
      () {
        // 2 runners < 3 minimum, so runners are NOT counted.
        // gameValue = 0.10 + schneider(0.10) = 0.20
        final round = SchafkopfRound(
          roundIndex: 1,
          gameType: SchafkopfGameType.sauspiel,
          activePlayerId: 'p1',
          partnerPlayerId: 'p2',
          points: {'p1': 95, 'p2': 0},
          runners: 2,
          schneider: true,
        );

        final payouts = round.calculatePayouts();

        expect(payouts['p1'], closeTo(0.20, 0.01));
        expect(payouts['p2'], closeTo(0.20, 0.01));
      },
    );

    test('calculatePayouts Sauspiel with 3 runners (counted)', () {
      // gameValue = 0.10 + 3*0.10 = 0.40
      final round = SchafkopfRound(
        roundIndex: 1,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: {'p1': 95, 'p2': 0},
        runners: 3,
        schneider: false,
      );

      final payouts = round.calculatePayouts();

      expect(payouts['p1'], closeTo(0.40, 0.01));
      expect(payouts['p2'], closeTo(0.40, 0.01));
    });

    test('calculatePayouts Wenz (Solo variant) wins', () {
      // gameValue = 0.10 * 2 = 0.20. Solo earns 0.20 * 3 = 0.60
      final round = SchafkopfRound(
        roundIndex: 1,
        gameType: SchafkopfGameType.wenz,
        activePlayerId: 'p1',
        points: {'p1': 65},
        runners: 0,
      );

      final payouts = round.calculatePayouts();

      expect(payouts['p1'], closeTo(0.60, 0.01));
    });

    test('calculatePayouts Solo with Schneider and Schwarz and 3 runners', () {
      // gameValue = 0.10*2 + schneider(0.10) + schwarz(0.10) + 3*0.10 = 0.70
      // Solo player earns 0.70 * 3 = 2.10
      final round = SchafkopfRound(
        roundIndex: 2,
        gameType: SchafkopfGameType.solo,
        activePlayerId: 'p1',
        points: {'p1': 120},
        schneider: true,
        schwarz: true,
        runners: 3,
      );

      final payouts = round.calculatePayouts();

      expect(payouts['p1'], closeTo(2.10, 0.01));
    });

    test('calculatePayouts correct for Sauspiel loss', () {
      // gameValue = 0.10, team lost
      final round = SchafkopfRound(
        roundIndex: 3,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: {'p1': 20, 'p2': 0},
      );

      final payouts = round.calculatePayouts();

      expect(payouts['p1'], closeTo(-0.10, 0.01));
      expect(payouts['p2'], closeTo(-0.10, 0.01));
    });

    test('calculatePayouts Tout (Solo variant) wins', () {
      // gameValue = 0.10 * 2 = 0.20. Solo earns 0.20 * 3 = 0.60
      final round = SchafkopfRound(
        roundIndex: 4,
        gameType: SchafkopfGameType.tout,
        activePlayerId: 'p1',
        points: {'p1': 100},
        runners: 0,
      );

      final payouts = round.calculatePayouts();

      expect(payouts['p1'], closeTo(0.60, 0.01));
    });

    test('calculatePayouts Laufende only counts at exactly 3', () {
      // 2 runners = NOT counted. gameValue = 0.10
      final r2 = SchafkopfRound(
        roundIndex: 5,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: {'p1': 65},
        runners: 2,
      );
      expect(r2.calculatePayouts()['p1'], closeTo(0.10, 0.01));

      // 3 runners = counted. gameValue = 0.10 + 3*0.10 = 0.40
      final r3 = SchafkopfRound(
        roundIndex: 6,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: {'p1': 65},
        runners: 3,
      );
      expect(r3.calculatePayouts()['p1'], closeTo(0.40, 0.01));
    });
  });
}
