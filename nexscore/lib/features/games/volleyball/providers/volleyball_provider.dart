import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/volleyball_models.dart';

final volleyballStateProvider =
    NotifierProvider<VolleyballStateNotifier, VolleyballGameState>(
      VolleyballStateNotifier.new,
    );

class VolleyballStateNotifier extends Notifier<VolleyballGameState> {
  final List<VolleyballGameState> _history = [];

  @override
  VolleyballGameState build() => const VolleyballGameState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 30) _history.removeAt(0);
  }

  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
    }
  }

  void setupMatch({
    required VolleyballType type,
    required String teamA,
    required String teamB,
    required List<String> pA,
    required List<String> pB,
  }) {
    state = VolleyballGameState(
      type: type,
      teamAName: teamA,
      teamBName: teamB,
      teamAPlayers: pA,
      teamBPlayers: pB,
      rules: type == VolleyballType.indoor
          ? VolleyballRules.indoor()
          : VolleyballRules.beach(),
      sets: const [VolleyballSet()],
    );
    _history.clear();
  }

  void addPoint(String team) {
    if (state.matchFinished) return;
    _pushState();

    final currentSet = state.currentSet;
    int scoreA = currentSet.scoreA;
    int scoreB = currentSet.scoreB;

    if (team == 'A') {
      scoreA++;
      state = state.copyWith(server: 'A');
    } else {
      scoreB++;
      state = state.copyWith(server: 'B');
    }

    final updatedSet = currentSet.copyWith(scoreA: scoreA, scoreB: scoreB);
    _updateSetAndCheckFinished(updatedSet);
  }

  void removePoint(String team) {
    if (state.matchFinished) return;
    final currentSet = state.currentSet;
    if (team == 'A' && currentSet.scoreA == 0) return;
    if (team == 'B' && currentSet.scoreB == 0) return;

    _pushState();
    if (team == 'A') {
      state = state.copyWith(
        sets: _updateSetsAt(
          state.currentSetIndex,
          currentSet.copyWith(scoreA: currentSet.scoreA - 1),
        ),
      );
    } else {
      state = state.copyWith(
        sets: _updateSetsAt(
          state.currentSetIndex,
          currentSet.copyWith(scoreB: currentSet.scoreB - 1),
        ),
      );
    }
  }

  void takeTimeout(String team) {
    if (state.matchFinished || state.currentSet.isFinished) return;

    final currentSet = state.currentSet;
    if (team == 'A') {
      if (currentSet.timeoutsTakenA >= state.rules.timeoutsPerSet) return;
      _pushState();
      state = state.copyWith(
        sets: _updateSetsAt(
          state.currentSetIndex,
          currentSet.copyWith(timeoutsTakenA: currentSet.timeoutsTakenA + 1),
        ),
      );
    } else {
      if (currentSet.timeoutsTakenB >= state.rules.timeoutsPerSet) return;
      _pushState();
      state = state.copyWith(
        sets: _updateSetsAt(
          state.currentSetIndex,
          currentSet.copyWith(timeoutsTakenB: currentSet.timeoutsTakenB + 1),
        ),
      );
    }
  }

  void _updateSetAndCheckFinished(VolleyballSet updatedSet) {
    final rules = state.rules;
    final isDecidingSet = state.currentSetIndex == (rules.setsToWin * 2 - 2);
    final targetPoints = isDecidingSet
        ? rules.decidingSetPoints
        : rules.pointsPerSet;

    bool setFinished = false;
    if (updatedSet.scoreA >= targetPoints ||
        updatedSet.scoreB >= targetPoints) {
      if ((updatedSet.scoreA - updatedSet.scoreB).abs() >= 2) {
        setFinished = true;
      }
    }

    final List<VolleyballSet> newSets = _updateSetsAt(
      state.currentSetIndex,
      updatedSet.copyWith(isFinished: setFinished),
    );

    if (setFinished) {
      state = state.copyWith(sets: newSets);
      _checkMatchFinished();
      if (!state.matchFinished) {
        _moveToNextSet();
      }
    } else {
      state = state.copyWith(sets: newSets);
    }
  }

  void _moveToNextSet() {
    final nextSets = [...state.sets, const VolleyballSet()];
    state = state.copyWith(
      sets: nextSets,
      currentSetIndex: state.currentSetIndex + 1,
    );
  }

  void _checkMatchFinished() {
    final setsA = state.setsWonA;
    final setsB = state.setsWonB;
    if (setsA >= state.rules.setsToWin || setsB >= state.rules.setsToWin) {
      state = state.copyWith(matchFinished: true);
    }
  }

  List<VolleyballSet> _updateSetsAt(int index, VolleyballSet newSet) {
    final list = [...state.sets];
    list[index] = newSet;
    return list;
  }

  void setServer(String? team) {
    _pushState();
    state = state.copyWith(server: team);
  }

  void resetGame() {
    _pushState();
    state = const VolleyballGameState();
  }

  void updateFromSync(VolleyballGameState newState) {
    if (state != newState) state = newState;
  }
}
