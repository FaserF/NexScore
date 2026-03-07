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

  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
    }
  }

  void updateState(WizardGameState newState) {
    _pushState();
    state = newState;
  }

  void addRound(WizardRound round) {
    _pushState();
    state = state.copyWith(rounds: [...state.rounds, round]);
  }

  void resetGame() {
    _pushState();
    state = const WizardGameState();
  }
}

final wizardStateProvider =
    NotifierProvider<WizardGameStateNotifier, WizardGameState>(
      WizardGameStateNotifier.new,
    );
