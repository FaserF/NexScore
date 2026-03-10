import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/models/player_model.dart';
import '../models/darts_models.dart';

class DartsNotifier extends Notifier<DartsGameState> {
  final List<DartsGameState> _history = [];

  @override
  DartsGameState build() {
    final activePlayers = ref.watch(activePlayersProvider);
    final playerStates = {
      for (final p in activePlayers)
        p.id: const DartPlayerState(startingScore: 301),
    };

    return DartsGameState(
      playerStates: playerStates,
      targetScore: 301,
      startedAt: DateTime.now(),
    );
  }

  void _pushState() {
    _history.add(state);
    if (_history.length > 30) _history.removeAt(0);
  }

  void addRound(String playerId, DartRound round) {
    _pushState();
    final pState = state.playerStates[playerId]!;
    final newRounds = [...pState.rounds, round];
    final newPlayerState = pState.copyWith(rounds: newRounds);

    final newPlayerStates = Map<String, DartPlayerState>.from(state.playerStates);
    newPlayerStates[playerId] = newPlayerState;

    bool hasWinner = newPlayerStates.values.any((ps) => ps.currentScore == 0);

    state = state.copyWith(
      playerStates: newPlayerStates,
      endedAt: hasWinner ? DateTime.now() : null,
      canUndo: _history.isNotEmpty,
    );
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void resetGame() {
    _history.clear();
    final activePlayers = ref.read(activePlayersProvider);
    final playerStates = {
      for (final p in activePlayers)
        p.id: DartPlayerState(
          startingScore: state.targetScore,
          finishType: state.finishType,
          startType: state.startType,
        ),
    };

    state = DartsGameState(
      playerStates: playerStates,
      targetScore: state.targetScore,
      finishType: state.finishType,
      startType: state.startType,
      startedAt: DateTime.now(),
      canUndo: false,
    );
  }

  void updateSettings({
    int? targetScore,
    DartsFinishType? finishType,
    DartsStartType? startType,
  }) {
    _pushState();
    final newTarget = targetScore ?? state.targetScore;
    final newFinish = finishType ?? state.finishType;
    final newStart = startType ?? state.startType;

    // Reset rounds when settings change (usually done at start of game)
    final newPlayerStates = state.playerStates.map((pid, ps) {
      return MapEntry(
        pid,
        DartPlayerState(
          startingScore: newTarget,
          finishType: newFinish,
          startType: newStart,
        ),
      );
    });

    state = state.copyWith(
      targetScore: newTarget,
      finishType: newFinish,
      startType: newStart,
      playerStates: newPlayerStates,
      canUndo: _history.isNotEmpty,
    );
  }
}

final dartsStateProvider = NotifierProvider<DartsNotifier, DartsGameState>(DartsNotifier.new);

final dartsPlayersProvider = Provider<List<Player>>((ref) {
  return ref.watch(activePlayersProvider);
});
