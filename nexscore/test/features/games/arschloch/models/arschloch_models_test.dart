import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/arschloch/models/arschloch_models.dart';

void main() {
  group('Arschloch Models – rankFromPosition', () {
    test('position 1 is always President', () {
      for (final n in [3, 4, 5, 6, 7, 8]) {
        expect(
          ArschlochGameState.rankFromPosition(1, n),
          ArschlochRank.president,
        );
      }
    });

    test('position 2 is VicePresident only for 4+ players', () {
      expect(
        ArschlochGameState.rankFromPosition(2, 4),
        ArschlochRank.vicePresident,
      );
      expect(
        ArschlochGameState.rankFromPosition(2, 5),
        ArschlochRank.vicePresident,
      );
      // In a 3-player game, position 2 is last → Arschloch handled separately
    });

    test('last position is always Arschloch', () {
      for (final n in [3, 4, 5, 6]) {
        expect(
          ArschlochGameState.rankFromPosition(n, n),
          ArschlochRank.arschloch,
        );
      }
    });

    test('second-to-last is ViceArschloch for 4+ players', () {
      expect(
        ArschlochGameState.rankFromPosition(3, 4),
        ArschlochRank.viceArschloch,
      );
      expect(
        ArschlochGameState.rankFromPosition(4, 5),
        ArschlochRank.viceArschloch,
      );
    });

    test('middle positions are neutral', () {
      // 5 players: positions 3 is neutral
      expect(ArschlochGameState.rankFromPosition(3, 5), ArschlochRank.neutral);
      // 6 players: positions 3 and 4 are neutral
      expect(ArschlochGameState.rankFromPosition(3, 6), ArschlochRank.neutral);
      expect(ArschlochGameState.rankFromPosition(4, 6), ArschlochRank.neutral);
    });

    test(
      '3-player game: pos1=President, pos2=ViceArschloch, pos3=Arschloch',
      () {
        expect(
          ArschlochGameState.rankFromPosition(1, 3),
          ArschlochRank.president,
        );
        expect(
          ArschlochGameState.rankFromPosition(2, 3),
          ArschlochRank.viceArschloch,
        );
        expect(
          ArschlochGameState.rankFromPosition(3, 3),
          ArschlochRank.arschloch,
        );
      },
    );
  });

  group('Arschloch Models – pointsForRank', () {
    test('President earns +2', () {
      expect(ArschlochGameState.pointsForRank(ArschlochRank.president), 2);
    });

    test('VicePresident earns +1', () {
      expect(ArschlochGameState.pointsForRank(ArschlochRank.vicePresident), 1);
    });

    test('Neutral earns 0', () {
      expect(ArschlochGameState.pointsForRank(ArschlochRank.neutral), 0);
    });

    test('ViceArschloch earns -1', () {
      expect(ArschlochGameState.pointsForRank(ArschlochRank.viceArschloch), -1);
    });

    test('Arschloch earns -2', () {
      expect(ArschlochGameState.pointsForRank(ArschlochRank.arschloch), -2);
    });
  });

  group('Arschloch Models – cardExchangeInstructions', () {
    test('4-player game includes President ↔ Arschloch exchange only', () {
      final finishOrder = {'p1': 1, 'p2': 2, 'p3': 3, 'p4': 4};
      final names = {'p1': 'Alice', 'p2': 'Bob', 'p3': 'Carl', 'p4': 'Dave'};
      final instructions = ArschlochGameState.cardExchangeInstructions(
        finishOrder,
        names,
        4,
      );

      expect(instructions.length, 2);
      expect(instructions[0], contains('Dave')); // Arschloch gives 2 cards
      expect(instructions[0], contains('Alice')); // to President
      expect(instructions[1], contains('Alice')); // President gives back
    });

    test('5+ player game includes ViceArschloch ↔ VicePresident exchange', () {
      final finishOrder = {'p1': 1, 'p2': 2, 'p3': 3, 'p4': 4, 'p5': 5};
      final names = {'p1': 'A', 'p2': 'B', 'p3': 'C', 'p4': 'D', 'p5': 'E'};
      final instructions = ArschlochGameState.cardExchangeInstructions(
        finishOrder,
        names,
        5,
      );

      expect(instructions.length, 3);
      expect(instructions[2], contains('D')); // ViceArschloch (4th) gives 1
      expect(instructions[2], contains('B')); // to VicePresident (2nd)
    });

    test('3 players only returns 2 instructions', () {
      final finishOrder = {'p1': 1, 'p2': 2, 'p3': 3};
      final names = {'p1': 'A', 'p2': 'B', 'p3': 'C'};
      final instructions = ArschlochGameState.cardExchangeInstructions(
        finishOrder,
        names,
        3,
      );

      expect(instructions.length, 2);
    });
  });

  group('Arschloch Models – getLeaders', () {
    test('sorted by points descending, then fewest arschloch rounds', () {
      final state = ArschlochGameState(
        playerStates: {
          'p1': const ArschlochPlayerState(points: 3, roundsAsArschloch: 0),
          'p2': const ArschlochPlayerState(points: 3, roundsAsArschloch: 1),
          'p3': const ArschlochPlayerState(points: -1, roundsAsArschloch: 2),
        },
      );

      final leaders = state.getLeaders();
      expect(leaders[0], 'p1'); // 3 pts, 0 arschloch
      expect(leaders[1], 'p2'); // 3 pts, 1 arschloch
      expect(leaders[2], 'p3'); // -1 pts
    });
  });

  group('Arschloch Models – rank labels', () {
    test('German labels correct', () {
      expect(ArschlochRank.president.labelDe(), 'Präsident');
      expect(ArschlochRank.vicePresident.labelDe(), 'Vizepräsident');
      expect(ArschlochRank.neutral.labelDe(), 'Bürger');
      expect(ArschlochRank.viceArschloch.labelDe(), 'Vize-Arschloch');
      expect(ArschlochRank.arschloch.labelDe(), 'Arschloch');
    });

    test('English labels correct', () {
      expect(ArschlochRank.president.labelEn(), 'President');
      expect(ArschlochRank.vicePresident.labelEn(), 'Vice President');
      expect(ArschlochRank.neutral.labelEn(), 'Citizen');
      expect(ArschlochRank.viceArschloch.labelEn(), 'Vice Asshole');
      expect(ArschlochRank.arschloch.labelEn(), 'Asshole');
    });
  });

  group('Arschloch Models – serialization', () {
    test('ArschlochPlayerState serializes and deserializes', () {
      const state = ArschlochPlayerState(
        roundsAsPresident: 2,
        roundsAsArschloch: 1,
        lastRank: ArschlochRank.president,
        points: 3,
      );

      final json = state.toJson();
      final restored = ArschlochPlayerState.fromJson(json);

      expect(restored.roundsAsPresident, 2);
      expect(restored.roundsAsArschloch, 1);
      expect(restored.lastRank, ArschlochRank.president);
      expect(restored.points, 3);
    });

    test('ArschlochRound serializes and deserializes', () {
      const round = ArschlochRound(
        roundIndex: 3,
        finishOrder: {'p1': 1, 'p2': 2, 'p3': 3},
      );

      final json = round.toJson();
      final restored = ArschlochRound.fromJson(json);

      expect(restored.roundIndex, 3);
      expect(restored.finishOrder['p2'], 2);
    });

    test('ArschlochGameState serializes and deserializes', () {
      final state = ArschlochGameState(
        playerStates: {
          'p1': const ArschlochPlayerState(
            points: 2,
            lastRank: ArschlochRank.president,
          ),
          'p2': const ArschlochPlayerState(
            points: -2,
            lastRank: ArschlochRank.arschloch,
          ),
        },
        rounds: const [
          ArschlochRound(roundIndex: 1, finishOrder: {'p1': 1, 'p2': 2}),
        ],
        usePoints: true,
      );

      final json = state.toJson();
      final restored = ArschlochGameState.fromJson(json);

      expect(restored.rounds.length, 1);
      expect(restored.playerStates['p1']!.points, 2);
      expect(restored.playerStates['p2']!.lastRank, ArschlochRank.arschloch);
      expect(restored.usePoints, true);
    });
  });
}
