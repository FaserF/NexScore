import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kniffel_digital_engine.dart';

class KniffelDigitalNotifier extends Notifier<KniffelDigitalState> {
  final KniffelDigitalEngine _engine = KniffelDigitalEngine();

  @override
  KniffelDigitalState build() => const KniffelDigitalState();

  void startGame(List<String> playerIds) {
    state = _engine.initializeGame(playerIds);
  }

  void rollDice() {
    if (state.phase != KniffelDigitalPhase.rolling &&
        state.phase != KniffelDigitalPhase.scoring) {
      return;
    }
    if (state.rollsLeft <= 0) return;
    state = _engine.rollDice(state);
  }

  void toggleHold(int index) {
    state = _engine.toggleHold(state, index);
  }

  void scoreCategory(KniffelCategory category) {
    if (state.phase != KniffelDigitalPhase.scoring) return;
    state = _engine.scoreCategory(state, category);
  }

  int calculateScore(KniffelCategory category) {
    return _engine.calculateScore(state.dice, category);
  }

  List<KniffelCategory> getAvailableCategories() {
    return _engine.getAvailableCategories(state, state.currentPlayerId!);
  }

  void resetGame() {
    state = const KniffelDigitalState();
  }
}

final kniffelDigitalProvider =
    NotifierProvider<KniffelDigitalNotifier, KniffelDigitalState>(
      KniffelDigitalNotifier.new,
    );
