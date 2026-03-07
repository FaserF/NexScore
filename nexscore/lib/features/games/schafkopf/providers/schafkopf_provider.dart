import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/schafkopf_models.dart';

class SchafkopfStateNotifier extends Notifier<SchafkopfGameState> {
  @override
  SchafkopfGameState build() => const SchafkopfGameState();

  void addRound(SchafkopfRound round) {
    state = state.copyWith(rounds: [...state.rounds, round]);

    // Auto-decrement bock rounds if active
    if (state.bockRoundsRemaining > 0) {
      state = state.copyWith(
        bockRoundsRemaining: state.bockRoundsRemaining - 1,
      );
    }
  }

  void updateStock(double amount) {
    state = state.copyWith(stock: state.stock + amount);
  }

  void setBockRounds(int count) {
    state = state.copyWith(bockRoundsRemaining: count);
  }

  void removeLastRound() {
    if (state.rounds.isNotEmpty) {
      state = state.copyWith(
        rounds: state.rounds.sublist(0, state.rounds.length - 1),
      );
    }
  }

  void resetGame() {
    state = const SchafkopfGameState();
  }
}

final schafkopfStateProvider =
    NotifierProvider<SchafkopfStateNotifier, SchafkopfGameState>(
      SchafkopfStateNotifier.new,
    );
