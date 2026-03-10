import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';

import '../models/darts_models.dart';
import '../providers/darts_provider.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';

class DartsScreen extends ConsumerStatefulWidget {
  const DartsScreen({super.key});

  // Duration Tracking: startedAt, endedAt, DateTime, duration

  @override
  ConsumerState<DartsScreen> createState() => _DartsScreenState();
}

class _DartsScreenState extends ConsumerState<DartsScreen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showWinner(DartsGameState state, List<Player> players, AppLocalizations l10n) {
    if (players.isEmpty) return;

    // Highest average or lowest throws? Usually just who finished first.
    // In our model, we can sort by currentScore (0 is best)
    final List<PlayerScore> scores = players.map((p) {
      final pState = state.playerStates[p.id] ?? DartPlayerState(startingScore: state.targetScore);
      return PlayerScore(p.name, pState.currentScore);
    }).toList();

    scores.sort((a, b) => a.score.compareTo(b.score));

    final winnerName = scores.first.name;
    final winner = players.firstWhere((p) => p.name == winnerName);

    ref.read(audioServiceProvider).play(SfxType.fanfare);
    _confettiController.show(
      winnerName: winner.name,
      winnerEmoji: '🎯',
      gameName: l10n.get('darts_title'),
      scores: scores,
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(), // Estimate
      endTime: DateTime.now(),
      durationSeconds: 0,
      gameType: 'darts',
      players: players.map<String>((p) => p.name).toList(),
      scores: {for (var s in scores) s.name: s.score},
      gameData: {
        'targetScore': state.targetScore,
        'startType': state.startType.name,
        'finishType': state.finishType.name,
      },
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(dartsStateProvider);
    final players = ref.watch(dartsPlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('darts_title'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.getWith('darts_target', [gameState.targetScore.toString()]),
        ),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://faserf.github.io/NexScore/docs/user_guide/games/#darts-x01',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _confirmSettings(context, gameState, l10n),
            tooltip: l10n.get('darts_settings'),
          ),
          if (gameState.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => ref.read(dartsStateProvider.notifier).undo(),
              tooltip: l10n.get('game_undo'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, l10n),
            tooltip: l10n.get('game_reset'),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _confirmFinishEarly(context, l10n),
            tooltip: l10n.get('finishGame'),
          ),
        ],
      ),
      body: WinnerConfettiOverlay(
        controller: _confettiController,
        child: MultiplayerClientOverlay(
          child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: players.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = players[index];
            final pState =
                gameState.playerStates[p.id] ??
                DartPlayerState(
                  startingScore: gameState.targetScore,
                  finishType: gameState.finishType,
                  startType: gameState.startType,
                );
            final currentScore = pState.currentScore;
            final isWinner = currentScore == 0;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              leading: CircleAvatar(
                backgroundColor: Color(
                  int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                ),
                child: isWinner
                    ? const Icon(Icons.emoji_events, color: Colors.amber)
                    : Text(p.name.substring(0, 1).toUpperCase()),
              ),
              title: Text(
                p.name,
                style: TextStyle(
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                  color: isWinner ? Colors.green : null,
                ),
              ),
              subtitle: Text(
                '${l10n.getWith('darts_avg', [pState.averagePerDart.toStringAsFixed(1)])} | ${l10n.getWith('darts_thrown', [(pState.rounds.length * 3).toString()])}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$currentScore',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isWinner
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: isWinner
                        ? null
                        : () => _showPointsDialog(
                            context,
                            ref,
                            p,
                            pState,
                            gameState,
                            l10n,
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

  void _confirmReset(BuildContext context, AppLocalizations l10n) {
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
          FilledButton(
            onPressed: () {
              ref.read(dartsStateProvider.notifier).resetGame();
              Navigator.pop(context);
            },
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _showPointsDialog(
    BuildContext context,
    WidgetRef ref,
    Player player,
    DartPlayerState pState,
    DartsGameState gameState,
    AppLocalizations l10n,
  ) async {
    final List<DartThrow> currentThrows = [];
    int multiplier = 1;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            int previewScore = pState.currentScore;
            bool isBust = false;

            // Calculate preview using the logic from our model
            final tempPlayerState = pState.copyWith(
              rounds: [
                ...pState.rounds,
                DartRound(throws: currentThrows),
              ],
            );
            previewScore = tempPlayerState.currentScore;

            // Check if we busted in THIS round
            if (currentThrows.isNotEmpty) {
              // A simplified bust check for UI feedback
              // In the model, currentScore stays same on bust.
              if (previewScore == pState.currentScore &&
                  currentThrows.fold(0, (s, t) => s + t.total) > 0) {
                // Might be a bust, but could also be "not started"
                // Let's check more carefully
                int lastWorkingScore = pState.currentScore;
                bool started =
                    pState.currentScore < pState.startingScore ||
                    gameState.startType == DartsStartType.straight;

                for (int i = 0; i < currentThrows.length; i++) {
                  final t = currentThrows[i];
                  if (!started) {
                    if ((gameState.startType == DartsStartType.double &&
                            t.multiplier == 2) ||
                        (gameState.startType == DartsStartType.master &&
                            (t.multiplier == 2 || t.multiplier == 3))) {
                      started = true;
                    } else {
                      continue;
                    }
                  }

                  final next = lastWorkingScore - t.total;
                  if (next < 0 || next == 1) {
                    isBust = true;
                    break;
                  }
                  if (next == 0) {
                    bool valid = false;
                    if (gameState.finishType == DartsFinishType.single) {
                      valid = true;
                    } else if (gameState.finishType == DartsFinishType.double &&
                        t.multiplier == 2) {
                      valid = true;
                    } else if (gameState.finishType == DartsFinishType.master &&
                        (t.multiplier == 2 || t.multiplier == 3)) {
                      valid = true;
                    }

                    if (!valid) isBust = true;
                    break;
                  }
                  lastWorkingScore = next;
                }
              }
            }

            return AlertDialog(
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Color(
                      int.parse(player.avatarColor.replaceFirst('#', '0xff')),
                    ),
                    child: Text(
                      player.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(player.name)),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isBust
                            ? Colors.red.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.get('darts_remaining'),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                isBust
                                    ? l10n.get('darts_bust')
                                    : '$previewScore',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isBust ? Colors.red : null,
                                    ),
                              ),
                              if (!isBust &&
                                  previewScore <= 170 &&
                                  ![
                                    159,
                                    162,
                                    163,
                                    165,
                                    166,
                                    168,
                                    169,
                                  ].contains(previewScore))
                                Text(
                                  l10n.get('darts_checkout_possible'),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                l10n.get('history_pts'),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Text(
                                '${currentThrows.fold(0, (sum, t) => sum + t.total)}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Current Throws Bubbles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final hasThrow = index < currentThrows.length;
                        final t = hasThrow ? currentThrows[index] : null;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Chip(
                            label: Text(
                              t == null
                                  ? '-'
                                  : '${t.multiplier == 3
                                        ? 'T'
                                        : t.multiplier == 2
                                        ? 'D'
                                        : 'S'}${t.score}',
                            ),
                            backgroundColor: hasThrow
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    // Multiplier Switcher
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('S')),
                        ButtonSegment(value: 2, label: Text('D')),
                        ButtonSegment(value: 3, label: Text('T')),
                      ],
                      selected: {multiplier},
                      onSelectionChanged: (val) {
                        setState(() => multiplier = val.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Board Numbers Grid
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ...List.generate(20, (i) => i + 1).map((n) {
                          return _BoardButton(
                            label: '$n',
                            onPressed: currentThrows.length < 3 && !isBust
                                ? () {
                                    setState(() {
                                      currentThrows.add(
                                        DartThrow(
                                          score: n,
                                          multiplier: multiplier,
                                        ),
                                      );
                                      multiplier = 1; // Reset to single
                                    });
                                  }
                                : null,
                          );
                        }),
                        _BoardButton(
                          label: '25',
                          onPressed:
                              currentThrows.length < 3 &&
                                  !isBust &&
                                  multiplier < 3
                              ? () {
                                  setState(() {
                                    currentThrows.add(
                                      DartThrow(
                                        score: 25,
                                        multiplier: multiplier,
                                      ),
                                    );
                                    multiplier = 1;
                                  });
                                }
                              : null,
                        ),
                        _BoardButton(
                          label: '0',
                          onPressed: currentThrows.length < 3 && !isBust
                              ? () {
                                  setState(() {
                                    currentThrows.add(
                                      const DartThrow(score: 0, multiplier: 1),
                                    );
                                    multiplier = 1;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (currentThrows.isNotEmpty) {
                      setState(() => currentThrows.removeLast());
                      isBust = false; // Recalculated next build
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    currentThrows.isEmpty
                        ? l10n.get('cancel')
                        : l10n.get('darts_remove_last'),
                  ),
                ),
                FilledButton(
                  onPressed: currentThrows.isNotEmpty || isBust
                      ? () {
                          final round = DartRound(throws: currentThrows);
                          ref
                              .read(dartsStateProvider.notifier)
                              .addRound(player.id, round);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(l10n.get('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmSettings(
    BuildContext context,
    DartsGameState state,
    AppLocalizations l10n,
  ) {
    int selectedScore = state.targetScore;
    DartsFinishType selectedFinish = state.finishType;
    DartsStartType selectedStart = state.startType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.get('darts_settings')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.get('history_pts'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [101, 201, 301, 501, 701, 1001]
                      .map(
                        (s) => ChoiceChip(
                          label: Text('$s'),
                          selected: selectedScore == s,
                          onSelected: (val) =>
                              setState(() => selectedScore = s),
                        ),
                      )
                      .toList(),
                ),
                const Divider(height: 32),
                Text(
                  l10n.get('darts_start_type'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<DartsStartType>(
                  isExpanded: true,
                  value: selectedStart,
                  onChanged: (val) => setState(() => selectedStart = val!),
                  items: DartsStartType.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(l10n.get('darts_start_${e.name}')),
                        ),
                      )
                      .toList(),
                ),
                const Divider(height: 32),
                Text(
                  l10n.get('darts_finish_type'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButton<DartsFinishType>(
                  isExpanded: true,
                  value: selectedFinish,
                  onChanged: (val) => setState(() => selectedFinish = val!),
                  items: DartsFinishType.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(l10n.get('darts_finish_${e.name}')),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(
              onPressed: () {
                ref
                    .read(dartsStateProvider.notifier)
                    .updateSettings(
                      targetScore: selectedScore,
                      finishType: selectedFinish,
                      startType: selectedStart,
                    );
                Navigator.pop(context);
              },
              child: Text(l10n.get('ok')),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmFinishEarly(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('finishGame')),
        content: Text(l10n.get('finishGameConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final state = ref.read(dartsStateProvider);
              final players = ref.read(dartsPlayersProvider);
              _showWinner(state, players, l10n);
              ref.read(dartsStateProvider.notifier).resetGame();
              Navigator.pop(context);
            },
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
  }
}

class _BoardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _BoardButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 40,
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
