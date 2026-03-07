import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qwixx_digital_engine.dart';

class QwixxDigitalNotifier extends Notifier<QwixxDigitalState> {
  final QwixxDigitalEngine _engine = QwixxDigitalEngine();

  @override
  QwixxDigitalState build() => const QwixxDigitalState();

  void startGame(List<String> playerIds) {
    state = _engine.initializeGame(playerIds);
  }

  void rollDice() {
    if (state.phase != QwixxDigitalPhase.rolling) return;
    state = _engine.rollDice(state);
  }

  void crossWhiteSum(String playerId, QwixxColor color) {
    state = _engine.crossWhiteSum(state, playerId, color);
    state = state.copyWith(phase: QwixxDigitalPhase.colorChoice);
  }

  void crossColorSum(String playerId, QwixxColor color) {
    state = _engine.crossColorSum(state, playerId, color);
    state = state.copyWith(phase: QwixxDigitalPhase.otherPlayers);
  }

  void skipPhase() {
    state = _engine.skipPhase(state);
  }

  void addPenalty(String playerId) {
    state = _engine.addPenalty(state, playerId);
  }

  void endRound() {
    state = _engine.endRound(state);
  }

  void resetGame() {
    state = const QwixxDigitalState();
  }
}

final qwixxDigitalProvider =
    NotifierProvider<QwixxDigitalNotifier, QwixxDigitalState>(
      QwixxDigitalNotifier.new,
    );
