import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/schafkopf_digital/models/bavarian_card_models.dart';
import 'package:nexscore/features/games/schafkopf_digital/models/schafkopf_digital_engine.dart';
import 'package:nexscore/features/games/schafkopf_digital/models/schafkopf_digital_state.dart';

void main() {
  late SchafkopfDigitalEngine engine;

  setUp(() {
    engine = SchafkopfDigitalEngine();
  });

  group('SchafkopfDigitalEngine - Initialization & Dealing', () {
    test('initializeGame sets up 4 players', () {
      final state = engine.initializeGame(['p1', 'p2', 'p3', 'p4']);
      expect(state.playerOrder.length, 4);
      expect(state.roundNumber, 1);
      expect(state.phase, SchafkopfDigitalPhase.gameSelect);
    });

    test('dealRound deals 8 cards to each player', () {
      var state = engine.initializeGame(['p1', 'p2', 'p3', 'p4']);
      state = engine.dealRound(state);
      expect(state.hands['p1']!.length, 8);
      expect(state.hands['p2']!.length, 8);
      expect(state.hands['p3']!.length, 8);
      expect(state.hands['p4']!.length, 8);
      expect(state.phase, SchafkopfDigitalPhase.gameSelect);
    });
  });

  group('SchafkopfDigitalEngine - Selecting & Playing Game', () {
    test('selectGame Sauspiel starts trick play and identifies partner', () {
      var state = engine.initializeGame(['p1', 'p2', 'p3', 'p4']);
      state = engine.dealRound(state);

      // Force called Ace into p3's hand to verify partner detection
      final grasAce = const BavarianCard(id: 'gras_ass', suit: BavarianSuit.gras, rank: BavarianRank.ass);
      state = state.copyWith(
        hands: {
          'p1': state.hands['p1']!,
          'p2': state.hands['p2']!,
          'p3': [grasAce, ...state.hands['p3']!.sublist(1)],
          'p4': state.hands['p4']!,
        }
      );

      state = engine.selectGame(state, 'p1', SchafkopfDigitalGameType.sauspiel, calledSuit: BavarianSuit.gras);
      expect(state.gameType, SchafkopfDigitalGameType.sauspiel);
      expect(state.activePlayerId, 'p1');
      expect(state.partnerPlayerId, 'p3'); // Partner is holding the Ace
      expect(state.phase, SchafkopfDigitalPhase.playing);
    });
  });
}
