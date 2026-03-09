import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/generic_score_models.dart';

final genericScoreProvider =
    NotifierProvider<GenericScoreNotifier, GenericScoreState>(() {
      return GenericScoreNotifier();
    });

class GenericScoreNotifier extends Notifier<GenericScoreState> {
  final List<GenericScoreState> _history = [];

  @override
  GenericScoreState build() {
    final activePlayers = ref.watch(activePlayersProvider);
    final playerIds = activePlayers.map((p) => p.id).toList();

    // Initialize with one round if empty
    return GenericScoreState(
      playerIds: playerIds,
      rounds: playerIds.isNotEmpty
          ? [List<int>.filled(playerIds.length, 0)]
          : [],
      playerTotals: {for (var id in playerIds) id: 0},
    );
  }

  void _pushState() {
    _history.add(state);
    if (_history.length > 20) _history.removeAt(0);
  }

  void addRound() {
    _pushState();
    final newRound = List<int>.filled(state.playerIds.length, 0);
    state = state.copyWith(
      rounds: [...state.rounds, newRound],
      canUndo: _history.isNotEmpty,
    );
  }

  void removeRound(int index) {
    if (state.rounds.length <= 1) return;
    _pushState();
    final newRounds = List<List<int>>.from(state.rounds)..removeAt(index);
    state = state.copyWith(rounds: newRounds, canUndo: _history.isNotEmpty);
    _updateTotals();
  }

  void updateScore(int roundIndex, int playerIndex, int score) {
    _pushState();
    final newRounds = List<List<int>>.from(state.rounds);
    final newRound = List<int>.from(newRounds[roundIndex]);
    newRound[playerIndex] = score;
    newRounds[roundIndex] = newRound;

    state = state.copyWith(rounds: newRounds, canUndo: _history.isNotEmpty);
    _updateTotals();
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
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
    _history.clear();
    final playerIds = state.playerIds;
    state = GenericScoreState(
      playerIds: playerIds,
      rounds: playerIds.isNotEmpty
          ? [List<int>.filled(playerIds.length, 0)]
          : [],
      playerTotals: {for (var id in playerIds) id: 0},
      canUndo: false,
    );
  }
}
