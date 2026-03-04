import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/session_model.dart';
import '../../../core/models/player_model.dart';
import '../../history/repository/session_repository.dart';
import '../../players/repository/player_repository.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final playersAsync = ref.watch(playersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('history'))),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.getWith('error_msg', [e.toString()]))),
        data: (sessions) => playersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              Center(child: Text(l10n.getWith('error_msg', [e.toString()]))),
          data: (players) {
            final completed = sessions.where((s) => s.completed).toList()
              ..sort((a, b) => b.startTime.compareTo(a.startTime));

            if (completed.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.history, size: 80, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      l10n.get('history_no_sessions'),
                      style: const TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: completed.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = completed[index];
                return _SessionCard(session: session, players: players);
              },
            );
          },
        ),
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

    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            session.gameType.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          l10n.get('game_${session.gameType}'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(gameDate),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: l10n.get('history_share_tooltip'),
              onPressed: () => _shareResult(context, session, playerName),
            ),
            const Icon(Icons.expand_more),
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
          return ListTile(
            leading: Text(medal, style: const TextStyle(fontSize: 20)),
            title: Text(playerName(entry.key)),
            trailing: Text(
              '${entry.value} ${l10n.get('history_pts')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          );
        }).toList(),
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
