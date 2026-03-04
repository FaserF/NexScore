import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/wizard_models.dart';

class WizardGameStateNotifier extends Notifier<WizardGameState> {
  @override
  WizardGameState build() => const WizardGameState();

  void updateState(WizardGameState newState) => state = newState;
}

final wizardStateProvider =
    NotifierProvider<WizardGameStateNotifier, WizardGameState>(
      WizardGameStateNotifier.new,
    );

class WizardScreen extends ConsumerWidget {
  const WizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, ref, state),
          ),
        ],
      ),
      body: Column(
        children: [
          // 2-player warning banner
          if (players.length == 2)
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
                      ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
                  child: Text(l10n.get('ok')),
                ),
              ],
            ),

          // Scoreboard
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final p = players[index];
                final score = WizardGameState.calculatePlayerScore(
                  p.id,
                  state.rounds,
                  lenient: state.scoringVariant == WizardScoringVariant.lenient,
                  extreme: state.scoringVariant == WizardScoringVariant.extreme,
                );
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                    ),
                    child: Text(p.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(p.name),
                  subtitle: Text(
                    l10n.getWith('wizard_history', [
                      state.rounds.length.toString(),
                    ]),
                  ),
                  trailing: Text(
                    score.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: score >= 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              },
            ),
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
                  subtitle: Text(
                    players
                        .map(
                          (p) =>
                              '${p.name}: ${l10n.get('wizard_bid')} ${round.bids[p.id] ?? 0} / ${l10n.get('wizard_won')} ${round.tricks[p.id] ?? 0}',
                        )
                        .join(' · '),
                  ),
                );
              }).toList(),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: () =>
                  _showRoundInputDialog(context, ref, state, players),
              icon: const Icon(Icons.add),
              label: Text(
                l10n.getWith('wizard_next_round', [
                  (state.rounds.length + 1).toString(),
                ]),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    WidgetRef ref,
    WizardGameState state,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.get('settings')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.get('settings_data'), // Reusing for variants
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
                  title: Text(
                    v.name[0].toUpperCase() + v.name.substring(1),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(label, style: const TextStyle(fontSize: 11)),
                  selected: isSelected,
                  onTap: () {
                    ref
                        .read(wizardStateProvider.notifier)
                        .updateState(state.copyWith(scoringVariant: v));
                    Navigator.pop(context);
                  },
                );
              }),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.get('wizard_rule_stiche')),
                subtitle: Text(l10n.get('wizard_rule_stiche_desc')),
                value: state.ruleSticheDuertenNichtAufgehen,
                onChanged: (val) {
                  ref
                      .read(wizardStateProvider.notifier)
                      .updateState(
                        state.copyWith(ruleSticheDuertenNichtAufgehen: val),
                      );
                  Navigator.pop(context);
                },
              ),
            ],
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
  }

  Future<void> _showRoundInputDialog(
    BuildContext context,
    WidgetRef ref,
    WizardGameState state,
    List<Player> players,
  ) async {
    final roundIndex = state.rounds.length + 1;
    final Map<String, TextEditingController> bidControllers = {
      for (var p in players) p.id: TextEditingController(text: '0'),
    };
    final Map<String, TextEditingController> trickControllers = {
      for (var p in players) p.id: TextEditingController(text: '0'),
    };

    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text('${l10n.get('wizard_round')} $roundIndex'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: players.map((p) {
                final isLastPlayer = p.id == players.last.id;
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
                        width: 70,
                        child: TextField(
                          controller: bidControllers[p.id],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.get('wizard_bid'),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: trickControllers[p.id],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          textInputAction: isLastPlayer
                              ? TextInputAction.done
                              : TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.get('wizard_won'),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: isLastPlayer
                              ? (_) {
                                  final newRound = WizardRound(
                                    roundIndex: roundIndex,
                                    bids: {
                                      for (var player in players)
                                        player.id:
                                            int.tryParse(
                                              bidControllers[player.id]!.text,
                                            ) ??
                                            0,
                                    },
                                    tricks: {
                                      for (var player in players)
                                        player.id:
                                            int.tryParse(
                                              trickControllers[player.id]!.text,
                                            ) ??
                                            0,
                                    },
                                  );
                                  ref
                                      .read(wizardStateProvider.notifier)
                                      .updateState(
                                        state.copyWith(
                                          rounds: [...state.rounds, newRound],
                                        ),
                                      );
                                  Navigator.pop(context);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final newRound = WizardRound(
                  roundIndex: roundIndex,
                  bids: {
                    for (var p in players)
                      p.id: int.tryParse(bidControllers[p.id]!.text) ?? 0,
                  },
                  tricks: {
                    for (var p in players)
                      p.id: int.tryParse(trickControllers[p.id]!.text) ?? 0,
                  },
                );
                ref
                    .read(wizardStateProvider.notifier)
                    .updateState(
                      state.copyWith(rounds: [...state.rounds, newRound]),
                    );
                Navigator.pop(context);
              },
              child: Text(l10n.get('wizard_save_round')),
            ),
          ],
        );
      },
    );

    for (var c in bidControllers.values) {
      c.dispose();
    }
    for (var c in trickControllers.values) {
      c.dispose();
    }
  }
}
