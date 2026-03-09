import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/romme_digital_engine.dart';

class RommeDigitalNotifier extends Notifier<RommeDigitalState> {
  final RommeDigitalEngine _engine = RommeDigitalEngine();
  final List<RommeDigitalState> _history = [];

  @override
  RommeDigitalState build() => const RommeDigitalState();

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

  void meldCards(List<RommeCard> cards) {
    if (state.currentPlayerId == null) return;
    _pushState();
    state = _engine
        .meldCards(state, state.currentPlayerId!, cards)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void discardCard(RommeCard card) {
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
    state = const RommeDigitalState();
  }
}

final rommeDigitalProvider =
    NotifierProvider<RommeDigitalNotifier, RommeDigitalState>(
      RommeDigitalNotifier.new,
    );
