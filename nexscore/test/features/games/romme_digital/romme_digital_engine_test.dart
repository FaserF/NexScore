import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/romme_digital/models/romme_digital_engine.dart';

void main() {
  late RommeDigitalEngine engine;

  setUp(() {
    engine = RommeDigitalEngine();
  });

  group('RommeDigitalEngine - Initialization', () {
    test('initializeGame setup correct scores and round numbers', () {
      final state = engine.initializeGame(['p1', 'p2']);
      expect(state.playerOrder, ['p1', 'p2']);
      expect(state.roundNumber, 1);
      expect(state.phase, RommeDigitalPhase.setup);
    });

    test('dealRound deals cards and fills draw/discard piles', () {
      var state = engine.initializeGame(['p1', 'p2']);
      state = engine.dealRound(state);
      expect(state.playerStates['p1']!.hand.length, 13); // 2-3 players = 13 cards
      expect(state.playerStates['p2']!.hand.length, 13);
      expect(state.drawPile.isNotEmpty, true);
      expect(state.discardPile.length, 1);
      expect(state.phase, RommeDigitalPhase.playing);
    });
  });

  group('RommeMeld - Validation', () {
    test('isValidSet verifies duplicate suits are not allowed in sets', () {
      final card1 = const RommeCard(id: 'c1', suit: 0, rank: 5);
      final card2 = const RommeCard(id: 'c2', suit: 1, rank: 5);
      final card3 = const RommeCard(id: 'c3', suit: 2, rank: 5);
      final meld = RommeMeld(cards: [card1, card2, card3]);
      expect(meld.isValidSet, true);

      final card4 = const RommeCard(id: 'c4', suit: 0, rank: 5); // Duplicate suit
      final invalidMeld = RommeMeld(cards: [card1, card2, card4]);
      expect(invalidMeld.isValidSet, false);
    });

    test('isValidRun validates correct sequential order of cards in run', () {
      final card1 = const RommeCard(id: 'c1', suit: 0, rank: 5);
      final card2 = const RommeCard(id: 'c2', suit: 0, rank: 6);
      final card3 = const RommeCard(id: 'c3', suit: 0, rank: 7);
      final meld = RommeMeld(cards: [card1, card2, card3]);
      expect(meld.isValidRun, true);
    });
  });
}
