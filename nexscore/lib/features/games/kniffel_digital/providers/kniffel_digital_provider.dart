import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kniffel_digital_engine.dart';

class KniffelDigitalNotifier extends Notifier<KniffelDigitalState> {
  final KniffelDigitalEngine _engine = KniffelDigitalEngine();
  final List<KniffelDigitalState> _history = [];

  @override
  KniffelDigitalState build() => const KniffelDigitalState();

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
    if (state.phase != KniffelDigitalPhase.rolling &&
        state.phase != KniffelDigitalPhase.scoring) {
      return;
    }
    if (state.rollsLeft <= 0) return;
    _pushState();
    state = _engine.rollDice(state).copyWith(canUndo: _history.isNotEmpty);
  }

  void toggleHold(int index) {
    _pushState();
    state = _engine
        .toggleHold(state, index)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  void scoreCategory(KniffelCategory category) {
    if (state.phase != KniffelDigitalPhase.scoring) return;
    _pushState();
    state = _engine
        .scoreCategory(state, category)
        .copyWith(canUndo: _history.isNotEmpty);
    if (state.phase == KniffelDigitalPhase.finished) {
      state = state.copyWith(endedAt: DateTime.now());
    }
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  int calculateScore(KniffelCategory category) {
    return _engine.calculateScore(state.dice, category);
  }

  List<KniffelCategory> getAvailableCategories() {
    return _engine.getAvailableCategories(state, state.currentPlayerId!);
  }

  void resetGame() {
    _history.clear();
    state = const KniffelDigitalState();
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(
      phase: KniffelDigitalPhase.finished,
      endedAt: DateTime.now(),
      canUndo: _history.isNotEmpty,
    );
  }
}

final kniffelDigitalProvider =
    NotifierProvider<KniffelDigitalNotifier, KniffelDigitalState>(
      KniffelDigitalNotifier.new,
    );
