import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/phase10_digital_engine.dart';

class Phase10DigitalNotifier extends Notifier<Phase10DigitalState> {
  final Phase10DigitalEngine _engine = Phase10DigitalEngine();
  final List<Phase10DigitalState> _history = [];

  @override
  Phase10DigitalState build() => const Phase10DigitalState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 20) _history.removeAt(0);
  }

  void startGame(List<String> playerIds) {
    _pushState();
    var newState = _engine.initializeGame(playerIds);
    newState = _engine.startGame(newState);
    state = newState.copyWith(canUndo: _history.isNotEmpty);
  }

  void drawFromPile() {
    if (state.currentPlayerId == null) return;
    _pushState();
    state = _engine
        .drawFromPile(state, state.currentPlayerId!)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void drawFromDiscard() {
    if (state.currentPlayerId == null) return;
    _pushState();
    state = _engine
        .drawFromDiscard(state, state.currentPlayerId!)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void layPhase(List<Phase10Card> cards) {
    if (state.currentPlayerId == null) return;
    _pushState();
    state = _engine
        .layPhase(state, state.currentPlayerId!, cards)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void discardCard(Phase10Card card) {
    if (state.currentPlayerId == null) return;
    _pushState();
    state = _engine
        .discardCard(state, state.currentPlayerId!, card)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void nextRound() {
    _pushState();
    state = _engine
        .startNextRound(state)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void resetGame() {
    _history.clear();
    state = const Phase10DigitalState();
  }
}

final phase10DigitalProvider =
    NotifierProvider<Phase10DigitalNotifier, Phase10DigitalState>(
      Phase10DigitalNotifier.new,
    );
