import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/extras/models/romme_models.dart';

void main() {
  group('Rommé Models – getPlayerScore', () {
    final rounds = [
      RommeRound(
        roundIndex: 1,
        penaltyPoints: {'p1': 10, 'p2': 0, 'p3': 25},
        winnerId: 'p2',
      ),
      RommeRound(
        roundIndex: 2,
        penaltyPoints: {'p1': 0, 'p2': 15, 'p3': 10},
        winnerId: 'p1',
      ),
    ];
    final state = RommeGameState(rounds: rounds);

    test('accumulates penalty points across rounds', () {
      expect(state.getPlayerScore('p1'), 10); // 10+0
      expect(state.getPlayerScore('p2'), 15); // 0+15
      expect(state.getPlayerScore('p3'), 35); // 25+10
    });

    test('returns 0 for a player not in any round', () {
      expect(state.getPlayerScore('unknown'), 0);
    });
  });

  group('Rommé Models – getLeaders', () {
    test('sorts by lowest total score ascending', () {
      final rounds = [
        RommeRound(
          roundIndex: 1,
          penaltyPoints: {'p1': 10, 'p2': 0, 'p3': 25},
          winnerId: 'p2',
        ),
        RommeRound(
          roundIndex: 2,
          penaltyPoints: {'p1': 0, 'p2': 15, 'p3': 10},
          winnerId: 'p1',
        ),
      ];
      final state = RommeGameState(rounds: rounds);

      final leaders = state.getLeaders(['p1', 'p2', 'p3']);
      // p1=10, p2=15, p3=35 → p1 wins
      expect(leaders[0], 'p1');
      expect(leaders[1], 'p2');
      expect(leaders[2], 'p3');
    });

    test('returns empty list when no rounds', () {
      const state = RommeGameState();
      expect(state.getLeaders(['p1', 'p2']), isEmpty);
    });

    test('handles tie correctly (stable sort order)', () {
      final rounds = [
        RommeRound(
          roundIndex: 1,
          penaltyPoints: {'p1': 10, 'p2': 10},
          winnerId: 'p3',
        ),
      ];
      final state = RommeGameState(rounds: rounds);
      final leaders = state.getLeaders(['p1', 'p2']);
      expect(leaders.length, 2);
      expect(leaders.contains('p1'), isTrue);
      expect(leaders.contains('p2'), isTrue);
    });
  });

  group('Rommé Models – Variants', () {
    test('Hand-Romme doubling settings', () {
      const state = RommeGameState(doubleOnHandRomme: true);
      // Doubling is handled in UI, but we can test if settings persist
      expect(state.doubleOnHandRomme, isTrue);
      expect(state.firstMeldPoints, 40);
    });
  });

  group('Rommé Models – serialization', () {
    test(
      'RommeRound serializes and deserializes with winner and Hand-Romme',
      () {
        const round = RommeRound(
          roundIndex: 5,
          penaltyPoints: {'p1': 30, 'p2': 0},
          winnerId: 'p2',
          isHandRomme: true,
        );
        final json = round.toJson();
        final restored = RommeRound.fromJson(json);
        expect(restored.roundIndex, 5);
        expect(restored.winnerId, 'p2');
        expect(restored.isHandRomme, isTrue);
        expect(restored.penaltyPoints['p1'], 30);
      },
    );

    test('RommeGameState serializes variants', () {
      const state = RommeGameState(
        firstMeldPoints: 30,
        doubleOnHandRomme: false,
        rounds: [
          RommeRound(roundIndex: 1, penaltyPoints: {'p1': 10}, winnerId: 'p2'),
        ],
      );
      final json = state.toJson();
      final restored = RommeGameState.fromJson(json);
      expect(restored.firstMeldPoints, 30);
      expect(restored.doubleOnHandRomme, isFalse);
      expect(restored.rounds.length, 1);
    });
  });
}
