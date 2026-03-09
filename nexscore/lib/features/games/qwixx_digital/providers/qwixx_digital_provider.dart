import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qwixx_digital_engine.dart';

class QwixxDigitalNotifier extends Notifier<QwixxDigitalState> {
  final QwixxDigitalEngine _engine = QwixxDigitalEngine();
  final List<QwixxDigitalState> _history = [];

  @override
  QwixxDigitalState build() => const QwixxDigitalState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 30) _history.removeAt(0);
  }

  void startGame(List<String> playerIds) {
    _pushState();
    state = _engine
        .initializeGame(playerIds)
        .copyWith(startedAt: DateTime.now(), canUndo: _history.isNotEmpty);
  }

  void rollDice() {
    if (state.phase != QwixxDigitalPhase.rolling) return;
    _pushState();
    state = _engine.rollDice(state).copyWith(canUndo: _history.isNotEmpty);
  }

  void crossWhiteSum(String playerId, QwixxColor color) {
    _pushState();
    state = _engine
        .crossWhiteSum(state, playerId, color)
        .copyWith(
          phase: QwixxDigitalPhase.colorChoice,
          canUndo: _history.isNotEmpty,
        );
  }

  void crossColorSum(String playerId, QwixxColor color) {
    _pushState();
    state = _engine
        .crossColorSum(state, playerId, color)
        .copyWith(
          phase: QwixxDigitalPhase.otherPlayers,
          canUndo: _history.isNotEmpty,
        );
  }

  void skipPhase() {
    _pushState();
    state = _engine.skipPhase(state).copyWith(canUndo: _history.isNotEmpty);
  }

  void addPenalty(String playerId) {
    _pushState();
    state = _engine
        .addPenalty(state, playerId)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void endRound() {
    _pushState();
    state = _engine.endRound(state).copyWith(canUndo: _history.isNotEmpty);
    if (state.phase == QwixxDigitalPhase.finished) {
      state = state.copyWith(endedAt: DateTime.now());
    }
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void resetGame() {
    _history.clear();
    state = const QwixxDigitalState();
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(
      phase: QwixxDigitalPhase.finished,
      endedAt: DateTime.now(),
      canUndo: _history.isNotEmpty,
    );
  }
}

final qwixxDigitalProvider =
    NotifierProvider<QwixxDigitalNotifier, QwixxDigitalState>(
      QwixxDigitalNotifier.new,
    );
