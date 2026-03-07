import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/wizard_models.dart';
import '../providers/wizard_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';

class WizardScreen extends ConsumerStatefulWidget {
  const WizardScreen({super.key});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  bool _isBannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('game_wizard'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    final scoringLabel = state.scoringVariant == WizardScoringVariant.standard
        ? l10n.get('wizard_scoring_standard').split(' – ')[0]
        : state.scoringVariant == WizardScoringVariant.lenient
        ? l10n.get('wizard_scoring_lenient').split(' – ')[0]
        : l10n.get('wizard_scoring_extreme').split(' – ')[0];

    final currentRoundNumber = state.rounds.length + state.customStartRound;
    final totalRounds = state.customTotalRounds ?? (60 ~/ players.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_wizard')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          Chip(
            label: Text(scoringLabel),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://faserf.github.io/NexScore/docs/user_guide/games/#wizard',
                ),
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: l10n.get('settings'),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _showEndGameDialog(context),
            tooltip: l10n.get('wizard_end_game'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
        ],
      ),
      body: MultiplayerClientOverlay(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 2-player warning banner
              if (players.length == 2 && !_isBannerDismissed)
                MaterialBanner(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  content: Text(
                    l10n.get('wizard_2player_warning'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  leading: Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          setState(() => _isBannerDismissed = true),
                      child: Text(l10n.get('ok')),
                    ),
                  ],
                ),

              // Active Round / Current Predictions
              if (state.currentRoundBids != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${l10n.get('wizard_round')} $currentRoundNumber / $totalRounds',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Chip(label: Text(l10n.get('wizard_predictions'))),
                            ],
                          ),
                          if (state.jesterTrumpRules)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Jester Trump Active',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: players.map((p) {
                              return Column(
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    (state.currentRoundBids![p.id] ?? 0)
                                        .toString(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Scoreboard
              Column(
                children: players.map((p) {
                  final score = WizardGameState.calculatePlayerScore(
                    p.id,
                    state.rounds,
                    lenient:
                        state.scoringVariant == WizardScoringVariant.lenient,
                    extreme:
                        state.scoringVariant == WizardScoringVariant.extreme,
                  );
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                        int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                      ),
                      child: Text(p.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(p.name),
                    subtitle: Text('${l10n.get('leaderboard_score')}: $score'),
                    trailing: state.rounds.isEmpty
                        ? null
                        : Text(
                            score >= 0 ? '+$score' : score.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: score >= 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                  );
                }).toList(),
              ),

              // Round history
              if (state.rounds.isNotEmpty)
                ExpansionTile(
                  title: Text(
                    l10n.getWith('wizard_history', [
                      state.rounds.length.toString(),
                    ]),
                  ),
                  children: state.rounds.reversed.map((round) {
                    return ListTile(
                      dense: true,
                      title: Text(
                        '${l10n.get('wizard_round')} ${round.roundIndex}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            players
                                .map(
                                  (p) =>
                                      '${p.name}: ${l10n.get('wizard_bid')} ${round.bids[p.id] ?? 0} / ${l10n.get('wizard_won')} ${round.tricks[p.id] ?? 0}',
                                )
                                .join(' · '),
                          ),
                          if (round.blownTricks > 0)
                            Text(
                              '${l10n.get('wizard_bombs')}: ${round.blownTricks}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  onPressed: () {
                    if (state.currentRoundBids == null) {
                      _showPredictionDialog(context, ref, state, players);
                    } else {
                      _showResultsDialog(context, ref, state, players);
                    }
                  },
                  icon: Icon(
                    state.currentRoundBids == null ? Icons.edit : Icons.check,
                  ),
                  label: Text(
                    state.currentRoundBids == null
                        ? '${l10n.get('wizard_round')} $currentRoundNumber ${l10n.get('wizard_predictions')}'
                        : '${l10n.get('wizard_round')} $currentRoundNumber ${l10n.get('wizard_actuals')}',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(wizardStateProvider);
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l10n.get('settings')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.get('settings_data'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...WizardScoringVariant.values.map((v) {
                      final label = v == WizardScoringVariant.standard
                          ? l10n.get('wizard_scoring_standard')
                          : v == WizardScoringVariant.lenient
                          ? l10n.get('wizard_scoring_lenient')
                          : l10n.get('wizard_scoring_extreme');
                      final isSelected = state.scoringVariant == v;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        title: Text(label),
                        onTap: () {
                          ref
                              .read(wizardStateProvider.notifier)
                              .updateState(state.copyWith(scoringVariant: v));
                        },
                      );
                    }),
                    const Divider(),
                    SwitchListTile(
                      title: Text(l10n.get('wizard_rule_stiche')),
                      value: state.ruleSticheDuertenNichtAufgehen,
                      onChanged: (val) {
                        ref
                            .read(wizardStateProvider.notifier)
                            .updateState(
                              state.copyWith(
                                ruleSticheDuertenNichtAufgehen: val,
                              ),
                            );
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Jester Trump Rules'),
                      subtitle: const Text('Jester as trump = No Trump'),
                      value: state.jesterTrumpRules,
                      onChanged: (val) {
                        ref
                            .read(wizardStateProvider.notifier)
                            .updateState(state.copyWith(jesterTrumpRules: val));
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Anniversary Edition'),
                      subtitle: const Text(
                        'Include Dragon & Fairy (+/- 10 points)',
                      ),
                      value: state.anniversaryCards,
                      onChanged: (val) {
                        ref
                            .read(wizardStateProvider.notifier)
                            .updateState(state.copyWith(anniversaryCards: val));
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: Text(l10n.get('wizard_start_round')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: state.customStartRound > 1
                                ? () {
                                    ref
                                        .read(wizardStateProvider.notifier)
                                        .updateState(
                                          state.copyWith(
                                            customStartRound:
                                                state.customStartRound - 1,
                                          ),
                                        );
                                  }
                                : null,
                          ),
                          Text(
                            state.customStartRound.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              ref
                                  .read(wizardStateProvider.notifier)
                                  .updateState(
                                    state.copyWith(
                                      customStartRound:
                                          state.customStartRound + 1,
                                    ),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('Total Rounds'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: (state.customTotalRounds ?? 1) > 1
                                ? () {
                                    ref
                                        .read(wizardStateProvider.notifier)
                                        .updateState(
                                          state.copyWith(
                                            customTotalRounds:
                                                (state.customTotalRounds ??
                                                    20) -
                                                1,
                                          ),
                                        );
                                  }
                                : null,
                          ),
                          Text(
                            (state.customTotalRounds ??
                                    60 ~/
                                        ref.read(activePlayersProvider).length)
                                .toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              ref
                                  .read(wizardStateProvider.notifier)
                                  .updateState(
                                    state.copyWith(
                                      customTotalRounds:
                                          (state.customTotalRounds ?? 20) + 1,
                                    ),
                                  );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('close')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEndGameDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/games');
            },
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> _showPredictionDialog(
    BuildContext context,
    WidgetRef ref,
    WizardGameState state,
    List<Player> players,
  ) async {
    final roundIndex = state.rounds.length + state.customStartRound;
    final Map<String, TextEditingController> bidControllers = {
      for (var p in players) p.id: TextEditingController(text: '0'),
    };

    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(
            '${l10n.get('wizard_round')} $roundIndex — ${l10n.get('wizard_predictions')}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...players.map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: bidControllers[p.id],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              labelText: l10n.get('wizard_bid'),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
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
                final bids = {
                  for (var p in players)
                    p.id: int.tryParse(bidControllers[p.id]!.text) ?? 0,
                };

                // Validation for Uneven Tricks Setting
                if (state.ruleSticheDuertenNichtAufgehen) {
                  final bidsSum = bids.values.fold<int>(
                    0,
                    (sum, val) => sum + val,
                  );
                  if (bidsSum == roundIndex) {
                    final lastPlayer = players.last;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.getWith('wizard_rule_uneven_error', [
                            lastPlayer.name,
                          ]),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                    return; // Prevent saving
                  }
                }

                ref
                    .read(wizardStateProvider.notifier)
                    .updateState(state.copyWith(currentRoundBids: bids));
                Navigator.pop(context);
              },
              child: Text(l10n.get('save')),
            ),
          ],
        );
      },
    );

    for (var c in bidControllers.values) {
      c.dispose();
    }
  }

  Future<void> _showResultsDialog(
    BuildContext context,
    WidgetRef ref,
    WizardGameState state,
    List<Player> players,
  ) async {
    final roundIndex = state.rounds.length + state.customStartRound;
    final Map<String, TextEditingController> trickControllers = {
      for (var p in players) p.id: TextEditingController(text: '0'),
    };
    final bombController = TextEditingController(text: '0');
    final Map<String, bool> playedDragon = {for (var p in players) p.id: false};
    final Map<String, bool> playedFairy = {for (var p in players) p.id: false};

    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(
            '${l10n.get('wizard_round')} $roundIndex — ${l10n.get('wizard_actuals')}',
          ),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final currentTricksSum = trickControllers.values
                    .map((c) => int.tryParse(c.text) ?? 0)
                    .fold(0, (a, b) => a + b);
                final currentBombs = int.tryParse(bombController.text) ?? 0;
                final totalSum = currentTricksSum + currentBombs;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.scoringVariant == WizardScoringVariant.extreme
                            ? 'Tricks: $currentTricksSum + Bombs: $currentBombs = $totalSum / $roundIndex'
                            : 'Total Tricks: $currentTricksSum / $roundIndex',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: totalSum == roundIndex
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.scoringVariant ==
                        WizardScoringVariant.extreme) ...[
                      TextField(
                        controller: bombController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.get('wizard_bombs'),
                          prefixIcon: const Icon(
                            Icons.emergency_share,
                            size: 20,
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                    ],
                    ...players.map((p) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${l10n.get('wizard_bid')}: ${state.currentRoundBids?[p.id] ?? 0}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: trickControllers[p.id],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      labelText: l10n.get('wizard_won'),
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            if (state.anniversaryCards)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FilterChip(
                                    label: const Text(
                                      'Dragon (+10)',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    selected: playedDragon[p.id]!,
                                    onSelected: (val) => setDialogState(
                                      () => playedDragon[p.id] = val,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  FilterChip(
                                    label: const Text(
                                      'Fairy (-10)',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    selected: playedFairy[p.id]!,
                                    onSelected: (val) => setDialogState(
                                      () => playedFairy[p.id] = val,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(
              onPressed: () => _saveResults(
                context,
                ref,
                state,
                players,
                roundIndex,
                trickControllers,
                bombController,
                playedDragon,
                playedFairy,
                l10n,
              ),
              child: Text(l10n.get('wizard_save_round')),
            ),
          ],
        );
      },
    );

    for (var c in trickControllers.values) {
      c.dispose();
    }
    bombController.dispose();
  }

  void _saveResults(
    BuildContext context,
    WidgetRef ref,
    WizardGameState state,
    List<Player> players,
    int roundIndex,
    Map<String, TextEditingController> trickControllers,
    TextEditingController bombController,
    Map<String, bool> playedDragon,
    Map<String, bool> playedFairy,
    AppLocalizations l10n,
  ) {
    final Map<String, int> tricks = {
      for (var p in players)
        p.id: int.tryParse(trickControllers[p.id]!.text) ?? 0,
    };

    final tricksSum = tricks.values.fold<int>(0, (sum, val) => sum + val);
    final bombTricks = int.tryParse(bombController.text) ?? 0;

    if (tricksSum + bombTricks != roundIndex) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.scoringVariant == WizardScoringVariant.extreme
                ? l10n.getWith('wizard_error_tricks_extreme', [
                    tricksSum.toString(),
                    bombTricks.toString(),
                    roundIndex.toString(),
                  ])
                : l10n.getWith('wizard_error_tricks', [
                    tricksSum.toString(),
                    roundIndex.toString(),
                  ]),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return; // Prevent saving if tricks don't match round number
    }

    final newRound = WizardRound(
      roundIndex: roundIndex,
      bids: state.currentRoundBids ?? {},
      tricks: tricks,
      blownTricks: bombTricks,
      playedDragon: playedDragon,
      playedFairy: playedFairy,
    );

    ref
        .read(wizardStateProvider.notifier)
        .updateState(
          state.copyWith(rounds: [...state.rounds, newRound], resetBids: true),
        );
    Navigator.pop(context);
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
              ref.read(wizardStateProvider.notifier).resetGame();
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
