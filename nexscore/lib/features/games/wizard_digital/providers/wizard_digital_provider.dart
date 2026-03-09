import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wizard_digital_state.dart';
import '../models/wizard_engine.dart';
import '../models/card_models.dart';

class WizardDigitalNotifier extends Notifier<WizardDigitalState> {
  final WizardEngine _engine = WizardEngine();
  final List<WizardDigitalState> _history = [];

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

  @override
  WizardDigitalState build() => const WizardDigitalState();

  /// Start a new game with the given player IDs.
  void startGame(List<String> playerIds) {
    state = _engine
        .initializeGame(playerIds)
        .copyWith(startedAt: DateTime.now(), canUndo: false);
    _history.clear();
  }

  /// Place a bid for the given player.
  void placeBid(String playerId, int bid) {
    if (state.phase != WizardPhase.bidding) return;
    if (state.currentPlayerId != playerId) return;
    _pushState();
    state = _engine
        .placeBid(state, playerId, bid)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  /// Play a card from the player's hand into the current trick.
  void playCard(String playerId, GameCard card) {
    if (state.phase != WizardPhase.playing) return;
    if (state.currentPlayerId != playerId) return;
    if (!_engine.isValidPlay(state, playerId, card)) return;
    _pushState();
    state = _engine
        .playCard(state, playerId, card)
        .copyWith(canUndo: _history.isNotEmpty);
  }

  /// Advance to the next round after viewing scores.
  void nextRound() {
    if (state.phase != WizardPhase.scoring) return;
    _pushState();
    state = _engine
        .startNextRound(state)
        .copyWith(canUndo: _history.isNotEmpty);
    if (state.phase == WizardPhase.finished) {
      state = state.copyWith(endedAt: DateTime.now());
    }
  }

  /// Check if a specific card is a valid play.
  bool isValidPlay(String playerId, GameCard card) {
    return _engine.isValidPlay(state, playerId, card);
  }

  /// Reset the game to setup state.
  void resetGame() {
    _history.clear();
    state = const WizardDigitalState();
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(
      phase: WizardPhase.finished,
      endedAt: DateTime.now(),
      canUndo: _history.isNotEmpty,
    );
  }

  /// Set the trump suit (used when the trump card is a Wizard and dealer chooses).
  void setTrumpSuit(CardSuit suit) {
    _pushState();
    state = state.copyWith(trumpSuit: suit, canUndo: _history.isNotEmpty);
  }
}

final wizardDigitalProvider =
    NotifierProvider<WizardDigitalNotifier, WizardDigitalState>(
      WizardDigitalNotifier.new,
    );
