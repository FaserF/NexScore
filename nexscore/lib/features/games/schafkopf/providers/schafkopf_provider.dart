import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schafkopf_models.dart';

class SchafkopfStateNotifier extends Notifier<SchafkopfGameState> {
  final List<SchafkopfGameState> _history = [];

  @override
  SchafkopfGameState build() {
    return const SchafkopfGameState(setupDone: true, startedAt: null);
  }

  void _pushState() {
    _history.add(state);
    if (_history.length > 30) _history.removeAt(0);
  }

  void _ensureStarted() {
    if (state.startedAt == null) {
      state = state.copyWith(startedAt: DateTime.now());
    }
  }

  void addRound(SchafkopfRound round) {
    _pushState();
    _ensureStarted();
    state = state.copyWith(
      rounds: [...state.rounds, round],
      canUndo: _history.isNotEmpty,
    );

    // Auto-decrement bock rounds if active
    if (state.bockRoundsRemaining > 0) {
      state = state.copyWith(
        bockRoundsRemaining: state.bockRoundsRemaining - 1,
      );
    }
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(
      endedAt: DateTime.now(),
      canUndo: _history.isNotEmpty,
    );
  }

  void updateStock(double amount) {
    _pushState();
    _ensureStarted();
    state = state.copyWith(
      stock: state.stock + amount,
      canUndo: _history.isNotEmpty,
    );
  }

  void setBockRounds(int count) {
    _pushState();
    _ensureStarted();
    state = state.copyWith(
      bockRoundsRemaining: count,
      canUndo: _history.isNotEmpty,
    );
  }

  void removeLastRound() {
    undo();
  }

  void resetGame() {
    _history.clear();
    state = SchafkopfGameState(
      startedAt: DateTime.now(),
      setupDone: true,
      canUndo: false,
    );
  }
}

final schafkopfStateProvider =
    NotifierProvider<SchafkopfStateNotifier, SchafkopfGameState>(
      SchafkopfStateNotifier.new,
    );
