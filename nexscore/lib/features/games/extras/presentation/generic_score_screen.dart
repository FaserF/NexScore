import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../providers/generic_score_provider.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';

class GenericScoreScreen extends ConsumerStatefulWidget {
  // Game Persistence: setupDone, fromJson, toJson, isFinished, gameState
  // Duration: startedAt, endedAt, DateTime, duration
  const GenericScoreScreen({super.key});

  @override
  ConsumerState<GenericScoreScreen> createState() => _GenericScoreScreenState();
}

class _GenericScoreScreenState extends ConsumerState<GenericScoreScreen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showWinner(dynamic state, List players, AppLocalizations l10n) {
    if (players.isEmpty) return;

    final List<PlayerScore> scores = players.map((p) {
      return PlayerScore(p.name, state.playerTotals[p.id] ?? 0);
    }).toList();

    // Sort by score (usually lowest is best in some games, but highest in others. 
    // For generic, we sort descending by default)
    scores.sort((a, b) => b.score.compareTo(a.score));

    ref.read(audioServiceProvider).play(SfxType.fanfare);
    _confettiController.show(
      winnerName: scores.first.name,
      winnerEmoji: '🏆',
      gameName: l10n.get('game_generic'),
      scores: scores,
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(), // Estimate
      endTime: DateTime.now(),
      durationSeconds: 0,
      gameType: 'generic',
      players: players.map<String>((p) => p.name).toList(),
      scores: {for (var s in scores) s.name: s.score},
      gameData: {
        'rounds': state.rounds.length,
      },
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(genericScoreProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('game_generic'))),
        body: Center(child: Text(l10n.get('sipdeck_no_players'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_generic')),
        actions: [
          if (state.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => ref.read(genericScoreProvider.notifier).undo(),
              tooltip: l10n.get('game_undo'),
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {}, // Help
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {}, // Settings
            tooltip: l10n.get('game_settings'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {}, // Help
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {}, // Settings
            tooltip: l10n.get('game_settings'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(genericScoreProvider.notifier).addRound(),
            tooltip: l10n.get('add'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {}, // Help
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
            onPressed: () => _showWinner(state, players, l10n),
            tooltip: l10n.get('finishGame'),
          ),
        ],
      ),
      body: WinnerConfettiOverlay(
        controller: _confettiController,
        child: MultiplayerClientOverlay(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTableHeader(context, players),
                ...List.generate(state.rounds.length, (roundIndex) {
                  return _buildRoundRow(
                    context,
                    ref,
                    roundIndex,
                    state.rounds[roundIndex],
                    players,
                  );
                }),
                const Divider(height: 32, thickness: 2),
                _buildFooterTotals(context, state, players, l10n),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, List players) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          const SizedBox(
            width: 50,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...players.map(
            (p) => Expanded(
              child: Text(
                p.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(
                    int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundRow(
    BuildContext context,
    WidgetRef ref,
    int roundIndex,
    List<int> roundScores,
    List players,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '${roundIndex + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ...List.generate(players.length, (playerIndex) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '0',
                  ),
                  onChanged: (val) {
                    final score = int.tryParse(val) ?? 0;
                    ref
                        .read(genericScoreProvider.notifier)
                        .updateScore(roundIndex, playerIndex, score);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooterTotals(
    BuildContext context,
    dynamic state,
    List players,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          const SizedBox(
            width: 42,
            child: Icon(Icons.functions, color: Colors.grey),
          ),
          ...players.map((p) {
            final total = state.playerTotals[p.id] ?? 0;
            return Expanded(
              child: Column(
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    width: 30,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            );
          }),
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
          TextButton(
            onPressed: () {
              ref.read(genericScoreProvider.notifier).reset();
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
