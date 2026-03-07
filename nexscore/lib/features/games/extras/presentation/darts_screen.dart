import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/darts_models.dart';

class DartsStateNotifier extends Notifier<DartsGameState> {
  @override
  DartsGameState build() => const DartsGameState();

  void addRound(String playerId, DartRound round) {
    final currentState =
        state.playerStates[playerId] ??
        DartPlayerState(
          startingScore: state.targetScore,
          finishType: state.finishType,
          startType: state.startType,
        );
    final updatedStates = Map<String, DartPlayerState>.from(state.playerStates);

    updatedStates[playerId] = currentState.copyWith(
      rounds: [...currentState.rounds, round],
    );

    state = state.copyWith(playerStates: updatedStates);
  }

  void updateSettings({
    int? targetScore,
    DartsFinishType? finishType,
    DartsStartType? startType,
  }) {
    state = state.copyWith(
      targetScore: targetScore,
      finishType: finishType,
      startType: startType,
      playerStates: {}, // Reset on major setting change
    );
  }

  void resetGame() {
    state = state.copyWith(playerStates: {});
  }
}

final dartsStateProvider = NotifierProvider<DartsStateNotifier, DartsGameState>(
  DartsStateNotifier.new,
);

class DartsPlayersNotifier extends Notifier<List<Player>> {
  @override
  List<Player> build() => [];

  void setPlayers(List<Player> players) {
    state = players;
  }
}

final dartsPlayersProvider = activePlayersProvider;

class DartsScreen extends ConsumerWidget {
  const DartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, ref, gameState, l10n),
            tooltip: l10n.get('darts_settings'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
        ],
      ),
      body: ListView.separated(
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
                    if (gameState.finishType == DartsFinishType.single)
                      valid = true;
                    else if (gameState.finishType == DartsFinishType.double &&
                        t.multiplier == 2)
                      valid = true;
                    else if (gameState.finishType == DartsFinishType.master &&
                        (t.multiplier == 2 || t.multiplier == 3))
                      valid = true;

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

  void _showSettingsDialog(
    BuildContext context,
    WidgetRef ref,
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

  void _confirmReset(
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
              ref.read(dartsStateProvider.notifier).resetGame();
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
