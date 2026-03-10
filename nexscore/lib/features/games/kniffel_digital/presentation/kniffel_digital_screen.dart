import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../models/kniffel_digital_engine.dart';
import '../providers/kniffel_digital_provider.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';
class KniffelDigitalScreen extends ConsumerStatefulWidget {
  const KniffelDigitalScreen({super.key});

  // Game Persistence: setupDone, fromJson, toJson, isFinished, gameState

  @override
  ConsumerState<KniffelDigitalScreen> createState() => _KniffelDigitalScreenState();
}

class _KniffelDigitalScreenState extends ConsumerState<KniffelDigitalScreen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kniffelDigitalProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_kniffel')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          if (state.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => ref.read(kniffelDigitalProvider.notifier).undo(),
              tooltip: l10n.get('game_undo'),
            ),
          if (state.phase != KniffelDigitalPhase.setup &&
              state.phase != KniffelDigitalPhase.finished)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _confirmFinishEarly(context, ref, l10n),
              tooltip: l10n.get('finishGame'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Placeholder for game settings
            },
            tooltip: l10n.get('game_settings'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Documentation link opened externally
            },
          ),
        ],
      ),
      body: WinnerConfettiOverlay(
        controller: _confettiController,
        child: MultiplayerClientOverlay(
          child: _buildContent(context, ref, state, players),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    KniffelDigitalState state,
    List players,
  ) {
    switch (state.phase) {
      case KniffelDigitalPhase.setup:
        return _buildSetup(context, ref, players);
      case KniffelDigitalPhase.rolling:
      case KniffelDigitalPhase.scoring:
        return _buildPlaying(context, ref, state, players);
      case KniffelDigitalPhase.finished:
      case KniffelDigitalPhase.roundEnd:
        return _buildFinished(context, state, players);
    }
  }

  Widget _buildSetup(BuildContext context, WidgetRef ref, List players) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, size: 80, color: Colors.deepOrange),
            const SizedBox(height: 24),
            Text(
              'Digital Kniffel',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '5 Würfel, 13 Kategorien, wer holt die meisten Punkte?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: players.isNotEmpty
                  ? () => ref
                        .read(kniffelDigitalProvider.notifier)
                        .startGame(
                          players.map<String>((p) => p.id as String).toList(),
                        )
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Spiel starten'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(250, 60),
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

  Widget _buildPlaying(
    BuildContext context,
    WidgetRef ref,
    KniffelDigitalState state,
    List players,
  ) {
    final currentPlayer = players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => players.first,
    );
    final pState = state.playerStates[state.currentPlayerId!]!;
    final available = ref
        .read(kniffelDigitalProvider.notifier)
        .getAvailableCategories();

    return Column(
      children: [
        // Player & round info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentPlayer.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Runde ${state.roundNumber}/13 · Würfe: ${state.rollsLeft}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        // Dice area
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: state.rollsLeft < 3
                    ? () => ref
                          .read(kniffelDigitalProvider.notifier)
                          .toggleHold(i)
                    : null,
                child: _DieWidget(
                  value: state.dice[i],
                  isHeld: state.held[i],
                  hasRolled: state.rollsLeft < 3,
                ),
              );
            }),
          ),
        ),
        // Roll button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: FilledButton.icon(
            onPressed: state.rollsLeft > 0
                ? () => ref.read(kniffelDigitalProvider.notifier).rollDice()
                : null,
            icon: const Icon(Icons.casino),
            label: Text(
              state.rollsLeft == 3
                  ? 'Würfeln!'
                  : 'Nochmal würfeln (${state.rollsLeft})',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Scoring categories
        if (state.phase == KniffelDigitalPhase.scoring)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Kategorie wählen:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                ..._buildUpperSection(ref, state, available),
                const Divider(),
                ListTile(
                  dense: true,
                  title: const Text('Oberer Bonus'),
                  trailing: Text(
                    '${pState.upperSum}/63 ${pState.upperBonus > 0 ? "(+35!)" : ""}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: pState.upperBonus > 0 ? Colors.green : null,
                    ),
                  ),
                ),
                const Divider(),
                ..._buildLowerSection(ref, state, available),
              ],
            ),
          )
        else
          const Expanded(
            child: Center(
              child: Text(
                'Würfle zuerst!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildUpperSection(
    WidgetRef ref,
    KniffelDigitalState state,
    List<KniffelCategory> available,
  ) {
    final categories = [
      (KniffelCategory.ones, 'Einser (1)'),
      (KniffelCategory.twos, 'Zweier (2)'),
      (KniffelCategory.threes, 'Dreier (3)'),
      (KniffelCategory.fours, 'Vierer (4)'),
      (KniffelCategory.fives, 'Fünfer (5)'),
      (KniffelCategory.sixes, 'Sechser (6)'),
    ];
    return categories
        .map(
          (entry) =>
              _buildCategoryTile(ref, state, entry.$1, entry.$2, available),
        )
        .toList();
  }

  List<Widget> _buildLowerSection(
    WidgetRef ref,
    KniffelDigitalState state,
    List<KniffelCategory> available,
  ) {
    final categories = [
      (KniffelCategory.threeOfAKind, 'Dreierpasch'),
      (KniffelCategory.fourOfAKind, 'Viererpasch'),
      (KniffelCategory.fullHouse, 'Full House (25)'),
      (KniffelCategory.smallStraight, 'Kleine Straße (30)'),
      (KniffelCategory.largeStraight, 'Große Straße (40)'),
      (KniffelCategory.kniffel, 'Kniffel! (50)'),
      (KniffelCategory.chance, 'Chance'),
    ];
    return categories
        .map(
          (entry) =>
              _buildCategoryTile(ref, state, entry.$1, entry.$2, available),
        )
        .toList();
  }

  Widget _buildCategoryTile(
    WidgetRef ref,
    KniffelDigitalState state,
    KniffelCategory category,
    String label,
    List<KniffelCategory> available,
  ) {
    final pState = state.playerStates[state.currentPlayerId!]!;
    final isAvailable = available.contains(category);
    final existing = pState.scores[category];
    final potentialScore = isAvailable
        ? ref.read(kniffelDigitalProvider.notifier).calculateScore(category)
        : null;

    return ListTile(
      dense: true,
      title: Text(
        label,
        style: TextStyle(
          color: isAvailable ? null : Colors.grey,
          fontWeight: isAvailable ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: existing != null
          ? Text(
              '$existing',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          : potentialScore != null
          ? Chip(
              label: Text('$potentialScore'),
              backgroundColor: potentialScore > 0
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.1),
            )
          : null,
      onTap: isAvailable && state.phase == KniffelDigitalPhase.scoring
          ? () => ref
                .read(kniffelDigitalProvider.notifier)
                .scoreCategory(category)
          : null,
    );
  }

  Widget _buildFinished(
    BuildContext context,
    KniffelDigitalState state,
    List players,
  ) {
    final sorted = List<String>.from(state.playerOrder)
      ..sort(
        (a, b) => (state.playerStates[b]?.totalScore ?? 0).compareTo(
          state.playerStates[a]?.totalScore ?? 0,
        ),
      );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Spiel beendet!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final pid = sorted[index];
                final player = players.firstWhere(
                  (p) => p.id == pid,
                  orElse: () => players.first,
                );
                final pState = state.playerStates[pid]!;
                return Card(
                  color: index == 0
                      ? Colors.amber.withValues(alpha: 0.15)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0 ? Colors.amber : Colors.grey,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Obere: ${pState.upperSum} + Bonus: ${pState.upperBonus} + Untere: ${pState.lowerSum}',
                    ),
                    trailing: Text(
                      '${pState.totalScore}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                );
              },
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
        title: Text(l10n.get('finishGame')),
        content: Text(l10n.get('finishGameConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final state = ref.read(kniffelDigitalProvider);
              final players = ref.read(activePlayersProvider);
              _showWinner(context, state, players);
              ref.read(kniffelDigitalProvider.notifier).finishGame();
              Navigator.pop(context);
            },
            child: Text(l10n.get('ok')),
          ),
        ],
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
          FilledButton(
            onPressed: () {
              ref.read(kniffelDigitalProvider.notifier).resetGame();
              Navigator.pop(context);
            },
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
  }
  void _showWinner(
    BuildContext context,
    KniffelDigitalState state,
    List players,
  ) {
    if (players.isEmpty) return;

    final sorted = List<String>.from(state.playerOrder)
      ..sort(
        (a, b) => (state.playerStates[b]?.totalScore ?? 0).compareTo(
          state.playerStates[a]?.totalScore ?? 0,
        ),
      );

    final winnerId = sorted.first;
    final winner = players.firstWhere((p) => p.id == winnerId);
    final l10n = AppLocalizations.of(context);

    final List<PlayerScore> scores = sorted.map((id) {
      final p = players.firstWhere((p) => p.id == id);
      return PlayerScore(p.name, state.playerStates[id]?.totalScore ?? 0);
    }).toList();

    ref.read(audioServiceProvider).play(SfxType.fanfare);
    _confettiController.show(
      winnerName: winner.name,
      winnerEmoji: '🎲',
      gameName: l10n.get('game_kniffel'),
      scores: scores,
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(), // Estimate
      endTime: DateTime.now(),
      durationSeconds: 0,
      gameType: 'kniffel_digital',
      players: players.map<String>((p) => p.name as String).toList(),
      scores: {for (var s in scores) s.name: s.score},
      gameData: {
        'round': state.roundNumber,
      },
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);
  }
}

/// Interactive die widget with hold indicator.
class _DieWidget extends StatelessWidget {
  final int value;
  final bool isHeld;
  final bool hasRolled;

  const _DieWidget({
    required this.value,
    required this.isHeld,
    required this.hasRolled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isHeld
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHeld
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.withValues(alpha: 0.3),
          width: isHeld ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHeld
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: isHeld ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hasRolled ? _dieEmoji(value) : '🎲',
              style: const TextStyle(fontSize: 24),
            ),
            if (isHeld)
              Text(
                'HALTEN',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _dieEmoji(int value) {
    return switch (value) {
      1 => '⚀',
      2 => '⚁',
      3 => '⚂',
      4 => '⚃',
      5 => '⚄',
      6 => '⚅',
      _ => '🎲',
    };
  }
}
