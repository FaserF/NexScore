import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wizard_digital_state.dart';
import '../models/wizard_engine.dart';
import '../models/card_models.dart';

class WizardDigitalNotifier extends Notifier<WizardDigitalState> {
  final WizardEngine _engine = WizardEngine();

  @override
  WizardDigitalState build() => const WizardDigitalState();

  /// Start a new game with the given player IDs.
  void startGame(List<String> playerIds) {
    state = _engine.initializeGame(playerIds);
  }

  /// Place a bid for the given player.
  void placeBid(String playerId, int bid) {
    if (state.phase != WizardPhase.bidding) return;
    if (state.currentPlayerId != playerId) return;
    state = _engine.placeBid(state, playerId, bid);
  }

  /// Play a card from the player's hand into the current trick.
  void playCard(String playerId, GameCard card) {
    if (state.phase != WizardPhase.playing) return;
    if (state.currentPlayerId != playerId) return;
    if (!_engine.isValidPlay(state, playerId, card)) return;
    state = _engine.playCard(state, playerId, card);
  }

  /// Advance to the next round after viewing scores.
  void nextRound() {
    if (state.phase != WizardPhase.scoring) return;
    state = _engine.startNextRound(state);
  }

  /// Check if a specific card is a valid play.
  bool isValidPlay(String playerId, GameCard card) {
    return _engine.isValidPlay(state, playerId, card);
  }

  /// Reset the game to setup state.
  void resetGame() {
    state = const WizardDigitalState();
  }

  /// Set the trump suit (used when the trump card is a Wizard and dealer chooses).
  void setTrumpSuit(CardSuit suit) {
    state = state.copyWith(trumpSuit: suit);
  }
}

final wizardDigitalProvider =
    NotifierProvider<WizardDigitalNotifier, WizardDigitalState>(
      WizardDigitalNotifier.new,
    );
