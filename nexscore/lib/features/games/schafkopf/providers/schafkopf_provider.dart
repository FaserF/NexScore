import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schafkopf_models.dart';

class SchafkopfStateNotifier extends Notifier<SchafkopfGameState> {
  final List<SchafkopfGameState> _history = [];

  @override
  SchafkopfGameState build() => const SchafkopfGameState();

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

  void addRound(SchafkopfRound round) {
    _pushState();
    state = state.copyWith(rounds: [...state.rounds, round]);

    // Auto-decrement bock rounds if active
    if (state.bockRoundsRemaining > 0) {
      state = state.copyWith(
        bockRoundsRemaining: state.bockRoundsRemaining - 1,
      );
    }
  }

  void updateStock(double amount) {
    _pushState();
    state = state.copyWith(stock: state.stock + amount);
  }

  void setBockRounds(int count) {
    _pushState();
    state = state.copyWith(bockRoundsRemaining: count);
  }

  void removeLastRound() {
    // Deprecated in favor of generic undo() but keeping for compatibility if used
    undo();
  }

  void resetGame() {
    _pushState();
    state = const SchafkopfGameState();
  }
}

final schafkopfStateProvider =
    NotifierProvider<SchafkopfStateNotifier, SchafkopfGameState>(
      SchafkopfStateNotifier.new,
    );
