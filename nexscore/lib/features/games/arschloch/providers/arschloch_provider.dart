import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arschloch_models.dart';

class ArschlochStateNotifier extends Notifier<ArschlochGameState> {
  @override
  ArschlochGameState build() => const ArschlochGameState();

  void addRound(ArschlochRound round) {
    final totalPlayers = state.playerStates.length;
    final updatedStates = Map<String, ArschlochPlayerState>.from(
      state.playerStates,
    );

    for (final entry in round.finishOrder.entries) {
      final playerId = entry.key;
      final position = entry.value;
      final rank = ArschlochGameState.rankFromPosition(position, totalPlayers);
      final points = ArschlochGameState.pointsForRank(rank);
      final existing = updatedStates[playerId] ?? const ArschlochPlayerState();
      updatedStates[playerId] = ArschlochPlayerState(
        roundsAsPresident:
            existing.roundsAsPresident +
            (rank == ArschlochRank.president ? 1 : 0),
        roundsAsArschloch:
            existing.roundsAsArschloch +
            (rank == ArschlochRank.arschloch ? 1 : 0),
        lastRank: rank,
        points: existing.points + points,
      );
    }

    state = state.copyWith(
      playerStates: updatedStates,
      rounds: [...state.rounds, round],
    );
  }

  void updateState(ArschlochGameState newState) => state = newState;

  void initPlayers(List<String> playerIds) {
    final states = <String, ArschlochPlayerState>{
      for (final id in playerIds) id: const ArschlochPlayerState(),
    };
    state = state.copyWith(playerStates: states, rounds: const []);
  }

  void resetGame() {
    state = state.copyWith(
      rounds: const [],
      playerStates: {
        for (final id in state.playerStates.keys)
          id: const ArschlochPlayerState(),
      },
    );
  }
}

final arschlochStateProvider =
    NotifierProvider<ArschlochStateNotifier, ArschlochGameState>(
      ArschlochStateNotifier.new,
    );
