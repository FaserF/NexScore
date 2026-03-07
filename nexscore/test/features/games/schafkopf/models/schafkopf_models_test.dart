import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/schafkopf/models/schafkopf_models.dart';

void main() {
  const allPlayers = ['p1', 'p2', 'p3', 'p4'];

  group('Schafkopf Models', () {
    test(
      'calculatePayouts Sauspiel with Schneider and 2 runners (runners < 3, ignored)',
      () {
        final round = SchafkopfRound(
          roundIndex: 1,
          gameType: SchafkopfGameType.sauspiel,
          activePlayerId: 'p1',
          partnerPlayerId: 'p2',
          points: const {'p1': 95, 'p2': 0},
          runners: 2,
          schneider: true,
        );

        final payouts = round.calculatePayouts(allPlayers);

        expect(payouts['p1'], closeTo(0.20, 0.01));
        expect(payouts['p2'], closeTo(0.20, 0.01));
        expect(payouts['p3'], closeTo(-0.20, 0.01));
        expect(payouts['p4'], closeTo(-0.20, 0.01));
      },
    );

    test('calculatePayouts Sauspiel with 3 runners (counted)', () {
      final round = SchafkopfRound(
        roundIndex: 1,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: const {'p1': 95, 'p2': 0},
        runners: 3,
        schneider: false,
      );

      final payouts = round.calculatePayouts(allPlayers);

      expect(payouts['p1'], closeTo(0.40, 0.01));
      expect(payouts['p2'], closeTo(0.40, 0.01));
    });

    test('calculatePayouts Wenz (Solo variant) wins', () {
      final round = SchafkopfRound(
        roundIndex: 1,
        gameType: SchafkopfGameType.wenz,
        activePlayerId: 'p1',
        points: const {'p1': 65},
        runners: 0,
      );

      final payouts = round.calculatePayouts(allPlayers);

      expect(payouts['p1'], closeTo(0.60, 0.01));
      expect(payouts['p2'], closeTo(-0.20, 0.01));
      expect(payouts['p3'], closeTo(-0.20, 0.01));
      expect(payouts['p4'], closeTo(-0.20, 0.01));
    });

    test('calculatePayouts Solo with Schneider and Schwarz and 3 runners', () {
      final round = SchafkopfRound(
        roundIndex: 2,
        gameType: SchafkopfGameType.solo,
        activePlayerId: 'p1',
        points: const {'p1': 120},
        schneider: true,
        schwarz: true,
        runners: 3,
      );

      final payouts = round.calculatePayouts(allPlayers);

      expect(payouts['p1'], closeTo(2.10, 0.01));
      expect(payouts['p2'], closeTo(-0.70, 0.01));
    });

    test('calculatePayouts correct for Sauspiel loss', () {
      final round = SchafkopfRound(
        roundIndex: 3,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: const {'p1': 20, 'p2': 0},
      );

      final payouts = round.calculatePayouts(allPlayers);

      expect(payouts['p1'], closeTo(-0.10, 0.01));
      expect(payouts['p2'], closeTo(-0.10, 0.01));
    });

    test('calculatePayouts Tout (Solo variant) wins', () {
      final round = SchafkopfRound(
        roundIndex: 4,
        gameType: SchafkopfGameType.tout,
        activePlayerId: 'p1',
        points: const {'p1': 100},
        runners: 0,
      );

      final payouts = round.calculatePayouts(allPlayers);

      expect(payouts['p1'], closeTo(0.60, 0.01));
    });

    test('calculatePayouts Laufende only counts at exactly 3', () {
      final r2 = SchafkopfRound(
        roundIndex: 5,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: const {'p1': 65},
        runners: 2,
      );
      expect(r2.calculatePayouts(allPlayers)['p1'], closeTo(0.10, 0.01));

      final r3 = SchafkopfRound(
        roundIndex: 6,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: const {'p1': 65},
        runners: 3,
      );
      expect(r3.calculatePayouts(allPlayers)['p1'], closeTo(0.40, 0.01));
    });
  });
}
