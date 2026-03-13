import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';
import '../models/volleyball_models.dart';
import '../providers/volleyball_provider.dart';
import '../services/volleyball_pdf_service.dart';
import 'volleyball_signature_dialog.dart';
import 'volleyball_signals_screen.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';

class VolleyballScoreboard extends ConsumerStatefulWidget {
  const VolleyballScoreboard({super.key});

  @override
  ConsumerState<VolleyballScoreboard> createState() =>
      _VolleyballScoreboardState();
}

class _VolleyballScoreboardState extends ConsumerState<VolleyballScoreboard> {
  final _confettiController = WinnerConfettiController();
  bool _celebrationShown = false;

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerCelebration(VolleyballGameState state, AppLocalizations l10n) {
    if (!state.matchFinished || _celebrationShown) return;
    _celebrationShown = true;

    final winnerName = state.setsWonA > state.setsWonB
        ? state.teamAName
        : state.teamBName;
    final (lpA, lpB) = state.leaguePoints;

    ref.read(audioServiceProvider).play(SfxType.fanfare);

    _confettiController.show(
      winnerName: winnerName,
      gameName: l10n.get('game_volleyball'),
      scores: [
        PlayerScore(state.teamAName, lpA),
        PlayerScore(state.teamBName, lpB),
      ],
      winnerColor: state.setsWonA > state.setsWonB
          ? Colors.blue.shade700
          : Colors.red.shade700,
      winnerEmoji: '🏐',
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(), // Estimate
      endTime: DateTime.now(),
      durationSeconds: 0,
      gameType: 'volleyball',
      players: [state.teamAName, state.teamBName],
      scores: {
        state.teamAName: lpA,
        state.teamBName: lpB,
      },
      gameData: {
        'setsWonA': state.setsWonA,
        'setsWonB': state.setsWonB,
        'type': state.type.name,
      },
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);

    // Auto-hide confetti after 4 seconds so _MatchFinishedView is accessible
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _confettiController.hide();
    });
  }

  void _showContinueDialog(
    BuildContext context,
    VolleyballGameState state,
    AppLocalizations l10n,
  ) {
    final winnerName = state.setsWonA > state.setsWonB
        ? state.teamAName
        : state.teamBName;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('vb_continue_playing_title')),
        content: Text(
          l10n.getWith('vb_continue_playing_message', [winnerName]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(volleyballStateProvider.notifier).confirmMatchFinished();
              Navigator.pop(context);
            },
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              _celebrationShown = false;
              ref
                  .read(volleyballStateProvider.notifier)
                  .continuePlayingRemainingSets();
              Navigator.pop(context);
            },
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(volleyballStateProvider);
    final l10n = AppLocalizations.of(context);

    if (!state.setupDone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const _SetupMatchDialog(),
        );
      });
    }

    if (state.matchFinished && !_celebrationShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerCelebration(state, l10n);
      });
    }

    if (state.pendingContinue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state.pendingContinue) {
          _showContinueDialog(context, state, l10n);
        }
      });
    }

    // Use isTeamAOnLeft indirectly via teamASide in the children widgets

    return WinnerConfettiOverlay(
      controller: _confettiController,
      showButtons: false,
      child: MultiplayerClientOverlay(
        child: Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: Text(l10n.get('game_volleyball')),
                leading: BackButton(onPressed: () => context.go('/games')),
                actions: [
                if (!state.matchFinished) ...[
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: state.canUndo
                        ? () => ref.read(volleyballStateProvider.notifier).undo()
                        : null,
                    tooltip: l10n.get('game_undo'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () => ref
                        .read(volleyballStateProvider.notifier)
                        .toggleSides(),
                    tooltip: l10n.get('vb_swap_sides'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            const _SetupMatchDialog(isEditing: true),
                      );
                    },
                    tooltip: l10n.get('edit'),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    onPressed: () => _confirmFinishEarly(context, ref, l10n),
                    tooltip: l10n.get('finishGame'),
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.rule),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VolleyballSignalsScreen(),
                      ),
                    );
                  },
                  tooltip: l10n.get('vb_signals_title'),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () {
                    launchUrl(
                      Uri.parse(
                        'https://faserf.github.io/NexScore/docs/user_guide/games/#volleyball-scoreboard',
                      ),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  tooltip: l10n.get('nav_help'),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _confirmResetDialog(context, ref, l10n),
                  tooltip: l10n.get('game_reset'),
                ),
              ],
            ),
            body: state.matchFinished && !state.pendingContinue
                ? _MatchFinishedView(state: state)
                : _ScoreboardBody(state: state),
          ),
          if (state.pendingSideSwitch)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.swap_horiz,
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.get('vb_side_switch_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.get('vb_side_switch_subtitle'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 48),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 20,
                          ),
                        ),
                        onPressed: () => ref
                            .read(volleyballStateProvider.notifier)
                            .confirmSideSwitch(),
                        icon: const Icon(Icons.check),
                        label: Text(l10n.get('ok').toUpperCase()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

  void _confirmResetDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('game_reset')),
        content: Text(l10n.get('game_reset_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              _celebrationShown = false;
              ref.read(volleyballStateProvider.notifier).resetGame();
              Navigator.pop(context);
            },
            child: Text(
              l10n.get('ok'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmFinishEarly(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('wizard_end_game')),
        content: Text(l10n.get('wizard_end_game_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(volleyballStateProvider.notifier).finishMatchEarly();
              Navigator.pop(context);
            },
            child: Text(
              l10n.get('ok'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreboardBody extends ConsumerWidget {
  final VolleyballGameState state;
  const _ScoreboardBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return _PortraitScoreboard(state: state, l10n: l10n);
        } else {
          return _LandscapeScoreboard(state: state, l10n: l10n);
        }
      },
    );
  }
}

class _SetupMatchDialog extends ConsumerStatefulWidget {
  final bool isEditing;
  const _SetupMatchDialog({this.isEditing = false});

  @override
  ConsumerState<_SetupMatchDialog> createState() => _SetupMatchDialogState();
}

class _SetupMatchDialogState extends ConsumerState<_SetupMatchDialog> {
  late VolleyballType _type;
  late VolleyballRuleSet _ruleSet;
  late TextEditingController _controllerA;
  late TextEditingController _controllerB;
  int _setsToWin = 3;
  VolleyballSide _initialSide = VolleyballSide.left;

  @override
  void initState() {
    super.initState();
    final state = ref.read(volleyballStateProvider);
    _type = state.type;
    _ruleSet = state.ruleSet;
    _controllerA = TextEditingController(
      text: widget.isEditing ? state.teamAName : '',
    );
    _controllerB = TextEditingController(
      text: widget.isEditing ? state.teamBName : '',
    );
    _setsToWin = state.rules.setsToWin;
    _initialSide = state.teamASide;
  }

  @override
  void dispose() {
    _controllerA.dispose();
    _controllerB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // BVV always plays 3 sets (setsToWin=2), so hide the "Best of" selector
    final showSetsSelector = _ruleSet == VolleyballRuleSet.dvv;

    return AlertDialog(
      title: Text(l10n.get('game_volleyball')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indoor / Beach selector
            SegmentedButton<VolleyballType>(
              segments: [
                ButtonSegment(
                  value: VolleyballType.indoor,
                  label: Text(l10n.get('vb_indoor')),
                  icon: const Icon(Icons.business),
                ),
                ButtonSegment(
                  value: VolleyballType.beach,
                  label: Text(l10n.get('vb_beach')),
                  icon: const Icon(Icons.beach_access),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
            const SizedBox(height: 12),
            // DVV / BVV rule set selector (only for indoor)
            if (_type == VolleyballType.indoor) ...[
              Text(
                l10n.get('vb_rule_set'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              SegmentedButton<VolleyballRuleSet>(
                segments: [
                  ButtonSegment(
                    value: VolleyballRuleSet.bvv,
                    label: Text(l10n.get('vb_rule_bvv')),
                  ),
                  ButtonSegment(
                    value: VolleyballRuleSet.dvv,
                    label: Text(l10n.get('vb_rule_dvv')),
                  ),
                ],
                selected: {_ruleSet},
                onSelectionChanged: (val) =>
                    setState(() => _ruleSet = val.first),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _controllerA,
              decoration: InputDecoration(
                labelText: l10n.get('vb_team_a'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controllerB,
              decoration: InputDecoration(
                labelText: l10n.get('vb_team_b'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.get('vb_sets'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              l10n.getWith('vb_players_count', ['4', '12']),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (showSetsSelector)
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Best of 1')),
                  ButtonSegment(value: 2, label: Text('Best of 3')),
                  ButtonSegment(value: 3, label: Text('Best of 5')),
                ],
                selected: {_setsToWin},
                onSelectionChanged: (set) {
                  setState(() => _setsToWin = set.first);
                },
              )
            else
              Text(
                'Best of 3',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 24),
            Text(
              l10n.get('vb_starting_side'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<VolleyballSide>(
              segments: [
                ButtonSegment(
                  value: VolleyballSide.left,
                  label: Text(l10n.get('vb_side_left')),
                  icon: const Icon(Icons.align_horizontal_left),
                ),
                ButtonSegment(
                  value: VolleyballSide.right,
                  label: Text(l10n.get('vb_side_right')),
                  icon: const Icon(Icons.align_horizontal_right),
                ),
              ],
              selected: {_initialSide},
              onSelectionChanged: (set) =>
                  setState(() => _initialSide = set.first),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.get('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            final notifier = ref.read(volleyballStateProvider.notifier);
            if (widget.isEditing) {
              notifier.updateTeams(_controllerA.text, _controllerB.text);
            } else {
              notifier.setupMatch(
                type: _type,
                teamA: _controllerA.text.isEmpty
                    ? l10n.get('vb_team_a')
                    : _controllerA.text,
                teamB: _controllerB.text.isEmpty
                    ? l10n.get('vb_team_b')
                    : _controllerB.text,
                pA: [],
                pB: [],
                setsToWin: _ruleSet == VolleyballRuleSet.bvv ? 2 : _setsToWin,
                ruleSet: _type == VolleyballType.indoor
                    ? _ruleSet
                    : VolleyballRuleSet.dvv,
                initialSide: _initialSide,
              );
            }
            Navigator.pop(context);
          },
          child: Text(l10n.get('ok')),
        ),
      ],
    );
  }
}

class _PortraitScoreboard extends ConsumerWidget {
  final VolleyballGameState state;
  final AppLocalizations l10n;
  const _PortraitScoreboard({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeamAFirst = state.teamASide == VolleyballSide.left;
    final team1Id = isTeamAFirst ? 'A' : 'B';
    final team2Id = isTeamAFirst ? 'B' : 'A';

    return Column(
      children: [
        _SetSummary(state: state, l10n: l10n),
        Expanded(
          child: Column(
            children: [
              _TeamScoreArea(
                teamId: team1Id,
                name: team1Id == 'A' ? state.teamAName : state.teamBName,
                score: team1Id == 'A'
                    ? state.currentSet.scoreA
                    : state.currentSet.scoreB,
                isServing: state.server == team1Id,
                color: team1Id == 'A'
                    ? Colors.blue.shade700
                    : Colors.red.shade700,
                timeouts: team1Id == 'A'
                    ? state.currentSet.timeoutsTakenA
                    : state.currentSet.timeoutsTakenB,
                maxTimeouts: state.rules.timeoutsPerSet,
              ),
              const Divider(height: 1, thickness: 2),
              _TeamScoreArea(
                teamId: team2Id,
                name: team2Id == 'A' ? state.teamAName : state.teamBName,
                score: team2Id == 'A'
                    ? state.currentSet.scoreA
                    : state.currentSet.scoreB,
                isServing: state.server == team2Id,
                color: team2Id == 'A'
                    ? Colors.blue.shade700
                    : Colors.red.shade700,
                timeouts: team2Id == 'A'
                    ? state.currentSet.timeoutsTakenA
                    : state.currentSet.timeoutsTakenB,
                maxTimeouts: state.rules.timeoutsPerSet,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LandscapeScoreboard extends ConsumerWidget {
  final VolleyballGameState state;
  final AppLocalizations l10n;
  const _LandscapeScoreboard({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeamAFirst = state.teamASide == VolleyballSide.left;
    final team1Id = isTeamAFirst ? 'A' : 'B';
    final team2Id = isTeamAFirst ? 'B' : 'A';

    return Column(
      children: [
        _SetSummary(state: state, l10n: l10n),
        Expanded(
          child: Row(
            children: [
              _TeamScoreArea(
                teamId: team1Id,
                name: team1Id == 'A' ? state.teamAName : state.teamBName,
                score: team1Id == 'A'
                    ? state.currentSet.scoreA
                    : state.currentSet.scoreB,
                isServing: state.server == team1Id,
                color: team1Id == 'A'
                    ? Colors.blue.shade700
                    : Colors.red.shade700,
                timeouts: team1Id == 'A'
                    ? state.currentSet.timeoutsTakenA
                    : state.currentSet.timeoutsTakenB,
                maxTimeouts: state.rules.timeoutsPerSet,
              ),
              const VerticalDivider(width: 1, thickness: 2),
              _TeamScoreArea(
                teamId: team2Id,
                name: team2Id == 'A' ? state.teamAName : state.teamBName,
                score: team2Id == 'A'
                    ? state.currentSet.scoreA
                    : state.currentSet.scoreB,
                isServing: state.server == team2Id,
                color: team2Id == 'A'
                    ? Colors.blue.shade700
                    : Colors.red.shade700,
                timeouts: team2Id == 'A'
                    ? state.currentSet.timeoutsTakenA
                    : state.currentSet.timeoutsTakenB,
                maxTimeouts: state.rules.timeoutsPerSet,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetSummary extends StatelessWidget {
  final VolleyballGameState state;
  final AppLocalizations l10n;
  const _SetSummary({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      borderRadius: 12,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SetWinsIndicator(count: state.setsWonA, color: Colors.blue),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'SET ${state.currentSetIndex + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  l10n.get('vb_sets'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          _SetWinsIndicator(count: state.setsWonB, color: Colors.red),
        ],
      ),
    );
  }
}

class _SetWinsIndicator extends StatelessWidget {
  final int count;
  final Color color;
  const _SetWinsIndicator({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < count ? color : color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 1),
          ),
        );
      }),
    );
  }
}

class _TeamScoreArea extends ConsumerWidget {
  final String teamId;
  final String name;
  final int score;
  final bool isServing;
  final Color color;
  final int timeouts;
  final int maxTimeouts;

  const _TeamScoreArea({
    required this.teamId,
    required this.name,
    required this.score,
    required this.isServing,
    required this.color,
    required this.timeouts,
    required this.maxTimeouts,
  });

  Future<void> _showInitialServerDialog(
    BuildContext context,
    WidgetRef ref,
    VolleyballGameState state,
    AppLocalizations l10n,
    String scorerTeamId,
  ) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('vb_select_initial_server')),
        content: Text(l10n.get('vb_select_initial_server_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'A'),
            child: Text(state.teamAName),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'B'),
            child: Text(state.teamBName),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(volleyballStateProvider.notifier).setServer(result);
      // After setting the initial server, add the point
      ref.read(volleyballStateProvider.notifier).addPoint(scorerTeamId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(volleyballStateProvider);

    return Expanded(
      child: InkWell(
        onTap: () {
          if (state.server == null) {
            _showInitialServerDialog(context, ref, state, l10n, teamId);
          } else {
            ref.read(volleyballStateProvider.notifier).addPoint(teamId);
          }
        },
        onLongPress: () =>
            ref.read(volleyballStateProvider.notifier).removePoint(teamId),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name.toUpperCase(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: Text(
                        '$score',
                        key: ValueKey(score),
                        style: TextStyle(
                          fontSize: 140,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          fontFamily: 'monospace',
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isServing)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sports_volleyball,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.get('vb_serving'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      '${l10n.get('vb_timeouts')}: $timeouts / $maxTimeouts',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: timeouts >= maxTimeouts 
                            ? Colors.grey 
                            : color.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(maxTimeouts, (index) {
                        final taken = index < timeouts;
                        return AnimatedScaleButton(
                          onPressed: taken || state.currentSet.isFinished
                              ? () {}
                              : () => ref
                                    .read(volleyballStateProvider.notifier)
                                    .takeTimeout(teamId),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 50,
                            height: 8,
                            decoration: BoxDecoration(
                              color: taken
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : color,
                              borderRadius: BorderRadius.circular(4),
                              border: taken 
                                  ? null 
                                  : Border.all(color: Colors.white24, width: 0.5),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchFinishedView extends ConsumerWidget {
  final VolleyballGameState state;
  const _MatchFinishedView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final winner = state.setsWonA > state.setsWonB
        ? state.teamAName
        : state.teamBName;
    final (lpA, lpB) = state.leaguePoints;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              l10n.get('vb_match_finished'),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.getWith('vb_winner', [winner]),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.amber.shade900),
            ),
            const SizedBox(height: 24),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FinishedTeamScore(
                        name: state.teamAName,
                        sets: state.setsWonA,
                        color: Colors.blue,
                      ),
                      const Text(
                        ':',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _FinishedTeamScore(
                        name: state.teamBName,
                        sets: state.setsWonB,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    l10n.get('vb_league_points').toUpperCase(),
                    style: TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$lpA - $lpB',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange,
                    ),
                  ),
                  if (state.ruleSet == VolleyballRuleSet.bvv)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.get('vb_rule_bvv'),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Set summaries with timestamps
            ...List.generate(state.sets.length, (index) {
              final s = state.sets[index];
              if (!s.isFinished && s.scoreA == 0 && s.scoreB == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.getWith('vb_set_with_number', [(index + 1).toString()]),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${s.scoreA} - ${s.scoreB}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (s.startedAt != null || s.endedAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatTimeRange(s.startedAt, s.endedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            // Action buttons — directly in the finished view (no overlap)
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _showExportFlow(context, ref),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(l10n.get('vb_export_pdf')),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/games'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.get('nav_games')), // Using 'nav_games' or similar to go back to overview
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(shareServiceProvider)
                        .shareWidget(
                          context,
                          ShareableScorecard(
                            gameName: l10n.get('game_volleyball'),
                            winnerName: winner,
                            winnerEmoji: '🏐',
                            winnerColor: state.setsWonA > state.setsWonB
                                ? Colors.blue.shade700
                                : Colors.red.shade700,
                            finalScores: [
                              PlayerScore(state.teamAName, lpA),
                              PlayerScore(state.teamBName, lpB),
                            ],
                          ),
                          text:
                              '${l10n.get('game_volleyball')}: ${state.teamAName} ${state.setsWonA}:${state.setsWonB} ${state.teamBName} 🏐',
                        );
                  },
                  icon: const Icon(Icons.share),
                  label: Text(l10n.get('share')),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatTimeRange(DateTime? start, DateTime? end) {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (start != null && end != null) return '${fmt(start)} – ${fmt(end)}';
    if (start != null) return fmt(start);
    if (end != null) return '→ ${fmt(end)}';
    return '';
  }

  Future<void> _showExportFlow(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    // 1. Signature Team A
    final sigAResult = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) => VolleyballSignatureDialog(
        title: l10n.getWith('vb_pdf_captain', [state.teamAName]),
      ),
    );
    if (sigAResult == null) return;
    // Empty bytes = skipped
    final Uint8List? sigA = sigAResult.isEmpty ? null : sigAResult;

    // 2. Signature Team B
    if (!context.mounted) return;
    final sigBResult = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) => VolleyballSignatureDialog(
        title: l10n.getWith('vb_pdf_captain', [state.teamBName]),
      ),
    );
    if (sigBResult == null) return;
    final Uint8List? sigB = sigBResult.isEmpty ? null : sigBResult;

    // 3. Signature Referee
    if (!context.mounted) return;
    final sigRefResult = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) =>
          VolleyballSignatureDialog(title: l10n.get('vb_pdf_referee')),
    );
    if (sigRefResult == null) return;
    final Uint8List? sigRef = sigRefResult.isEmpty ? null : sigRefResult;

    // 4. Generate PDF
    if (!context.mounted) return;
    await VolleyballPdfService.generateAndPrintReport(
      context: context,
      state: state,
      signatureA: sigA,
      signatureB: sigB,
      signatureRef: sigRef,
    );
  }
}


class _FinishedTeamScore extends StatelessWidget {
  final String name;
  final int sets;
  final Color color;
  const _FinishedTeamScore({
    required this.name,
    required this.sets,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          '$sets',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
