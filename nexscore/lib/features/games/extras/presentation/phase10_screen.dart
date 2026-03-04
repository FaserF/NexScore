import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/phase10_models.dart';

class Phase10StateNotifier extends Notifier<Phase10GameState> {
  @override
  Phase10GameState build() => const Phase10GameState();

  void setVariant(Phase10Variant variant) {
    state = Phase10GameState(
      playerStates: state.playerStates,
      variant: variant,
    );
  }

  void setFullState(Phase10GameState newState) {
    state = newState;
  }

  void advancePhase(String playerId) {
    final currentState =
        state.playerStates[playerId] ?? const Phase10PlayerState();
    final updatedStates = Map<String, Phase10PlayerState>.from(
      state.playerStates,
    );

    if (state.variant == Phase10Variant.original) {
      updatedStates[playerId] = currentState.copyWith(
        currentPhase: (currentState.currentPhase + 1).clamp(1, 10),
      );
    } else {
      // Masters / Duel: mark current phase as completed, let user pick next
      final completed = Set<int>.from(currentState.completedPhases)
        ..add(currentState.currentPhase);
      updatedStates[playerId] = currentState.copyWith(
        completedPhases: completed,
        currentPhase: currentState.currentPhase,
      );
    }
    state = state.copyWith(playerStates: updatedStates);
  }

  void selectMastersPhase(String playerId, int phase) {
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

class Phase10PlayersNotifier extends Notifier<List<Player>> {
  @override
  List<Player> build() => [];

  void setPlayers(List<Player> players) => state = players;
}

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
      Phase10Variant.duel => l10n.get('phase10_duel'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_phase10')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
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
        ],
      ),
      body: Column(
        children: [
          // Phase legend button
          InkWell(
            onTap: () => _showPhaseLegend(context),
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

                final phase = Phase10Phase.values[pState.currentPhase - 1];
                final phaseTitle = _labelForPhase(phase, l10n, isTitle: true);
                final phaseDesc = _labelForPhase(phase, l10n, isTitle: false);

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
                            pState.completedPhases.toList().toString(),
                          ]),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.green.shade700),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (gameState.variant == Phase10Variant.masters)
                        _MastersPhaseSelector(
                          currentPhase: pState.currentPhase,
                          completedPhases: pState.completedPhases,
                          onChanged: (p) => ref
                              .read(phase10StateProvider.notifier)
                              .selectMastersPhase(p.toString(), p),
                          playerId: p.id,
                          ref: ref,
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
                              onPressed: pState.currentPhase < 10
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
              Phase10Variant.duel => l10n.get('phase10_duel'),
            };
            final label = switch (v) {
              Phase10Variant.original => l10n.get('phase10_v_desc_original'),
              Phase10Variant.masters => l10n.get('phase10_v_desc_masters'),
              Phase10Variant.duel => l10n.get('phase10_v_desc_duel'),
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

  void _showPhaseLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('phase10_legend_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: Phase10Phase.values.map((phase) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        _labelForPhase(phase, l10n, isTitle: true),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(_labelForPhase(phase, l10n, isTitle: false)),
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

  String _labelForPhase(
    Phase10Phase phase,
    AppLocalizations l10n, {
    required bool isTitle,
  }) {
    final num = phase.index + 1;
    if (isTitle) {
      return l10n.get('phase10_p${num}_title');
    } else {
      return l10n.get('phase10_p${num}_desc');
    }
  }
}

class _MastersPhaseSelector extends StatelessWidget {
  final int currentPhase;
  final Set<int> completedPhases;
  final void Function(int) onChanged;
  final String playerId;
  final WidgetRef ref;
  final AppLocalizations l10n;

  const _MastersPhaseSelector({
    required this.currentPhase,
    required this.completedPhases,
    required this.onChanged,
    required this.playerId,
    required this.ref,
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
            children: Phase10Phase.values.map((phase) {
              final done = completedPhases.contains(phase.number);
              return ListTile(
                leading: done
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.radio_button_unchecked),
                title: Text(l10n.get('phase10_p${phase.number}_title')),
                subtitle: Text(
                  l10n.get('phase10_p${phase.number}_desc'),
                  style: const TextStyle(fontSize: 11),
                ),
                selected: phase.number == currentPhase,
                onTap: () {
                  ref
                      .read(phase10StateProvider.notifier)
                      .selectMastersPhase(playerId, phase.number);
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
