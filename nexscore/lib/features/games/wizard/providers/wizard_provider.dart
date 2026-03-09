import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wizard_models.dart';

class WizardGameStateNotifier extends Notifier<WizardGameState> {
  final List<WizardGameState> _history = [];

  @override
  WizardGameState build() => const WizardGameState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 20) _history.removeAt(0);
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void updateState(WizardGameState newState) {
    _pushState();
    state = newState.copyWith(
      canUndo: _history.isNotEmpty,
      startedAt: state.startedAt ?? DateTime.now(),
    );
  }

  void addRound(WizardRound round) {
    _pushState();
    state = state.copyWith(
      rounds: [...state.rounds, round],
      canUndo: _history.isNotEmpty,
      startedAt: state.startedAt ?? DateTime.now(),
    );
  }

  void resetGame() {
    _history.clear();
    state = const WizardGameState();
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(
      endedAt: DateTime.now(),
      canUndo: _history.isNotEmpty,
    );
  }
}

final wizardStateProvider =
    NotifierProvider<WizardGameStateNotifier, WizardGameState>(
      WizardGameStateNotifier.new,
    );
