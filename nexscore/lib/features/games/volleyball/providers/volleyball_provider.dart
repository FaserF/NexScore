import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/volleyball_models.dart';

final volleyballStateProvider =
    NotifierProvider<VolleyballStateNotifier, VolleyballGameState>(
      VolleyballStateNotifier.new,
    );

class VolleyballStateNotifier extends Notifier<VolleyballGameState> {
  final List<VolleyballGameState> _history = [];

  @override
  VolleyballGameState build() => VolleyballGameState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 20) _history.removeAt(0);
    state = state.copyWith(canUndo: _history.isNotEmpty);
  }

  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isEmpty) return;
    state = _history.removeLast().copyWith(canUndo: _history.isNotEmpty);
  }

  void setupMatch({
    required VolleyballType type,
    required String teamA,
    required String teamB,
    required List<String> pA,
    required List<String> pB,
    int setsToWin = 3,
    VolleyballRuleSet ruleSet = VolleyballRuleSet.bvv,
    VolleyballSide? initialSide,
  }) {
    final rules = type == VolleyballType.indoor
        ? (ruleSet == VolleyballRuleSet.bvv
              ? VolleyballRules.bvv()
              : VolleyballRules.indoor(setsToWin: setsToWin))
        : VolleyballRules.beach(setsToWin: setsToWin);

    state = VolleyballGameState(
      type: type,
      rules: rules,
      ruleSet: ruleSet,
      teamAName: teamA,
      teamBName: teamB,
      teamAPlayers: pA,
      teamBPlayers: pB,
      setupDone: true,
      matchStartedAt: DateTime.now(),
      teamASide: initialSide ?? VolleyballSide.left,
      sets: [VolleyballSet(startedAt: DateTime.now())],
    );
  }

  void finishMatchEarly() {
    if (state.matchFinished) return;
    _pushState();
    state = state.copyWith(
      matchFinished: true,
      earlyFinished: true,
      matchEndedAt: DateTime.now(),
    );
  }

  void confirmSideSwitch() {
    state = state.copyWith(
      teamASide: state.teamASide == VolleyballSide.left
          ? VolleyballSide.right
          : VolleyballSide.left,
      pendingSideSwitch: false,
      sets: _updateSetsAt(
        state.currentSetIndex,
        state.currentSet.copyWith(midSetSideSwitchDone: true),
      ),
    );
  }

  void toggleSides() {
    _pushState();
    state = state.copyWith(sidesSwapped: !state.sidesSwapped);
  }

  void updateTeams(String teamA, String teamB) {
    _pushState();
    state = state.copyWith(teamAName: teamA, teamBName: teamB);
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

    // Mid-set side switch check (deciding set only)
    final isDeciding = state.currentSetIndex == state.rules.maxSets - 1;
    if (isDeciding && !updatedSet.midSetSideSwitchDone) {
      final leadScore = scoreA > scoreB ? scoreA : scoreB;
      if (leadScore >= state.rules.midSetSideSwitchPoints) {
        state = state.copyWith(
          sets: _updateSetsAt(state.currentSetIndex, updatedSet),
          pendingSideSwitch: true,
        );
        // We still check for set finished below, but UI will show overlay
      }
    }

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
    final isDecidingSet = state.currentSetIndex == (rules.maxSets - 1);
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

    final now = DateTime.now();
    final List<VolleyballSet> newSets = _updateSetsAt(
      state.currentSetIndex,
      updatedSet.copyWith(
        isFinished: setFinished,
        endedAt: setFinished ? now : null,
      ),
    );

    if (setFinished) {
      state = state.copyWith(sets: newSets);
      _checkMatchFinished();
      if (!state.matchFinished && !state.pendingContinue) {
        _moveToNextSet();
      }
    } else {
      state = state.copyWith(sets: newSets);
    }
  }

  void _moveToNextSet() {
    final nextSets = List<VolleyballSet>.from(state.sets);
    nextSets.add(VolleyballSet(startedAt: DateTime.now()));

    state = state.copyWith(
      sets: nextSets,
      currentSetIndex: state.currentSetIndex + 1,
      timeoutsA: 0,
      timeoutsB: 0,
      teamASide: state.teamASide == VolleyballSide.left
          ? VolleyballSide.right
          : VolleyballSide.left,
    );
  }

  void _checkMatchFinished() {
    final setsA = state.setsWonA;
    final setsB = state.setsWonB;
    if (setsA >= state.rules.setsToWin || setsB >= state.rules.setsToWin) {
      // Check if there are remaining sets that could be played
      final totalFinished = state.sets.where((s) => s.isFinished).length;
      final maxSets = state.rules.maxSets;
      if (totalFinished < maxSets) {
        // Winner determined but remaining sets available — ask user
        state = state.copyWith(
          pendingContinue: true,
          matchFinished: true,
          matchEndedAt: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          matchFinished: true,
          matchEndedAt: DateTime.now(),
        );
      }
    }
  }

  /// User chose to continue playing remaining sets after winner was determined.
  void continuePlayingRemainingSets() {
    if (!state.pendingContinue) return;
    _pushState();
    state = state.copyWith(
      matchFinished: false,
      pendingContinue: false,
      matchEndedAt: null,
    );
    _moveToNextSet();
  }

  /// User chose not to continue — keep the match as finished.
  void confirmMatchFinished() {
    _pushState();
    state = state.copyWith(pendingContinue: false);
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
    state = VolleyballGameState();
  }

  void updateFromSync(VolleyballGameState newState) {
    if (state != newState) state = newState;
  }
}
