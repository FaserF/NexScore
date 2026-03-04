import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/player_model.dart';
import '../repository/player_repository.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersState = ref.watch(playersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('players'))),
      body: playersState.when(
        data: (players) {
          if (players.isEmpty) {
            return Center(child: Text(l10n.get('no_players')));
          }
          return ListView.builder(
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    int.parse(player.avatarColor.replaceFirst('#', '0xff')),
                  ),
                  child: Text(
                    player.name.isNotEmpty
                        ? player.name.substring(0, 1).toUpperCase()
                        : '?',
                  ),
                ),
                title: Text(player.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _confirmDelete(context, ref, player);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text(l10n.getWith('error_msg', [err.toString()]))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddPlayerDialog(context, ref);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.get('add_player')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Player player) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('delete')),
        content: Text(l10n.getWith('players_delete_confirm', [player.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(playersProvider.notifier).deletePlayer(player.id);
              Navigator.pop(context);
            },
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.get('add_player')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.get('player_name')),
            autofocus: true,
            onSubmitted: (_) {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newPlayer = Player(
                  id: const Uuid().v4(),
                  name: name,
                  avatarColor: '#2196F3',
                );
                ref.read(playersProvider.notifier).addPlayer(newPlayer);
              }
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  final newPlayer = Player(
                    id: const Uuid().v4(),
                    name: name,
                    avatarColor: '#2196F3',
                  );
                  ref.read(playersProvider.notifier).addPlayer(newPlayer);
                }
                Navigator.pop(context);
              },
              child: Text(l10n.get('add')),
            ),
          ],
        );
      },
    );
  }
}
