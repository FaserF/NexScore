import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/phase10_models.dart';

class Phase10StateNotifier extends Notifier<Phase10GameState> {
  @override
  Phase10GameState build() => const Phase10GameState();

  void setVariant(Phase10Variant variant) {
    state = state.copyWith(
      variant: variant,
      playerStates: {}, // Reset on major variant change
    );
  }

  void setFullState(Phase10GameState newState) {
    state = newState;
  }

  void resetGame() {
    state = state.copyWith(playerStates: {});
  }

  void advancePhase(String playerId) {
    final currentState =
        state.playerStates[playerId] ?? const Phase10PlayerState();
    final updatedStates = Map<String, Phase10PlayerState>.from(
      state.playerStates,
    );

    final completed = Set<int>.from(currentState.completedPhases)
      ..add(currentState.currentPhase);

    int nextPhase = currentState.currentPhase;
    if (state.variant == Phase10Variant.original ||
        state.variant == Phase10Variant.levelUp) {
      nextPhase = (currentState.currentPhase + 1).clamp(
        1,
        state.activePhases.length,
      );
    }

    updatedStates[playerId] = currentState.copyWith(
      completedPhases: completed,
      currentPhase: nextPhase,
    );

    state = state.copyWith(playerStates: updatedStates);
  }

  void selectPhase(String playerId, int phase) {
    final currentState =
        state.playerStates[playerId] ?? const Phase10PlayerState();
    final updatedStates = Map<String, Phase10PlayerState>.from(
      state.playerStates,
    );
    updatedStates[playerId] = currentState.copyWith(currentPhase: phase);
    state = state.copyWith(playerStates: updatedStates);
  }

  void addPenaltyPoints(String playerId, int points) {
    final currentState =
        state.playerStates[playerId] ?? const Phase10PlayerState();
    final updatedStates = Map<String, Phase10PlayerState>.from(
      state.playerStates,
    );
    updatedStates[playerId] = currentState.copyWith(
      totalScore: currentState.totalScore + points,
    );
    state = state.copyWith(playerStates: updatedStates);
  }
}

final phase10StateProvider =
    NotifierProvider<Phase10StateNotifier, Phase10GameState>(
      Phase10StateNotifier.new,
    );

final phase10PlayersProvider = activePlayersProvider;

class Phase10Screen extends ConsumerWidget {
  const Phase10Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(phase10StateProvider);
    final players = ref.watch(phase10PlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('game_phase10'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    final leaders = gameState.getLeaders();
    final variantLabel = switch (gameState.variant) {
      Phase10Variant.original => l10n.get('phase10_original'),
      Phase10Variant.masters => l10n.get('phase10_masters'),
      Phase10Variant.levelUp => 'Level Up',
      Phase10Variant.duel => l10n.get('phase10_duel'),
      Phase10Variant.custom => 'Custom',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_phase10')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://faserf.github.io/NexScore/docs/user_guide/games/#phase-10',
                ),
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          Chip(
            label: Text(variantLabel),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showVariantDialog(context, ref, gameState, l10n),
            tooltip: l10n.get('phase10_variant'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
        ],
      ),
      body: Column(
        children: [
          InkWell(
            onTap: () => _showPhaseLegend(context, gameState),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    l10n.get('phase10_legend_tap'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: players.length,
              separatorBuilder: (context, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final p = players[index];
                final pState =
                    gameState.playerStates[p.id] ?? const Phase10PlayerState();
                final isLeader = leaders.isNotEmpty && leaders.first == p.id;
                final isLast =
                    leaders.isNotEmpty &&
                    leaders.last == p.id &&
                    players.length > 1;

                final activePhases = gameState.activePhases;
                final phaseNum = pState.currentPhase;
                final phase =
                    activePhases[(phaseNum - 1).clamp(
                      0,
                      activePhases.length - 1,
                    )];
                final phaseTitle = phase.title;
                final phaseDesc = phase.description;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                    ),
                    child: isLeader
                        ? const Icon(Icons.star, color: Colors.amber, size: 20)
                        : Text(p.name.substring(0, 1).toUpperCase()),
                  ),
                  title: Text(
                    p.name,
                    style: TextStyle(
                      fontWeight: isLeader
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isLast ? Colors.red : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$phaseTitle: $phaseDesc',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (gameState.variant == Phase10Variant.masters &&
                          pState.completedPhases.isNotEmpty)
                        Text(
                          l10n.getWith('phase10_done', [
                            pState.completedPhases.toList().join(', '),
                          ]),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.green.shade700),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (gameState.variant == Phase10Variant.masters ||
                          gameState.variant == Phase10Variant.duel)
                        _PhaseSelector(
                          currentPhase: pState.currentPhase,
                          completedPhases: pState.completedPhases,
                          onChanged: (pNum) => ref
                              .read(phase10StateProvider.notifier)
                              .selectPhase(p.id, pNum),
                          activePhases: activePhases,
                          l10n: l10n,
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: pState.currentPhase > 1
                                  ? () {
                                      final states =
                                          Map<String, Phase10PlayerState>.from(
                                            gameState.playerStates,
                                          );
                                      states[p.id] = pState.copyWith(
                                        currentPhase: pState.currentPhase - 1,
                                      );
                                      ref
                                          .read(phase10StateProvider.notifier)
                                          .setFullState(
                                            gameState.copyWith(
                                              playerStates: states,
                                            ),
                                          );
                                    }
                                  : null,
                            ),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${pState.currentPhase}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed:
                                  pState.currentPhase < activePhases.length
                                  ? () => ref
                                        .read(phase10StateProvider.notifier)
                                        .advancePhase(p.id)
                                  : null,
                            ),
                          ],
                        ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () =>
                            _showPointsDialog(context, ref, p, pState, l10n),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${pState.totalScore}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showVariantDialog(
    BuildContext context,
    WidgetRef ref,
    Phase10GameState state,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('phase10_variant')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Phase10Variant.values.map((v) {
            final title = switch (v) {
              Phase10Variant.original => l10n.get('phase10_original'),
              Phase10Variant.masters => l10n.get('phase10_masters'),
              Phase10Variant.levelUp => 'Level Up',
              Phase10Variant.duel => l10n.get('phase10_duel'),
              Phase10Variant.custom => 'Custom',
            };
            final label = switch (v) {
              Phase10Variant.original => l10n.get('phase10_v_desc_original'),
              Phase10Variant.masters => l10n.get('phase10_v_desc_masters'),
              Phase10Variant.levelUp => 'Higher rounds require more points.',
              Phase10Variant.duel => l10n.get('phase10_v_desc_duel'),
              Phase10Variant.custom => 'Custom phases.',
            };
            final isSelected = state.variant == v;
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
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(label, style: const TextStyle(fontSize: 11)),
              selected: isSelected,
              onTap: () {
                ref.read(phase10StateProvider.notifier).setVariant(v);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
        ],
      ),
    );
  }

  void _showPhaseLegend(BuildContext context, Phase10GameState gameState) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('phase10_legend_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: gameState.activePhases.map((phase) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        phase.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(child: Text(phase.description)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _showPointsDialog(
    BuildContext context,
    WidgetRef ref,
    Player player,
    Phase10PlayerState pState,
    AppLocalizations l10n,
  ) async {
    int pointsToAdd = 0;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${l10n.get('phase10_penalty')} – ${player.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.get('phase10_penalty_desc')),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() {
                          pointsToAdd = (pointsToAdd - 5).clamp(0, 995);
                        }),
                      ),
                      Text(
                        '+$pointsToAdd',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setState(() {
                          pointsToAdd = (pointsToAdd + 5).clamp(0, 995);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final pts in [5, 10, 25, 50])
                        ActionChip(
                          label: Text('+$pts'),
                          onPressed: () => setState(() => pointsToAdd += pts),
                        ),
                      ActionChip(
                        label: Text(l10n.get('clear')),
                        backgroundColor: Colors.redAccent.withValues(
                          alpha: 0.2,
                        ),
                        onPressed: () => setState(() => pointsToAdd = 0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: l10n.get('history_pts'),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) {
                        setState(() => pointsToAdd = parsed);
                      }
                    },
                    onSubmitted: (_) {
                      ref
                          .read(phase10StateProvider.notifier)
                          .addPenaltyPoints(player.id, pointsToAdd);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(phase10StateProvider.notifier)
                        .addPenaltyPoints(player.id, pointsToAdd);
                    Navigator.pop(context);
                  },
                  child: Text(l10n.get('add')),
                ),
              ],
            );
          },
        );
      },
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
              ref.read(phase10StateProvider.notifier).resetGame();
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

class _PhaseSelector extends StatelessWidget {
  final int currentPhase;
  final Set<int> completedPhases;
  final void Function(int) onChanged;
  final List<Phase10Phase> activePhases;
  final AppLocalizations l10n;

  const _PhaseSelector({
    required this.currentPhase,
    required this.completedPhases,
    required this.onChanged,
    required this.activePhases,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _pickPhase(context),
      child: Text('${l10n.get('phase10_phase')} $currentPhase'),
    );
  }

  void _pickPhase(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('phase10_pick_phase')),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: activePhases.map((phase) {
              final done = completedPhases.contains(phase.number);
              return ListTile(
                leading: done
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.radio_button_unchecked),
                title: Text(phase.title),
                subtitle: Text(
                  phase.description,
                  style: const TextStyle(fontSize: 11),
                ),
                selected: phase.number == currentPhase,
                onTap: () {
                  onChanged(phase.number);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
