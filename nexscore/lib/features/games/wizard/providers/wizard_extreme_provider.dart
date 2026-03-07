import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wizard_extreme_models.dart';

class WizardExtremeStateNotifier extends Notifier<WizardExtremeGameState> {
  @override
  WizardExtremeGameState build() => const WizardExtremeGameState();

  void addRound(Map<String, WizardExtremePlayerRound> round) {
    state = WizardExtremeGameState(rounds: [...state.rounds, round]);
  }

  void updateRound(int index, Map<String, WizardExtremePlayerRound> round) {
    final newRounds = List<Map<String, WizardExtremePlayerRound>>.from(
      state.rounds,
    );
    newRounds[index] = round;
    state = WizardExtremeGameState(rounds: newRounds);
  }

  void removeLastRound() {
    if (state.rounds.isEmpty) return;
    state = WizardExtremeGameState(
      rounds: state.rounds.sublist(0, state.rounds.length - 1),
    );
  }

  void resetGame() {
    state = const WizardExtremeGameState();
  }
}

final wizardExtremeStateProvider =
    NotifierProvider<WizardExtremeStateNotifier, WizardExtremeGameState>(
      WizardExtremeStateNotifier.new,
    );
