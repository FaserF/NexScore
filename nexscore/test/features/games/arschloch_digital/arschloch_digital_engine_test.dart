import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/arschloch_digital/models/arschloch_digital_engine.dart';
import 'package:nexscore/features/games/arschloch_digital/models/arschloch_digital_state.dart';
import 'package:nexscore/features/games/arschloch_digital/models/standard_card_models.dart';

void main() {
  late ArschlochDigitalEngine engine;

  setUp(() {
    engine = ArschlochDigitalEngine();
  });

  group('ArschlochDigitalEngine - Basic Flow', () {
    test('initializeGame creates initial state', () {
      final state = engine.initializeGame(['p1', 'p2', 'p3']);
      expect(state.playerOrder, ['p1', 'p2', 'p3']);
      expect(state.roundNumber, 1);
      expect(state.phase, ArschlochDigitalPhase.playing);
    });

    test('dealCards gives hands to players', () {
      var state = engine.initializeGame(['p1', 'p2', 'p3']);
      state = engine.dealCards(state);
      expect(state.currentPlayerId, 'p1');
      expect(state.playerStates['p1']!.hand.isNotEmpty, true);
    });

    test('getPlayableGroups on empty pile can play any single card or group', () {
      var state = engine.initializeGame(['p1', 'p2']);
      state = engine.dealCards(state);
      final groups = engine.getPlayableGroups(state, 'p1');
      expect(groups.isNotEmpty, true);
    });

    test('playCards updates hand and pile', () {
      var state = engine.initializeGame(['p1', 'p2']);
      state = engine.dealCards(state);
      final playerHand = state.playerStates['p1']!.hand;
      final play = [playerHand.first];

      state = engine.playCards(state, 'p1', play);
      expect(state.currentPileRank, play.first.numericRank);
      expect(state.currentPileCount, 1);
      expect(state.currentPlayerId, 'p2');
    });

    test('pass switches current player and clears pile when everyone passes', () {
      var state = engine.initializeGame(['p1', 'p2']);
      state = engine.dealCards(state);
      final card = state.playerStates['p1']!.hand.first;
      state = engine.playCards(state, 'p1', [card]);

      // p2 passes
      state = engine.pass(state, 'p2');
      expect(state.currentPile.isEmpty, true);
      expect(state.currentPileRank, 0);
    });
  });
}
