import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arschloch_digital_state.dart';
import '../models/arschloch_digital_engine.dart';
import '../models/standard_card_models.dart';

class ArschlochDigitalNotifier extends Notifier<ArschlochDigitalState> {
  final ArschlochDigitalEngine _engine = ArschlochDigitalEngine();

  @override
  ArschlochDigitalState build() => const ArschlochDigitalState();

  void startGame(List<String> playerIds) {
    state = _engine.initializeGame(playerIds);
    state = _engine.startGame(state);
  }

  void playCards(String playerId, List<StandardCard> cards) {
    if (state.phase != ArschlochDigitalPhase.playing) return;
    if (state.currentPlayerId != playerId) return;
    state = _engine.playCards(state, playerId, cards);
  }

  void pass(String playerId) {
    if (state.phase != ArschlochDigitalPhase.playing) return;
    if (state.currentPlayerId != playerId) return;
    state = _engine.pass(state, playerId);
  }

  List<List<StandardCard>> getPlayableGroups(String playerId) {
    return _engine.getPlayableGroups(state, playerId);
  }

  void nextRound() {
    if (state.phase != ArschlochDigitalPhase.roundEnd) return;
    state = _engine.startNextRound(state);
  }

  void resetGame() {
    state = const ArschlochDigitalState();
  }
}

final arschlochDigitalProvider =
    NotifierProvider<ArschlochDigitalNotifier, ArschlochDigitalState>(
      ArschlochDigitalNotifier.new,
    );
