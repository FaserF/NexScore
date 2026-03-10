import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../models/card_models.dart';
import '../models/wizard_digital_state.dart';
import '../providers/wizard_digital_provider.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';

class WizardDigitalScreen extends ConsumerStatefulWidget {
  const WizardDigitalScreen({super.key});

  // Game Persistence: setupDone, fromJson, toJson, isFinished, gameState

  @override
  ConsumerState<WizardDigitalScreen> createState() =>
      _WizardDigitalScreenState();
}

class _WizardDigitalScreenState extends ConsumerState<WizardDigitalScreen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardDigitalProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mystic Tricks — ${l10n.get("wizard_round")} ${state.currentRound}/${state.totalRounds}',
        ),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          if (state.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => ref.read(wizardDigitalProvider.notifier).undo(),
              tooltip: l10n.get('game_undo'),
            ),
          if (state.phase != WizardPhase.finished)
            IconButton(
              icon: const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
              ),
              onPressed: () => _confirmFinish(context, ref, l10n),
              tooltip: l10n.get('finishGame'),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://faserf.github.io/NexScore/docs/user_guide/games/#wizard',
                ),
                mode: LaunchMode.externalApplication,
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
            tooltip: l10n.get('game_settings'),
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

  void _showWinner(WizardDigitalState state, List<Player> players) {
    if (players.isEmpty) return;

    final sortedPlayerIds = [...state.playerOrder]
      ..sort(
        (a, b) =>
            (state.totalScores[b] ?? 0).compareTo(state.totalScores[a] ?? 0),
      );

    final winnerId = sortedPlayerIds.first;
    final winner = players.firstWhere((p) => p.id == winnerId);
    final l10n = AppLocalizations.of(context);

    final List<PlayerScore> scores = sortedPlayerIds.map((id) {
      final p = players.firstWhere((p) => p.id == id);
      return PlayerScore(p.name, state.totalScores[id] ?? 0);
    }).toList();

    ref.read(audioServiceProvider).play(SfxType.fanfare);
    _confettiController.show(
      winnerName: winner.name,
      winnerEmoji: winner.emoji,
      gameName: l10n.get('game_wizard'),
      scores: scores,
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(), // Estimate
      endTime: DateTime.now(),
      durationSeconds: 0,
      gameType: 'wizard_digital',
      players: players.map((p) => p.name).toList(),
      scores: {for (var s in scores) s.name: s.score},
      gameData: {
        'round': state.currentRound,
        'totalRounds': state.totalRounds,
      },
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);
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
              ref.read(wizardDigitalProvider.notifier).resetGame();
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
              ref.read(wizardDigitalProvider.notifier).finishGame();
              Navigator.pop(context);
              _showWinner(
                ref.read(wizardDigitalProvider),
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
    WizardDigitalState state,
    List players,
    AppLocalizations l10n,
  ) {
    switch (state.phase) {
      case WizardPhase.setup:
        return _buildSetup(context, ref, players);
      case WizardPhase.bidding:
        return _buildBidding(context, ref, state, players);
      case WizardPhase.playing:
        return _buildPlaying(context, ref, state, players);
      case WizardPhase.scoring:
        return _buildScoring(context, ref, state, players, l10n);
      case WizardPhase.finished:
        return _buildFinished(context, ref, state, players, l10n);
    }
  }

  Widget _buildSetup(BuildContext context, WidgetRef ref, List players) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            Text(
              'Mystic Tricks',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A Wizard-inspired trick-taking card game',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            Text(
              '${players.length} players ready',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: players.length >= 3
                  ? () {
                      ref
                          .read(wizardDigitalProvider.notifier)
                          .startGame(
                            players.map<String>((p) => p.id as String).toList(),
                          );
                    }
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Game'),
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
                'Minimum 3 players required',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBidding(
    BuildContext context,
    WidgetRef ref,
    WizardDigitalState state,
    List players,
  ) {
    final currentPlayer = players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => players.first,
    );
    final hand = state.hands[state.currentPlayerId] ?? [];

    return Column(
      children: [
        // Trump display
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Trump: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (state.trumpCard != null)
                _CardChip(card: state.trumpCard!)
              else
                const Text('No Trump'),
            ],
          ),
        ),
        // Current bids
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${currentPlayer.name}\'s turn to bid',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Show already placed bids
              ...state.bids.entries.map((entry) {
                final player = players.firstWhere(
                  (p) => p.id == entry.key,
                  orElse: () => players.first,
                );
                return ListTile(
                  title: Text(player.name),
                  trailing: Text(
                    'Bid: ${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }),
              const SizedBox(height: 24),
              // Hand preview
              Text(
                'Your cards:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: hand.map((c) => _CardChip(card: c)).toList(),
              ),
              const SizedBox(height: 24),
              // Bid selection
              Text(
                'Choose your bid (0-${state.currentRound}):',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(state.currentRound + 1, (i) {
                  return ChoiceChip(
                    label: Text('$i'),
                    selected: false,
                    onSelected: (_) {
                      ref
                          .read(wizardDigitalProvider.notifier)
                          .placeBid(state.currentPlayerId!, i);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaying(
    BuildContext context,
    WidgetRef ref,
    WizardDigitalState state,
    List players,
  ) {
    final currentPlayer = players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => players.first,
    );
    final hand = state.hands[state.currentPlayerId] ?? [];

    return Column(
      children: [
        // Trump + Trick area
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Trump: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (state.trumpSuit != null)
                        Text(
                          _suitLabel(state.trumpSuit!),
                          style: const TextStyle(fontSize: 16),
                        )
                      else
                        const Text('None', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Text(
                    'Trick ${state.completedTricks.length + 1}/${state.currentRound}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Cards played in current trick
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: state.playerOrder.map((pid) {
                  final card = state.currentTrick.playedCards[pid];
                  final player = players.firstWhere(
                    (p) => p.id == pid,
                    orElse: () => players.first,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      children: [
                        Text(
                          player.name,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: pid == state.currentPlayerId
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        card != null
                            ? _CardChip(card: card, large: true)
                            : Container(
                                width: 50,
                                height: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: pid == state.currentPlayerId
                                    ? const Center(
                                        child: Icon(
                                          Icons.hourglass_top,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
                                      )
                                    : null,
                              ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        // Player info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentPlayer.name}\'s turn',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Bid: ${state.bids[state.currentPlayerId] ?? "?"}  |  Won: ${state.tricksWon[state.currentPlayerId] ?? 0}',
              ),
            ],
          ),
        ),
        // Player's hand
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Hand:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: hand.map((card) {
                        final isValid = ref
                            .read(wizardDigitalProvider.notifier)
                            .isValidPlay(state.currentPlayerId!, card);
                        return GestureDetector(
                          onTap: isValid
                              ? () {
                                  ref
                                      .read(wizardDigitalProvider.notifier)
                                      .playCard(state.currentPlayerId!, card);
                                }
                              : null,
                          child: AnimatedOpacity(
                            opacity: isValid ? 1.0 : 0.4,
                            duration: const Duration(milliseconds: 200),
                            child: _CardWidget(card: card, isPlayable: isValid),
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
      ],
    );
  }

  Widget _buildScoring(
    BuildContext context,
    WidgetRef ref,
    WizardDigitalState state,
    List players,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Round ${state.currentRound} Results',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: state.playerOrder.map((pid) {
                final player = players.firstWhere(
                  (p) => p.id == pid,
                  orElse: () => players.first,
                );
                final bid = state.bids[pid] ?? 0;
                final won = state.tricksWon[pid] ?? 0;
                final correct = bid == won;
                return Card(
                  color: correct
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  child: ListTile(
                    title: Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Bid: $bid  |  Won: $won'),
                    trailing: Text(
                      correct
                          ? '+${20 + 10 * won}'
                          : '-${10 * (bid - won).abs()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: correct ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(wizardDigitalProvider.notifier).nextRound(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next Round'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinished(
    BuildContext context,
    WidgetRef ref,
    WizardDigitalState state,
    List players,
    AppLocalizations l10n,
  ) {
    final sortedPlayers = [...state.playerOrder]
      ..sort(
        (a, b) =>
            (state.totalScores[b] ?? 0).compareTo(state.totalScores[a] ?? 0),
      );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Game Over!',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final pid = sortedPlayers[index];
                final player = players.firstWhere(
                  (p) => p.id == pid,
                  orElse: () => players.first,
                );
                final score = state.totalScores[pid] ?? 0;
                return Card(
                  color: index == 0
                      ? Colors.amber.withValues(alpha: 0.15)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0
                          ? Colors.amber
                          : index == 1
                          ? Colors.grey
                          : index == 2
                          ? Colors.brown.shade300
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '$score pts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: index == 0 ? Colors.amber.shade800 : null,
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
                ref.read(wizardDigitalProvider.notifier).resetGame(),
            icon: const Icon(Icons.replay),
            label: const Text('Play Again'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }



  String _suitLabel(CardSuit suit) {
    switch (suit) {
      case CardSuit.flame:
        return '🔥 Flame';
      case CardSuit.frost:
        return '❄️ Frost';
      case CardSuit.earth:
        return '🌿 Earth';
      case CardSuit.wind:
        return '💨 Wind';
    }
  }
}

/// Small chip representation of a card
class _CardChip extends StatelessWidget {
  final GameCard card;
  final bool large;

  const _CardChip({required this.card, this.large = false});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    switch (card.type) {
      case CardType.wizard:
        bgColor = Colors.deepPurple;
        break;
      case CardType.jester:
        bgColor = Colors.grey;
        break;
      case CardType.normal:
        bgColor = _suitColor(card.suit!);
        break;
    }

    return Container(
      width: large ? 50 : 40,
      height: large ? 70 : 32,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bgColor, width: 1.5),
      ),
      child: Center(
        child: Text(
          card.shortLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: large ? 14 : 11,
            color: bgColor,
          ),
        ),
      ),
    );
  }

  Color _suitColor(CardSuit suit) {
    switch (suit) {
      case CardSuit.flame:
        return Colors.red;
      case CardSuit.frost:
        return Colors.blue;
      case CardSuit.earth:
        return Colors.green;
      case CardSuit.wind:
        return Colors.cyan;
    }
  }
}

/// Full card widget for the player's hand
class _CardWidget extends StatelessWidget {
  final GameCard card;
  final bool isPlayable;

  const _CardWidget({required this.card, required this.isPlayable});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    IconData iconData;

    switch (card.type) {
      case CardType.wizard:
        bgColor = Colors.deepPurple;
        iconData = Icons.auto_awesome;
        break;
      case CardType.jester:
        bgColor = Colors.grey;
        iconData = Icons.sentiment_very_satisfied;
        break;
      case CardType.normal:
        bgColor = _suitColor(card.suit!);
        iconData = _suitIcon(card.suit!);
        break;
    }

    return Container(
      width: 65,
      height: 95,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor.withValues(alpha: 0.1),
            bgColor.withValues(alpha: 0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlayable ? bgColor : Colors.grey.withValues(alpha: 0.3),
          width: isPlayable ? 2 : 1,
        ),
        boxShadow: isPlayable
            ? [
                BoxShadow(
                  color: bgColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: bgColor, size: 24),
          const SizedBox(height: 4),
          Text(
            card.shortLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: bgColor,
            ),
          ),
          if (card.type == CardType.normal)
            Text(
              '${card.value}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: bgColor,
              ),
            ),
        ],
      ),
    );
  }

  Color _suitColor(CardSuit suit) {
    switch (suit) {
      case CardSuit.flame:
        return Colors.red;
      case CardSuit.frost:
        return Colors.blue;
      case CardSuit.earth:
        return Colors.green;
      case CardSuit.wind:
        return Colors.cyan;
    }
  }

  IconData _suitIcon(CardSuit suit) {
    switch (suit) {
      case CardSuit.flame:
        return Icons.local_fire_department;
      case CardSuit.frost:
        return Icons.ac_unit;
      case CardSuit.earth:
        return Icons.eco;
      case CardSuit.wind:
        return Icons.air;
    }
  }
}
