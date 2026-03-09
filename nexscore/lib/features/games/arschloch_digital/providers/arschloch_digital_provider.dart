import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arschloch_digital_state.dart';
import '../models/arschloch_digital_engine.dart';
import '../models/standard_card_models.dart';

class ArschlochDigitalNotifier extends Notifier<ArschlochDigitalState> {
  final ArschlochDigitalEngine _engine = ArschlochDigitalEngine();
  final List<ArschlochDigitalState> _history = [];

  @override
  ArschlochDigitalState build() => const ArschlochDigitalState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 20) _history.removeAt(0);
  }

  void startGame(List<String> playerIds) {
    _pushState();
    state = _engine.initializeGame(playerIds);
    state = _engine.startGame(state);
    state = state.copyWith(
      canUndo: _history.isNotEmpty,
      startedAt: DateTime.now(),
    );
  }

  void playCards(String playerId, List<StandardCard> cards) {
    if (state.phase != ArschlochDigitalPhase.playing) return;
    if (state.currentPlayerId != playerId) return;
    _pushState();
    state = _engine.playCards(state, playerId, cards);
    state = state.copyWith(canUndo: _history.isNotEmpty);
  }

  void pass(String playerId) {
    if (state.phase != ArschlochDigitalPhase.playing) return;
    if (state.currentPlayerId != playerId) return;
    _pushState();
    state = _engine.pass(state, playerId);
    state = state.copyWith(canUndo: _history.isNotEmpty);
  }

  List<List<StandardCard>> getPlayableGroups(String playerId) {
    return _engine.getPlayableGroups(state, playerId);
  }

  void nextRound() {
    if (state.phase != ArschlochDigitalPhase.roundEnd) return;
    _pushState();
    state = _engine.startNextRound(state);
    state = state.copyWith(canUndo: _history.isNotEmpty);
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void resetGame() {
    _history.clear();
    state = const ArschlochDigitalState();
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(
      phase: ArschlochDigitalPhase.finished,
      endedAt: DateTime.now(),
      canUndo: _history.isNotEmpty,
    );
  }
}

final arschlochDigitalProvider =
    NotifierProvider<ArschlochDigitalNotifier, ArschlochDigitalState>(
      ArschlochDigitalNotifier.new,
    );
