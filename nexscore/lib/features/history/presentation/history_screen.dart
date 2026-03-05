import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/session_model.dart';
import '../../../core/models/player_model.dart';
import '../../history/repository/session_repository.dart';
import '../../players/repository/player_repository.dart';
import '../../../core/theme/widgets/glass_container.dart';
import '../../../core/theme/widgets/animated_scale_button.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final playersAsync = ref.watch(playersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l10n.get('history'),
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
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(l10n.getWith('error_msg', [e.toString()])),
              ),
            ),
            data: (sessions) => playersAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(l10n.getWith('error_msg', [e.toString()])),
                ),
              ),
              data: (players) {
                final completed = sessions.where((s) => s.completed).toList()
                  ..sort((a, b) => b.startTime.compareTo(a.startTime));

                if (completed.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off,
                            size: 80,
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.get('history_no_sessions'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 140),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final session = completed[index];
                      return _SessionCard(session: session, players: players);
                    }, childCount: completed.length),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final List<Player> players;

  const _SessionCard({required this.session, required this.players});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Build display of top players
    final sortedScores = session.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String playerName(String id) => players
        .firstWhere(
          (p) => p.id == id,
          orElse: () => Player(
            id: id,
            name: id.substring(0, 6),
            avatarColor: '#888888',
            ownerUid: null,
          ),
        )
        .name;

    final gameDate =
        '${session.startTime.day}.${session.startTime.month}.${session.startTime.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        borderRadius: 24,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 20,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  session.gameType.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            title: Text(
              l10n.get('game_${session.gameType}'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                gameDate,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScaleButton(
                  onPressed: () => _shareResult(context, session, playerName),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.ios_share,
                      size: 20,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            children: sortedScores.map((entry) {
              final rank = sortedScores.indexOf(entry) + 1;
              final medal = rank == 1
                  ? '🥇'
                  : rank == 2
                  ? '🥈'
                  : rank == 3
                  ? '🥉'
                  : '  $rank.';
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        medal,
                        style: const TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        playerName(entry.key),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rank == 1
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value} ${l10n.get('history_pts')}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rank == 1
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _shareResult(
    BuildContext context,
    Session session,
    String Function(String) playerName,
  ) {
    final l10n = AppLocalizations.of(context);
    final sortedScores = session.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final gameName = l10n.get('game_${session.gameType}');
    final lines = <String>[
      '🏆 NexScore – $gameName ${l10n.get('history')}',
      '',
      ...sortedScores.mapIndexed((index, entry) {
        final medal = index == 0
            ? '🥇'
            : index == 1
            ? '🥈'
            : index == 2
            ? '🥉'
            : '${index + 1}.';
        return '$medal ${playerName(entry.key)}: ${entry.value} ${l10n.get('history_pts')}';
      }),
    ];

    final text = lines.join('\n');

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.get('history_copied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

extension _IndexedIterable<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}
