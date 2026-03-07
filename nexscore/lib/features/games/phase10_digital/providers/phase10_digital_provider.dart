import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/phase10_digital_engine.dart';

class Phase10DigitalNotifier extends Notifier<Phase10DigitalState> {
  final Phase10DigitalEngine _engine = Phase10DigitalEngine();

  @override
  Phase10DigitalState build() => const Phase10DigitalState();

  void startGame(List<String> playerIds) {
    state = _engine.initializeGame(playerIds);
    state = _engine.startGame(state);
  }

  void drawFromPile() {
    if (state.currentPlayerId == null) return;
    state = _engine.drawFromPile(state, state.currentPlayerId!);
  }

  void drawFromDiscard() {
    if (state.currentPlayerId == null) return;
    state = _engine.drawFromDiscard(state, state.currentPlayerId!);
  }

  void layPhase(List<Phase10Card> cards) {
    if (state.currentPlayerId == null) return;
    state = _engine.layPhase(state, state.currentPlayerId!, cards);
  }

  void discardCard(Phase10Card card) {
    if (state.currentPlayerId == null) return;
    state = _engine.discardCard(state, state.currentPlayerId!, card);
  }

  void nextRound() {
    state = _engine.startNextRound(state);
  }

  void resetGame() {
    state = const Phase10DigitalState();
  }
}

final phase10DigitalProvider =
    NotifierProvider<Phase10DigitalNotifier, Phase10DigitalState>(
      Phase10DigitalNotifier.new,
    );
