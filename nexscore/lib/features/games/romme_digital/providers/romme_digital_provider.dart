import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/romme_digital_engine.dart';

class RommeDigitalNotifier extends Notifier<RommeDigitalState> {
  final RommeDigitalEngine _engine = RommeDigitalEngine();

  @override
  RommeDigitalState build() => const RommeDigitalState();

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

  void meldCards(List<RommeCard> cards) {
    if (state.currentPlayerId == null) return;
    state = _engine.meldCards(state, state.currentPlayerId!, cards);
  }

  void discardCard(RommeCard card) {
    if (state.currentPlayerId == null) return;
    state = _engine.discardCard(state, state.currentPlayerId!, card);
  }

  void nextRound() {
    state = _engine.startNextRound(state);
  }

  void resetGame() {
    state = const RommeDigitalState();
  }
}

final rommeDigitalProvider =
    NotifierProvider<RommeDigitalNotifier, RommeDigitalState>(
      RommeDigitalNotifier.new,
    );
