import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../models/standard_card_models.dart';
import '../models/arschloch_digital_state.dart';
import '../providers/arschloch_digital_provider.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';

class ArschlochDigitalScreen extends ConsumerStatefulWidget {
  const ArschlochDigitalScreen({super.key});

  // Game Persistence: setupDone, fromJson, toJson, isFinished, gameState

  @override
  ConsumerState<ArschlochDigitalScreen> createState() =>
      _ArschlochDigitalScreenState();
}

class _ArschlochDigitalScreenState
    extends ConsumerState<ArschlochDigitalScreen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arschlochDigitalProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digital ${l10n.get("game_arschloch")}'),
            if (state.startedAt != null)
              Text(
                'Seit ${state.startedAt!.hour}:${state.startedAt!.minute.toString().padLeft(2, "0")}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: const Icon(Icons.scoreboard_outlined),
            onPressed: () => _showScoreboard(context, state, players),
          ),
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => ref.read(arschlochDigitalProvider.notifier).undo(),
            tooltip: l10n.get('game_undo'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(arschlochDigitalProvider.notifier)
                .resetGame(), // Parity: reset
            tooltip: l10n.get('game_reset'),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _confirmFinish(context, ref, l10n),
            tooltip: l10n.get('finishGame'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://faserf.github.io/NexScore/docs/user_guide/games/#arschloch',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
            tooltip: l10n.get('nav_settings'),
          ),
        ],
      ),
      body: WinnerConfettiOverlay(
        controller: _confettiController,
        child: MultiplayerClientOverlay(
          child: _buildPhaseContent(context, ref, state, players, l10n),
        ),
      ),
    );
  }

  void _showWinner(ArschlochDigitalState state, List players) {
    if (players.isEmpty) return;

    final sortedPlayerIds = [...state.playerOrder]
      ..sort(
        (a, b) => (state.playerStates[b]?.totalPoints ?? 0).compareTo(
          state.playerStates[a]?.totalPoints ?? 0,
        ),
      );

    final winnerId = sortedPlayerIds.first;
    final winner = players.firstWhere((p) => p.id == winnerId);
    final l10n = AppLocalizations.of(context);

    final List<PlayerScore> scores = sortedPlayerIds.map((id) {
      final p = players.firstWhere((p) => p.id == id);
      return PlayerScore(p.name, state.playerStates[id]?.totalPoints ?? 0);
    }).toList();

    ref.read(audioServiceProvider).play(SfxType.fanfare);
    _confettiController.show(
      winnerName: winner.name,
      winnerEmoji: winner.emoji,
      gameName: l10n.get('game_arschloch'),
      scores: scores,
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: state.startedAt ?? DateTime.now(),
      endTime: DateTime.now(),
      durationSeconds: 0,
      gameType: 'arschloch_digital',
      players: players.map<String>((p) => p.name as String).toList(),
      scores: {for (var s in scores) s.name: s.score},
      gameData: {
        'round': state.roundNumber,
      },
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);
  }

  void _confirmFinish(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('wizard_end_game')),
        content: Text(l10n.get('game_finish_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(arschlochDigitalProvider.notifier).finishGame();
              Navigator.pop(context);
              _showWinner(
                ref.read(arschlochDigitalProvider),
                ref.read(activePlayersProvider),
              );
            },
            child: Text(
              l10n.get('ok'),
              style: const TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent(
    BuildContext context,
    WidgetRef ref,
    ArschlochDigitalState state,
    List players,
    AppLocalizations l10n,
  ) {
    switch (state.phase) {
      case ArschlochDigitalPhase.setup:
        return _buildSetup(context, ref, players);
      case ArschlochDigitalPhase.playing:
        return _buildPlaying(context, ref, state, players);
      case ArschlochDigitalPhase.roundEnd:
        return _buildRoundEnd(context, ref, state, players);
      case ArschlochDigitalPhase.cardSwap:
      case ArschlochDigitalPhase.finished:
        return _buildRoundEnd(context, ref, state, players);
    }
  }

  Widget _buildSetup(BuildContext context, WidgetRef ref, List players) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            Text(
              'Digital Arschloch',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wer wird Präsident, wer wird Arschloch?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Text(
              '${players.length} Spieler bereit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: players.length >= 3
                  ? () => ref
                        .read(arschlochDigitalProvider.notifier)
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
            if (players.length < 3) ...[
              const SizedBox(height: 16),
              const Text(
                'Mindestens 3 Spieler benötigt',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaying(
    BuildContext context,
    WidgetRef ref,
    ArschlochDigitalState state,
    List players,
  ) {
    final currentPlayer = players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => players.first,
    );
    final hand = state.playerStates[state.currentPlayerId]?.hand ?? [];
    final playableGroups = ref
        .read(arschlochDigitalProvider.notifier)
        .getPlayableGroups(state.currentPlayerId!);

    return Column(
      children: [
        // Pile area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Text(
                'Runde ${state.roundNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              if (state.currentPile.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Stapel leer — spiele frei!',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  children: state.currentPile
                      .map((c) => _StandardCardChip(card: c, large: true))
                      .toList(),
                ),
            ],
          ),
        ),
        // Player status bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: state.playerOrder.map((pid) {
              final player = players.firstWhere(
                (p) => p.id == pid,
                orElse: () => players.first,
              );
              final pState = state.playerStates[pid]!;
              final isActive = pid == state.currentPlayerId;
              return Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: isActive ? 18 : 14,
                      backgroundColor: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.3),
                      child: Text(
                        player.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: isActive ? 14 : 10,
                          color: isActive
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pState.hand.isEmpty ? '✓' : '${pState.hand.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        // Current player banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentPlayer.name} ist dran',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (playableGroups.isEmpty && state.currentPileRank > 0)
                const Text('Muss passen!', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        // Hand
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deine Karten:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: hand.map((card) {
                        final canPlay = playableGroups.any(
                          (g) => g.any((c) => c.id == card.id),
                        );
                        return GestureDetector(
                          onTap: canPlay
                              ? () {
                                  // Find the group containing this card and play it
                                  final group = playableGroups.firstWhere(
                                    (g) => g.any((c) => c.id == card.id),
                                    orElse: () => [],
                                  );
                                  if (group.isNotEmpty) {
                                    ref
                                        .read(arschlochDigitalProvider.notifier)
                                        .playCards(
                                          state.currentPlayerId!,
                                          group,
                                        );
                                  }
                                }
                              : null,
                          child: AnimatedOpacity(
                            opacity: canPlay ? 1.0 : 0.4,
                            duration: const Duration(milliseconds: 200),
                            child: _StandardCardWidget(
                              card: card,
                              isPlayable: canPlay,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Pass button
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: state.currentPileRank > 0
                ? () => ref
                      .read(arschlochDigitalProvider.notifier)
                      .pass(state.currentPlayerId!)
                : null,
            icon: const Icon(Icons.skip_next),
            label: const Text('Passen'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundEnd(
    BuildContext context,
    WidgetRef ref,
    ArschlochDigitalState state,
    List players,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Runde ${state.roundNumber} beendet!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: state.finishOrder.length,
              itemBuilder: (context, index) {
                final pid = state.finishOrder[index];
                final player = players.firstWhere(
                  (p) => p.id == pid,
                  orElse: () => players.first,
                );
                final pState = state.playerStates[pid]!;
                final rankLabel = _rankLabel(pState.currentRank);
                final rankColor = _rankColor(pState.currentRank);

                return Card(
                  color: rankColor.withValues(alpha: 0.1),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rankColor,
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
                    subtitle: Text(rankLabel),
                    trailing: Text(
                      '${pState.totalPoints} Pkt',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(arschlochDigitalProvider.notifier).nextRound(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Nächste Runde'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }

  void _showScoreboard(
    BuildContext context,
    ArschlochDigitalState state,
    List players,
  ) {
    // Sort by total points descending
    final sorted = List<String>.from(state.playerOrder)
      ..sort(
        (a, b) => (state.playerStates[b]?.totalPoints ?? 0).compareTo(
          state.playerStates[a]?.totalPoints ?? 0,
        ),
      );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spielstand'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sorted.map((pid) {
            final player = players.firstWhere(
              (p) => p.id == pid,
              orElse: () => players.first,
            );
            final pState = state.playerStates[pid]!;
            return ListTile(
              title: Text(player.name),
              subtitle: Text(_rankLabel(pState.currentRank)),
              trailing: Text(
                '${pState.totalPoints} Pkt',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _rankLabel(ArschlochRank? rank) {
    return switch (rank) {
      ArschlochRank.praesident => '👑 Präsident',
      ArschlochRank.vizePraesident => '🥈 Vize-Präsident',
      ArschlochRank.neutral => '😐 Neutral',
      ArschlochRank.vizeArschloch => '😬 Vize-Arschloch',
      ArschlochRank.arschloch => '💩 Arschloch',
      null => '—',
    };
  }

  Color _rankColor(ArschlochRank? rank) {
    return switch (rank) {
      ArschlochRank.praesident => Colors.amber,
      ArschlochRank.vizePraesident => Colors.blue,
      ArschlochRank.neutral => Colors.grey,
      ArschlochRank.vizeArschloch => Colors.orange,
      ArschlochRank.arschloch => Colors.brown,
      null => Colors.grey,
    };
  }
}

/// Compact standard card chip
class _StandardCardChip extends StatelessWidget {
  final StandardCard card;
  final bool large;

  const _StandardCardChip({required this.card, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = _suitColor(card.suit);
    return Container(
      width: large ? 50 : 40,
      height: large ? 70 : 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2),
        ],
      ),
      child: Center(
        child: Text(
          card.shortLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: large ? 14 : 10,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _suitColor(StandardSuit suit) {
    return switch (suit) {
      StandardSuit.hearts => Colors.red,
      StandardSuit.diamonds => Colors.red,
      StandardSuit.clubs => Colors.black,
      StandardSuit.spades => Colors.black,
    };
  }
}

/// Full card widget for player hand
class _StandardCardWidget extends StatelessWidget {
  final StandardCard card;
  final bool isPlayable;

  const _StandardCardWidget({required this.card, required this.isPlayable});

  @override
  Widget build(BuildContext context) {
    final color = _suitColor(card.suit);

    return Container(
      width: 55,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlayable ? color : Colors.grey.withValues(alpha: 0.3),
          width: isPlayable ? 2 : 1,
        ),
        boxShadow: isPlayable
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.shortLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _suitColor(StandardSuit suit) {
    return switch (suit) {
      StandardSuit.hearts => Colors.red,
      StandardSuit.diamonds => Colors.red,
      StandardSuit.clubs => Colors.black87,
      StandardSuit.spades => Colors.black87,
    };
  }
}
