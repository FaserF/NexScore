import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';
import '../models/volleyball_models.dart';
import '../providers/volleyball_provider.dart';
import '../services/volleyball_pdf_service.dart';
import 'volleyball_signature_dialog.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';

class VolleyballScoreboard extends ConsumerStatefulWidget {
  const VolleyballScoreboard({super.key});

  @override
  ConsumerState<VolleyballScoreboard> createState() =>
      _VolleyballScoreboardState();
}

class _VolleyballScoreboardState extends ConsumerState<VolleyballScoreboard> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _triggerCelebration(VolleyballGameState state, AppLocalizations l10n) {
    if (!state.matchFinished) return;

    final winnerName = state.setsWonA > state.setsWonB
        ? state.teamAName
        : state.teamBName;
    final (lpA, lpB) = state.leaguePoints;

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

    if (state.matchFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerCelebration(state, l10n);
      });
    }

    return WinnerConfettiOverlay(
      controller: _confettiController,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.get('game_volleyball')),
          leading: BackButton(onPressed: () => context.go('/games')),
          actions: [
            if (!state.matchFinished) ...[
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: ref.read(volleyballStateProvider.notifier).canUndo
                    ? () => ref.read(volleyballStateProvider.notifier).undo()
                    : null,
                tooltip: l10n.get('game_undo'),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () =>
                    ref.read(volleyballStateProvider.notifier).toggleSides(),
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
                tooltip: l10n.get('wizard_end_game'),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => context.push('/games/volleyball/signals'),
              tooltip: l10n.get('vb_signals_title'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _confirmResetDialog(context, ref, l10n),
              tooltip: l10n.get('game_reset'),
            ),
          ],
        ),
        body: state.matchFinished
            ? _MatchFinishedView(state: state)
            : _ScoreboardBody(state: state),
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
  late TextEditingController _controllerA;
  late TextEditingController _controllerB;
  int _setsToWin = 3;

  @override
  void initState() {
    super.initState();
    final state = ref.read(volleyballStateProvider);
    _type = state.type;
    _controllerA = TextEditingController(
      text: widget.isEditing ? state.teamAName : '',
    );
    _controllerB = TextEditingController(
      text: widget.isEditing ? state.teamBName : '',
    );
    _setsToWin = state.rules.setsToWin;
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
    return AlertDialog(
      title: Text(l10n.get('game_volleyball')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            const SizedBox(height: 16),
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
            ),
            const SizedBox(height: 24),
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
                setsToWin: _setsToWin,
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
    return Column(
      children: [
        _SetSummary(state: state, l10n: l10n),
        Expanded(
          child: Column(
            children: [
              _TeamScoreArea(
                teamId: state.sidesSwapped ? 'B' : 'A',
                name: state.sidesSwapped ? state.teamBName : state.teamAName,
                score: state.sidesSwapped
                    ? state.currentSet.scoreB
                    : state.currentSet.scoreA,
                isServing: state.server == (state.sidesSwapped ? 'B' : 'A'),
                color: state.sidesSwapped
                    ? Colors.red.shade700
                    : Colors.blue.shade700,
                timeouts: state.sidesSwapped
                    ? state.currentSet.timeoutsTakenB
                    : state.currentSet.timeoutsTakenA,
                maxTimeouts: state.rules.timeoutsPerSet,
              ),
              const Divider(height: 1, thickness: 2),
              _TeamScoreArea(
                teamId: state.sidesSwapped ? 'A' : 'B',
                name: state.sidesSwapped ? state.teamAName : state.teamBName,
                score: state.sidesSwapped
                    ? state.currentSet.scoreA
                    : state.currentSet.scoreB,
                isServing: state.server == (state.sidesSwapped ? 'A' : 'B'),
                color: state.sidesSwapped
                    ? Colors.blue.shade700
                    : Colors.red.shade700,
                timeouts: state.sidesSwapped
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
    return Column(
      children: [
        _SetSummary(state: state, l10n: l10n),
        Expanded(
          child: Row(
            children: [
              _TeamScoreArea(
                teamId: state.sidesSwapped ? 'B' : 'A',
                name: state.sidesSwapped ? state.teamBName : state.teamAName,
                score: state.sidesSwapped
                    ? state.currentSet.scoreB
                    : state.currentSet.scoreA,
                isServing: state.server == (state.sidesSwapped ? 'B' : 'A'),
                color: state.sidesSwapped
                    ? Colors.red.shade700
                    : Colors.blue.shade700,
                timeouts: state.sidesSwapped
                    ? state.currentSet.timeoutsTakenB
                    : state.currentSet.timeoutsTakenA,
                maxTimeouts: state.rules.timeoutsPerSet,
              ),
              const VerticalDivider(width: 1, thickness: 2),
              _TeamScoreArea(
                teamId: state.sidesSwapped ? 'A' : 'B',
                name: state.sidesSwapped ? state.teamAName : state.teamBName,
                score: state.sidesSwapped
                    ? state.currentSet.scoreA
                    : state.currentSet.scoreB,
                isServing: state.server == (state.sidesSwapped ? 'A' : 'B'),
                color: state.sidesSwapped
                    ? Colors.blue.shade700
                    : Colors.red.shade700,
                timeouts: state.sidesSwapped
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Expanded(
      child: InkWell(
        onTap: () =>
            ref.read(volleyballStateProvider.notifier).addPoint(teamId),
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
                          fontFamily: 'monospace', // Simple "digital" feel
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
                            'SERVING',
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
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(maxTimeouts, (index) {
                    final taken = index < timeouts;
                    return AnimatedScaleButton(
                      onPressed: taken
                          ? () {}
                          : () => ref
                                .read(volleyballStateProvider.notifier)
                                .takeTimeout(teamId),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          color: taken
                              ? Colors.grey.withValues(alpha: 0.3)
                              : color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            const SizedBox(height: 32),
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
                ],
              ),
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: () => _showExportFlow(context, ref),
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(l10n.get('vb_export_pdf')),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExportFlow(BuildContext context, WidgetRef ref) async {
    // 1. Signature Team A
    final sigA = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) => VolleyballSignatureDialog(
        title: 'Captain ${state.teamAName} Signature',
      ),
    );
    if (sigA == null) return;

    // 2. Signature Team B
    if (!context.mounted) return;
    final sigB = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) => VolleyballSignatureDialog(
        title: 'Captain ${state.teamBName} Signature',
      ),
    );
    if (sigB == null) return;

    // 3. Signature Referee
    if (!context.mounted) return;
    final sigRef = await showDialog<Uint8List>(
      context: context,
      builder: (ctx) =>
          const VolleyballSignatureDialog(title: 'Referee Signature'),
    );
    if (sigRef == null) return;

    // 4. Generate PDF
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
