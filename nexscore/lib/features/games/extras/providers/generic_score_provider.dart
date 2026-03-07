import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/generic_score_models.dart';

final genericScoreProvider =
    StateNotifierProvider<GenericScoreNotifier, GenericScoreState>((ref) {
      final activePlayers = ref.watch(activePlayersProvider);
      return GenericScoreNotifier(activePlayers.map((p) => p.id).toList());
    });

class GenericScoreNotifier extends StateNotifier<GenericScoreState> {
  GenericScoreNotifier(List<String> playerIds)
    : super(GenericScoreState(playerIds: playerIds)) {
    if (playerIds.isNotEmpty && state.rounds.isEmpty) {
      addRound();
    }
  }

  void addRound() {
    final newRound = List<int>.filled(state.playerIds.length, 0);
    state = state.copyWith(rounds: [...state.rounds, newRound]);
  }

  void removeRound(int index) {
    if (state.rounds.length <= 1) return;
    final newRounds = List<List<int>>.from(state.rounds)..removeAt(index);
    state = state.copyWith(rounds: newRounds);
    _updateTotals();
  }

  void updateScore(int roundIndex, int playerIndex, int score) {
    final newRounds = List<List<int>>.from(state.rounds);
    final newRound = List<int>.from(newRounds[roundIndex]);
    newRound[playerIndex] = score;
    newRounds[roundIndex] = newRound;

    state = state.copyWith(rounds: newRounds);
    _updateTotals();
  }

  void _updateTotals() {
    final totals = <String, int>{};
    for (var i = 0; i < state.playerIds.length; i++) {
      var sum = 0;
      for (final round in state.rounds) {
        sum += round[i];
      }
      totals[state.playerIds[i]] = sum;
    }
    state = state.copyWith(playerTotals: totals);
  }

  void reset() {
    state = GenericScoreState(playerIds: state.playerIds);
    addRound();
  }
}
