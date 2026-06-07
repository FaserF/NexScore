import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/phase10_digital/models/phase10_digital_engine.dart';

void main() {
  late Phase10DigitalEngine engine;

  setUp(() {
    engine = Phase10DigitalEngine();
  });

  group('Phase10DigitalEngine - Initialization & Dealing', () {
    test('initializeGame sets up initial parameters', () {
      final state = engine.initializeGame(['p1', 'p2']);
      expect(state.playerOrder, ['p1', 'p2']);
      expect(state.roundNumber, 1);
      expect(state.phase, Phase10DigitalPhase.setup);
    });

    test('dealRound distributes 10 cards per player and sets draw/discard piles', () {
      var state = engine.initializeGame(['p1', 'p2']);
      state = engine.dealRound(state);
      expect(state.playerStates['p1']!.hand.length, 10);
      expect(state.playerStates['p2']!.hand.length, 10);
      expect(state.drawPile.isNotEmpty, true);
      expect(state.discardPile.length, 1);
      expect(state.phase, Phase10DigitalPhase.playing);
    });
  });

  group('Phase10DigitalEngine - Draws & Discard Flow', () {
    test('drawFromPile updates player hand and reduces draw pile', () {
      var state = engine.initializeGame(['p1']);
      state = engine.dealRound(state);
      final initialHandLen = state.playerStates['p1']!.hand.length;

      state = engine.drawFromPile(state, 'p1');
      expect(state.playerStates['p1']!.hand.length, initialHandLen + 1);
      expect(state.playerStates['p1']!.hasDrawn, true);
    });

    test('discardCard ends player turn and advances active player', () {
      var state = engine.initializeGame(['p1', 'p2']);
      state = engine.dealRound(state);
      state = engine.drawFromPile(state, 'p1');
      final discard = state.playerStates['p1']!.hand.first;

      state = engine.discardCard(state, 'p1', discard);
      expect(state.currentPlayerId, 'p2');
      expect(state.playerStates['p1']!.hasDrawn, false);
    });
  });
}
