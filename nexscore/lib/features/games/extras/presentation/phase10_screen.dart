import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/phase10_models.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';

class Phase10StateNotifier extends Notifier<Phase10GameState> {
  final List<Phase10GameState> _history = [];

  @override
  Phase10GameState build() => const Phase10GameState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 20) _history.removeAt(0);
  }

  void setVariant(Phase10Variant variant) {
    _pushState();
    state = state.copyWith(
      variant: variant,
      playerStates: {}, // Reset on major variant change
      canUndo: _history.isNotEmpty,
    );
  }

  void setFullState(Phase10GameState newState) {
    _pushState();
    state = newState.copyWith(canUndo: _history.isNotEmpty);
  }

  void resetGame() {
    _history.clear();
    state = state.copyWith(playerStates: {}, canUndo: false);
  }

  void advancePhase(String playerId) {
    final currentState =
        state.playerStates[playerId] ?? const Phase10PlayerState();
    _pushState();
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

    state = state.copyWith(
      playerStates: updatedStates,
      canUndo: _history.isNotEmpty,
    );
  }

  void selectPhase(String playerId, int phase) {
    final currentState =
        state.playerStates[playerId] ?? const Phase10PlayerState();
    _pushState();
    final updatedStates = Map<String, Phase10PlayerState>.from(
      state.playerStates,
    );
    updatedStates[playerId] = currentState.copyWith(currentPhase: phase);
    state = state.copyWith(
      playerStates: updatedStates,
      canUndo: _history.isNotEmpty,
    );
  }

  void addPenaltyPoints(String playerId, int points) {
    final currentState =
        state.playerStates[playerId] ?? const Phase10PlayerState();
    _pushState();
    final updatedStates = Map<String, Phase10PlayerState>.from(
      state.playerStates,
    );
    updatedStates[playerId] = currentState.copyWith(
      totalScore: currentState.totalScore + points,
    );
    state = state.copyWith(
      playerStates: updatedStates,
      canUndo: _history.isNotEmpty,
    );
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }
}

final phase10StateProvider =
    NotifierProvider<Phase10StateNotifier, Phase10GameState>(
      Phase10StateNotifier.new,
    );

final phase10PlayersProvider = activePlayersProvider;

class Phase10Screen extends ConsumerStatefulWidget {
  const Phase10Screen({super.key});

  // Duration Tracking: startedAt, endedAt, DateTime, duration

  @override
  ConsumerState<Phase10Screen> createState() => _Phase10ScreenState();
}

class _Phase10ScreenState extends ConsumerState<Phase10Screen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showWinner(Phase10GameState gameState, List<Player> players) {
    if (players.isEmpty) return;

    final leaderIds = gameState.getLeaders();
    if (leaderIds.isEmpty) return;

    final winnerId = leaderIds.first;
    final winner = players.firstWhere((p) => p.id == winnerId);
    final l10n = AppLocalizations.of(context);

    // Sort scores (ascending is better in Phase 10 if same phase, but getLeaders handles it)
    // Actually, Phase 10 logic: Most phases, then fewest points.
    // getLeaders already returns them in correct order.
    final List<PlayerScore> sortedScores = leaderIds.map((id) {
      final p = players.firstWhere((player) => player.id == id);
      final pState = gameState.playerStates[id] ?? const Phase10PlayerState();
      return PlayerScore(p.name, pState.totalScore);
    }).toList();

    ref.read(audioServiceProvider).play(SfxType.fanfare);
    _confettiController.show(
      winnerName: winner.name,
      winnerEmoji: winner.emoji,
      gameName: l10n.get('game_phase10'),
      scores: sortedScores,
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(), // Estimate
      endTime: DateTime.now(),
      durationSeconds: 0,
      gameType: 'phase10',
      players: players.map<String>((p) => p.name).toList(),
      scores: {for (var s in sortedScores) s.name: s.score},
      gameData: {
        'variant': gameState.variant.name,
      },
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);
  }

  @override
  Widget build(BuildContext context) {
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
                  'https://faserf.github.io/NexScore/docs/user_guide/games/index.html#phase-10',
                ),
                mode: LaunchMode.externalApplication,
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
            onPressed: () => _showVariantDialog(context, gameState, l10n),
            tooltip: l10n.get('phase10_variant'),
          ),
          if (gameState.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => ref.read(phase10StateProvider.notifier).undo(),
              tooltip: l10n.get('game_undo'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, l10n),
            tooltip: l10n.get('game_reset'),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _showWinner(gameState, players),
            tooltip: l10n.get('finishGame'),
          ),
        ],
      ),
      body: WinnerConfettiOverlay(
        controller: _confettiController,
        child: MultiplayerClientOverlay(
          child: Column(
          children: [
            InkWell(
              onTap: () => _showPhaseLegend(context, gameState),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                      gameState.playerStates[p.id] ??
                      const Phase10PlayerState();
                  final isLeader = leaders.isNotEmpty && leaders.first == p.id;
                  final isLast =
                      leaders.isNotEmpty &&
                      leaders.last == p.id &&
                      players.length > 1;

                  final activePhases = gameState.activePhases.isNotEmpty
                      ? gameState.activePhases
                      : Phase10PhaseSet.original.phases;
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
                          ? const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            )
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
                                            Map<
                                              String,
                                              Phase10PlayerState
                                            >.from(gameState.playerStates);
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
                              _showPointsDialog(context, p, pState, l10n),
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
      ),
    ),
    );
  }

  void _showVariantDialog(
    BuildContext context,
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
    return FilledButton.tonalIcon(
      onPressed: () => _pickPhase(context),
      icon: const Icon(Icons.arrow_drop_down),
      label: Text(
        '${l10n.get('phase10_phase')} $currentPhase',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
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
