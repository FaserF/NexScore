import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schafkopf_digital_state.dart';
import '../models/schafkopf_digital_engine.dart';
import '../models/bavarian_card_models.dart';

class SchafkopfDigitalNotifier extends Notifier<SchafkopfDigitalState> {
  final SchafkopfDigitalEngine _engine = SchafkopfDigitalEngine();

  @override
  SchafkopfDigitalState build() => const SchafkopfDigitalState();

  void startGame(List<String> playerIds) {
    state = _engine.initializeGame(playerIds);
    state = _engine.startGame(state);
  }

  void selectGame(
    String playerId,
    SchafkopfDigitalGameType? gameType, {
    BavarianSuit? calledSuit,
  }) {
    state = _engine.selectGame(
      state,
      playerId,
      gameType,
      calledSuit: calledSuit,
    );
  }

  void playCard(String playerId, BavarianCard card) {
    if (state.phase != SchafkopfDigitalPhase.playing) return;
    if (state.currentPlayerId != playerId) return;
    if (!_engine.isValidPlay(state, playerId, card)) return;
    state = _engine.playCard(state, playerId, card);
  }

  bool isValidPlay(String playerId, BavarianCard card) {
    return _engine.isValidPlay(state, playerId, card);
  }

  void nextRound() {
    if (state.phase != SchafkopfDigitalPhase.scoring) return;
    state = _engine.startNextRound(state);
  }

  void resetGame() {
    state = const SchafkopfDigitalState();
  }
}

final schafkopfDigitalProvider =
    NotifierProvider<SchafkopfDigitalNotifier, SchafkopfDigitalState>(
      SchafkopfDigitalNotifier.new,
    );
