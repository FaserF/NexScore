import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/arschloch_models.dart';

class ArschlochStateNotifier extends Notifier<ArschlochGameState> {
  final List<ArschlochGameState> _history = [];

  @override
  ArschlochGameState build() {
    return const ArschlochGameState(setupDone: true, startedAt: null);
  }

  void _pushState() {
    _history.add(state);
    if (_history.length > 30) _history.removeAt(0);
  }

  bool get canUndo => _history.isNotEmpty;

  void _ensureStarted() {
    if (state.startedAt == null) {
      state = state.copyWith(startedAt: DateTime.now());
    }
  }

  void addRound(ArschlochRound round) {
    _pushState();
    _ensureStarted();
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

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
    }
  }

  void updateState(ArschlochGameState newState) {
    _pushState();
    state = newState;
  }

  void initPlayers(List<String> playerIds) {
    _pushState();
    final states = <String, ArschlochPlayerState>{
      for (final id in playerIds) id: const ArschlochPlayerState(),
    };
    state = ArschlochGameState(
      playerStates: states,
      rounds: const [],
      startedAt: DateTime.now(),
      setupDone: true,
    );
  }

  void resetGame() {
    final playerIds = state.playerStates.keys.toList();
    initPlayers(playerIds);
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(endedAt: DateTime.now());
  }
}

final arschlochStateProvider =
    NotifierProvider<ArschlochStateNotifier, ArschlochGameState>(
      ArschlochStateNotifier.new,
    );
