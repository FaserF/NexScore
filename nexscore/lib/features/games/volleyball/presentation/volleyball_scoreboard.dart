import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../models/volleyball_models.dart';
import '../providers/volleyball_provider.dart';
import '../services/volleyball_pdf_service.dart';
import 'volleyball_signature_dialog.dart';
import 'volleyball_signals_screen.dart';

class VolleyballScoreboard extends ConsumerWidget {
  const VolleyballScoreboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(volleyballStateProvider);
    final l10n = AppLocalizations.of(context);

    // Initial setup if no team names are set
    if (state.teamAName == 'Team A' &&
        state.teamBName == 'Team B' &&
        state.sets.length == 1 &&
        state.sets[0].scoreA == 0 &&
        state.sets[0].scoreB == 0 &&
        state.server == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSetupDialog(context, ref, l10n);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_volleyball')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: ref.read(volleyballStateProvider.notifier).canUndo
                ? () => ref.read(volleyballStateProvider.notifier).undo()
                : null,
            tooltip: l10n.get('game_undo'),
          ),
          IconButton(
            icon: const Icon(Icons.rule),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VolleyballSignalsScreen(),
              ),
            ),
            tooltip: l10n.get('vb_signals_title'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (state.matchFinished) {
            return _MatchFinishedView(state: state, l10n: l10n);
          }
          if (orientation == Orientation.portrait) {
            return _PortraitScoreboard(state: state, l10n: l10n);
          } else {
            return _LandscapeScoreboard(state: state, l10n: l10n);
          }
        },
      ),
    );
  }

  void _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SetupMatchDialog(ref: ref, l10n: l10n),
    );
  }

  void _showSetupDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SetupMatchDialog(ref: ref, l10n: l10n),
    );
  }
}

class _SetupMatchDialog extends StatefulWidget {
  final WidgetRef ref;
  final AppLocalizations l10n;
  const _SetupMatchDialog({required this.ref, required this.l10n});

  @override
  State<_SetupMatchDialog> createState() => _SetupMatchDialogState();
}

class _SetupMatchDialogState extends State<_SetupMatchDialog> {
  late TextEditingController _teamAController;
  late TextEditingController _teamBController;
  VolleyballType _type = VolleyballType.indoor;

  @override
  void initState() {
    super.initState();
    _teamAController = TextEditingController(text: 'Team A');
    _teamBController = TextEditingController(text: 'Team B');
  }

  @override
  void dispose() {
    _teamAController.dispose();
    _teamBController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l10n.get('game_volleyball')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<VolleyballType>(
              segments: [
                ButtonSegment(
                  value: VolleyballType.indoor,
                  label: Text(widget.l10n.get('vb_indoor')),
                  icon: const Icon(Icons.business),
                ),
                ButtonSegment(
                  value: VolleyballType.beach,
                  label: Text(widget.l10n.get('vb_beach')),
                  icon: const Icon(Icons.beach_access),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _teamAController,
              decoration: InputDecoration(
                labelText: widget.l10n.get('vb_team_a'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _teamBController,
              decoration: InputDecoration(
                labelText: widget.l10n.get('vb_team_b'),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.get('cancel')),
        ),
        FilledButton(
          onPressed: () {
            widget.ref
                .read(volleyballStateProvider.notifier)
                .setupMatch(
                  type: _type,
                  teamA: _teamAController.text,
                  teamB: _teamBController.text,
                  pA: [],
                  pB: [],
                );
            Navigator.pop(context);
          },
          child: Text(widget.l10n.get('ok')),
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
                teamId: 'A',
                name: state.teamAName,
                score: state.currentSet.scoreA,
                isServing: state.server == 'A',
                color: Colors.blue.shade700,
                timeouts: state.currentSet.timeoutsTakenA,
                maxTimeouts: state.rules.timeoutsPerSet,
              ),
              const Divider(height: 1, thickness: 2),
              _TeamScoreArea(
                teamId: 'B',
                name: state.teamBName,
                score: state.currentSet.scoreB,
                isServing: state.server == 'B',
                color: Colors.red.shade700,
                timeouts: state.currentSet.timeoutsTakenB,
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
                teamId: 'A',
                name: state.teamAName,
                score: state.currentSet.scoreA,
                isServing: state.server == 'A',
                color: Colors.blue.shade700,
                timeouts: state.currentSet.timeoutsTakenA,
                maxTimeouts: state.rules.timeoutsPerSet,
              ),
              const VerticalDivider(width: 1, thickness: 2),
              _TeamScoreArea(
                teamId: 'B',
                name: state.teamBName,
                score: state.currentSet.scoreB,
                isServing: state.server == 'B',
                color: Colors.red.shade700,
                timeouts: state.currentSet.timeoutsTakenB,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${state.setsWonA}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${l10n.get('vb_sets')} (Set ${state.currentSetIndex + 1})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Text(
            '${state.setsWonB}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ],
      ),
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
    final l10n = AppLocalizations.of(context);
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () =>
              ref.read(volleyballStateProvider.notifier).addPoint(teamId),
          onLongPress: () =>
              ref.read(volleyballStateProvider.notifier).removePoint(teamId),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isServing)
                          const Icon(
                            Icons.sports_volleyball,
                            size: 24,
                            color: Colors.orange,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        if (isServing)
                          const Icon(
                            Icons.sports_volleyball,
                            size: 24,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                    FittedBox(
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 120,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${l10n.get('vb_timeout')}: '),
                    ...List.generate(maxTimeouts, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Icon(
                          index < timeouts ? Icons.timer_off : Icons.timer,
                          size: 20,
                          color: index < timeouts ? Colors.grey : color,
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    if (timeouts < maxTimeouts)
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => ref
                            .read(volleyballStateProvider.notifier)
                            .takeTimeout(teamId),
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
  final AppLocalizations l10n;
  const _MatchFinishedView({required this.state, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final winner = state.setsWonA > state.setsWonB
        ? state.teamAName
        : state.teamBName;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
          const SizedBox(height: 24),
          Text(
            l10n.get('vb_match_finished'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.getWith('vb_winner', [winner]),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.amber.shade900),
          ),
          const SizedBox(height: 32),
          Text(
            '${state.setsWonA} : ${state.setsWonB}',
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: () => _showExportFlow(context, ref),
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(l10n.get('vb_export_pdf')),
          ),
        ],
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
      state: state,
      signatureA: sigA,
      signatureB: sigB,
      signatureRef: sigRef,
    );
  }
}
