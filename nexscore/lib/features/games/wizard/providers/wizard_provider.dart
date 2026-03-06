import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wizard_models.dart';

class WizardGameStateNotifier extends Notifier<WizardGameState> {
  @override
  WizardGameState build() => const WizardGameState();

  void updateState(WizardGameState newState) => state = newState;

  void addRound(WizardRound round) {
    state = state.copyWith(rounds: [...state.rounds, round]);
  }

  void resetGame() {
    state = const WizardGameState();
  }
}

final wizardStateProvider =
    NotifierProvider<WizardGameStateNotifier, WizardGameState>(
      WizardGameStateNotifier.new,
    );
