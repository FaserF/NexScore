import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schafkopf_digital_state.dart';
import '../models/schafkopf_digital_engine.dart';
import '../models/bavarian_card_models.dart';

class SchafkopfDigitalNotifier extends Notifier<SchafkopfDigitalState> {
  final SchafkopfDigitalEngine _engine = SchafkopfDigitalEngine();
  final List<SchafkopfDigitalState> _history = [];

  @override
  SchafkopfDigitalState build() => const SchafkopfDigitalState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 30) _history.removeAt(0);
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void startGame(List<String> playerIds) {
    _pushState();
    state = _engine.initializeGame(playerIds);
    state = _engine
        .startGame(state)
        .copyWith(startedAt: DateTime.now(), canUndo: _history.isNotEmpty);
  }

  void selectGame(
    String playerId,
    SchafkopfDigitalGameType? gameType, {
    BavarianSuit? calledSuit,
  }) {
    _pushState();
    state = _engine
        .selectGame(state, playerId, gameType, calledSuit: calledSuit)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void playCard(String playerId, BavarianCard card) {
    if (state.phase != SchafkopfDigitalPhase.playing) return;
    if (state.currentPlayerId != playerId) return;
    if (!_engine.isValidPlay(state, playerId, card)) return;
    _pushState();
    state = _engine
        .playCard(state, playerId, card)
        .copyWith(canUndo: _history.isNotEmpty);

    if (state.phase == SchafkopfDigitalPhase.finished) {
      state = state.copyWith(endedAt: DateTime.now());
    }
  }

  bool isValidPlay(String playerId, BavarianCard card) {
    return _engine.isValidPlay(state, playerId, card);
  }

  void nextRound() {
    if (state.phase != SchafkopfDigitalPhase.scoring) return;
    _pushState();
    state = _engine
        .startNextRound(state)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void resetGame() {
    _history.clear();
    state = const SchafkopfDigitalState();
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(
      endedAt: DateTime.now(),
      phase: SchafkopfDigitalPhase.finished,
      canUndo: _history.isNotEmpty,
    );
  }
}

final schafkopfDigitalProvider =
    NotifierProvider<SchafkopfDigitalNotifier, SchafkopfDigitalState>(
      SchafkopfDigitalNotifier.new,
    );
