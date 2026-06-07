import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../players/repository/player_repository.dart';
import '../../history/repository/session_repository.dart';
import '../../../core/models/player_model.dart';
import '../../../core/models/session_model.dart';

/// Leaderboard entry computed from session history.
class LeaderboardEntry {
  final Player player;
  final int gamesPlayed;
  final int gamesWon;
  final double winRate;
  final int totalScore;

  const LeaderboardEntry({
    required this.player,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.winRate,
    required this.totalScore,
  });
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String? _selectedGameType;

  bool _isLowestScoreBest(String gameType) {
    final clean = gameType.replaceAll('_digital', '');
    return clean == 'darts' || clean == 'romme';
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l10n.get('leaderboard_title'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            centerTitle: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
          ),
          sessionsAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (sessions) {
              final gameTypes = sessions
                  .where((s) => s.completed)
                  .map((s) => s.gameType)
                  .toSet()
                  .toList()
                ..sort();

              if (gameTypes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedGameType,
                          isExpanded: true,
                          hint: Text(l10n.get('filter_game_type')),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(l10n.get('all_games')),
                            ),
                            ...gameTypes.map((type) {
                              return DropdownMenuItem<String?>(
                                value: type,
                                child: Text(l10n.get('game_$type')),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedGameType = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          playersAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(l10n.getWith('error_msg', [e.toString()])),
              ),
            ),
            data: (players) => sessionsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(l10n.getWith('error_msg', [e.toString()])),
                ),
              ),
              data: (sessions) {
                final entries = _buildLeaderboard(players, sessions);
                if (entries.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emoji_events_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.get('leaderboard_empty'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = entries[index];
                      final medal = index == 0
                          ? '🥇'
                          : index == 1
                          ? '🥈'
                          : index == 2
                          ? '🥉'
                          : '${index + 1}.';
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(
                            medal,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            entry.player.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${entry.gamesPlayed} ${l10n.get('leaderboard_games')} · ${(entry.winRate * 100).toStringAsFixed(0)}% ${l10n.get('leaderboard_win_rate')}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${entry.gamesWon} ${l10n.get('leaderboard_wins')}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${l10n.get('leaderboard_score')}: ${entry.totalScore}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: entries.length),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<LeaderboardEntry> _buildLeaderboard(
    List<Player> players,
    List<Session> sessions,
  ) {
    final Map<String, int> gamesPlayed = {};
    final Map<String, int> gamesWon = {};
    final Map<String, int> totalScores = {};

    final filteredSessions = _selectedGameType != null
        ? sessions.where((s) => s.completed && s.gameType == _selectedGameType)
        : sessions.where((s) => s.completed);

    for (final session in filteredSessions) {
      if (session.scores.isEmpty) continue;

      final isLowestBest = _isLowestScoreBest(session.gameType);
      final winningScore = isLowestBest
          ? session.scores.values.reduce((a, b) => a < b ? a : b)
          : session.scores.values.reduce((a, b) => a > b ? a : b);

      for (final entry in session.scores.entries) {
        final pid = entry.key;
        gamesPlayed[pid] = (gamesPlayed[pid] ?? 0) + 1;
        totalScores[pid] = (totalScores[pid] ?? 0) + entry.value;
        if (entry.value == winningScore) {
          gamesWon[pid] = (gamesWon[pid] ?? 0) + 1;
        }
      }
    }

    final entries = players.where((p) => gamesPlayed.containsKey(p.id)).map((
      p,
    ) {
      final played = gamesPlayed[p.id] ?? 0;
      final won = gamesWon[p.id] ?? 0;
      return LeaderboardEntry(
        player: p,
        gamesPlayed: played,
        gamesWon: won,
        winRate: played > 0 ? won / played : 0,
        totalScore: totalScores[p.id] ?? 0,
      );
    }).toList()..sort((a, b) => b.gamesWon.compareTo(a.gamesWon));

    return entries;
  }
}
