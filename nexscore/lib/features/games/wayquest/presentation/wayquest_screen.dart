import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/wayquest_models.dart';
import '../providers/wayquest_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../core/providers/tts_provider.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../settings/provider/settings_provider.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../core/providers/share_provider.dart';
import '../../../../shared/widgets/shareable_card.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';

class WayQuestScreen extends ConsumerStatefulWidget {
  const WayQuestScreen({super.key});

  // Game Persistence: setupDone, fromJson, toJson, isFinished, gameState

  @override
  ConsumerState<WayQuestScreen> createState() => _WayQuestScreenState();
}

class _WayQuestScreenState extends ConsumerState<WayQuestScreen> {
  final _confettiController = WinnerConfettiController();
  bool _showingWinnerSelection = false;

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wayQuestStateProvider);
    final l10n = AppLocalizations.of(context);

    ref.listen<WayQuestGameState>(wayQuestStateProvider, (previous, next) {
      if (next.playedCards.length > (previous?.playedCards.length ?? 0)) {
        // Play swipe sound
        ref.read(audioServiceProvider).play(SfxType.swipe);

        if (ref.read(ttsActiveProvider)) {
          final card = next.currentCard;
          if (card != null) {
            final ttsService = ref.read(ttsServiceProvider);
            final settings = ref.read(settingsProvider);
            final locale = settings.locale?.languageCode ?? 'en';
            ttsService.setLanguage(locale);
            ttsService.speak(card.text);
          }
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_wayquest')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(ttsActiveProvider) ? Icons.volume_up : Icons.volume_off,
              color: ref.watch(ttsActiveProvider)
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            onPressed: () {
              ref.read(ttsActiveProvider.notifier).toggle();
              final active = ref.read(ttsActiveProvider);
              if (!active) {
                ref.read(ttsServiceProvider).stop();
              }
            },
            tooltip: l10n.get('tts_toggle'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showCategoriesModal(context, ref, l10n),
            tooltip: l10n.get('wayquest_categories'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => launchUrl(
              Uri.parse(
                'https://faserf.github.io/NexScore/docs/user_guide/games/#wayquest',
              ),
              mode: LaunchMode.externalApplication,
            ),
            tooltip: l10n.get('nav_help'),
          ),
          if (state.canUndo)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: l10n.get('game_undo'),
              onPressed: () => ref.read(wayQuestStateProvider.notifier).undo(),
            ),
          if (state.playedCards.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.leaderboard_outlined),
              onPressed: () => _showScoreboard(context, ref, l10n),
              tooltip: l10n.get('wayquest_scoreboard'),
            ),
          if (state.playedCards.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _confirmFinish(context, ref, l10n),
              tooltip: l10n.get('finishGame'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
        ],
      ),
      body: WinnerConfettiOverlay(
        controller: _confettiController,
        child: MultiplayerClientOverlay(
          child: Center(
            child: state.playedCards.isEmpty
                ? _WayQuestSetup(l10n: l10n)
                : _buildGameView(state, l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildGameView(WayQuestGameState state, AppLocalizations l10n) {
    final players = ref.watch(activePlayersProvider);
    if (_showingWinnerSelection && players.length >= 2) {
      return _buildWinnerSelection(state, players, l10n);
    }
    return _WayQuestGame(
      l10n: l10n,
      state: state,
      onNextCard: () {
        final activePlayers = ref.read(activePlayersProvider);
        if (activePlayers.length >= 2) {
          setState(() => _showingWinnerSelection = true);
        } else {
          ref.read(wayQuestStateProvider.notifier).drawNextCard(activePlayers, l10n);
        }
      },
    );
  }

  Widget _buildWinnerSelection(
    WayQuestGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 48, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            l10n.get('wayquest_who_won'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...players.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FilledButton.tonal(
              onPressed: () {
                ref.read(wayQuestStateProvider.notifier).recordWinner(p.id, 1);
                setState(() => _showingWinnerSelection = false);
                ref.read(wayQuestStateProvider.notifier).drawNextCard(players, l10n);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(p.name, style: const TextStyle(fontSize: 18)),
            ),
          )),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              setState(() => _showingWinnerSelection = false);
              ref.read(wayQuestStateProvider.notifier).drawNextCard(players, l10n);
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(l10n.get('wayquest_nobody_won')),
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
          TextButton(
            onPressed: () {
              ref.read(wayQuestStateProvider.notifier).resetGame();
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
              ref.read(wayQuestStateProvider.notifier).finishGame();
              Navigator.pop(context);
              _showWinner(
                ref.read(wayQuestStateProvider),
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

  void _showWinner(WayQuestGameState state, List<Player> players) {
    if (players.isEmpty) return;

    final l10n = AppLocalizations.of(context);

    // Determine the winner from scores
    String winnerName = 'WayQuest';
    if (state.scores.isNotEmpty) {
      final sortedEntries = state.scores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topId = sortedEntries.first.key;
      final topPlayer = players.where((p) => p.id == topId);
      if (topPlayer.isNotEmpty) {
        winnerName = topPlayer.first.name;
      }
    }

    ref.read(audioServiceProvider).play(SfxType.fanfare);
    _confettiController.show(
      winnerName: winnerName,
      winnerEmoji: '\u{1F3C6}',
      gameName: l10n.get('game_wayquest'),
      scores: players.map((p) {
        return PlayerScore(p.name, state.scores[p.id] ?? 0);
      }).toList(),
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: state.startedAt ?? DateTime.now(),
      endTime: state.endedAt ?? DateTime.now(),
      durationSeconds: state.startedAt != null && state.endedAt != null
          ? state.endedAt!.difference(state.startedAt!).inSeconds
          : 0,
      gameType: 'wayquest',
      players: players.map<String>((p) => p.name).toList(),
      scores: { for (final p in players) p.name: state.scores[p.id] ?? 0 },
      gameData: {
        'playedQuests': state.playedCards.length,
      },
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);
  }

  void _showCategoriesModal(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                l10n.get('wayquest_categories'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final s = ref.watch(wayQuestStateProvider);
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: WayQuestCategory.values.map((cat) {
                      final isSelected = s.selectedCategories.contains(cat);
                      return FilterChip(
                        label: Text(l10n.get('wayquest_cat_\${cat.name}')),
                        selected: isSelected,
                        onSelected: (_) => ref
                            .read(wayQuestStateProvider.notifier)
                            .toggleCategory(cat),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('ok')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showScoreboard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final state = ref.read(wayQuestStateProvider);
    final players = ref.read(activePlayersProvider);
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) => (state.scores[b.id] ?? 0).compareTo(state.scores[a.id] ?? 0));

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.get('wayquest_scoreboard'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedPlayers.asMap().entries.map((entry) {
              final index = entry.key;
              final player = entry.value;
              final score = state.scores[player.id] ?? 0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: index == 0 ? Colors.amber : null,
                  child: Text('${index + 1}'),
                ),
                title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  l10n.getWith('wayquest_points', [score.toString()]),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: index == 0 ? Colors.amber.shade700 : null,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _WayQuestSetup extends ConsumerWidget {
  final AppLocalizations l10n;
  const _WayQuestSetup({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wayQuestStateProvider);
    final players = ref.watch(activePlayersProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.get('wayquest_categories'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: WayQuestCategory.values.map((cat) {
                final isSelected = state.selectedCategories.contains(cat);
                return Card(
                  elevation: isSelected ? 4 : 1,
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.5)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => ref
                        .read(wayQuestStateProvider.notifier)
                        .toggleCategory(cat),
                    title: Text(
                      l10n.get('wayquest_cat_${cat.name}'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    leading: _getCategoryIcon(cat),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (_) => ref
                          .read(wayQuestStateProvider.notifier)
                          .toggleCategory(cat),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ref
                  .read(wayQuestStateProvider.notifier)
                  .drawNextCard(players, l10n);
            },
            icon: const Icon(Icons.directions_car),
            label: Text(l10n.get('wayquest_start')),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCategoryIcon(WayQuestCategory cat) {
    switch (cat) {
      case WayQuestCategory.deepTalks:
        return const Icon(Icons.favorite, color: Colors.redAccent);
      case WayQuestCategory.wouldYouRather:
        return const Icon(Icons.compare_arrows, color: Colors.blueAccent);
      case WayQuestCategory.roadChallenges:
        return const Icon(Icons.map, color: Colors.green);
      case WayQuestCategory.hypotheticals:
        return const Icon(Icons.psychology, color: Colors.purpleAccent);
      case WayQuestCategory.storyStarters:
        return const Icon(Icons.auto_stories, color: Colors.orangeAccent);
    }
  }
}

class _WayQuestGame extends ConsumerWidget {
  final AppLocalizations l10n;
  final WayQuestGameState state;
  final VoidCallback onNextCard;
  const _WayQuestGame({required this.l10n, required this.state, required this.onNextCard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final currentCard = state.currentCard;

    if (currentCard == null) return const SizedBox.shrink();

    return Stack(
      children: [
        GestureDetector(
          onTap: onNextCard,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: Card(
                      key: ValueKey(
                        currentCard.id + state.playedCards.length.toString(),
                      ),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      color: _getCategoryColor(context, currentCard.category),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        width: double.infinity,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _getCategoryIcon(currentCard.category, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                l10n
                                    .get(
                                      'wayquest_cat_${currentCard.category.name}',
                                    )
                                    .toUpperCase(),
                                style: const TextStyle(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                currentCard.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    l10n.get('wayquest_tap_continue'),
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(shareServiceProvider)
                                          .shareWidget(
                                            context,
                                            ShareableCard(
                                              title: l10n.get(
                                                'wayquest_cat_${currentCard.category.name}',
                                              ),
                                              text: currentCard.text,
                                              baseColor: _getCategoryColor(
                                                context,
                                                currentCard.category,
                                              ),
                                              brandText: 'WayQuest',
                                            ),
                                            text:
                                                'Check out this WayQuest challenge! 🚗 #NexScore',
                                          );
                                    },
                                    icon: const Icon(
                                      Icons.share,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    tooltip: 'Share this challenge',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'QUEST ${state.playedCards.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(BuildContext context, WayQuestCategory cat) {
    switch (cat) {
      case WayQuestCategory.deepTalks:
        return Colors.red.shade400;
      case WayQuestCategory.wouldYouRather:
        return Colors.blue.shade400;
      case WayQuestCategory.roadChallenges:
        return Colors.green.shade400;
      case WayQuestCategory.hypotheticals:
        return Colors.purple.shade400;
      case WayQuestCategory.storyStarters:
        return Colors.orange.shade400;
    }
  }

  Widget _getCategoryIcon(WayQuestCategory cat, {double size = 24}) {
    IconData data;
    switch (cat) {
      case WayQuestCategory.deepTalks:
        data = Icons.favorite;
        break;
      case WayQuestCategory.wouldYouRather:
        data = Icons.compare_arrows;
        break;
      case WayQuestCategory.roadChallenges:
        data = Icons.map;
        break;
      case WayQuestCategory.hypotheticals:
        data = Icons.psychology;
        break;
      case WayQuestCategory.storyStarters:
        data = Icons.auto_stories;
        break;
    }
    return Icon(data, color: Colors.white, size: size);
  }
}
