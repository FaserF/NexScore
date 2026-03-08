import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/player_model.dart';
import '../../../core/models/player_group.dart';
import '../../players/repository/player_repository.dart';
import '../../players/repository/player_group_repository.dart';
import '../../../core/providers/active_players_provider.dart';
import '../../../core/providers/persistence_provider.dart';

class GameSetupScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameSetupScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  final Set<String> _selectedPlayerIds = {};

  int get _minPlayers {
    switch (widget.gameId) {
      case 'schafkopf':
        return 4;
      case 'arschloch':
        return 2;
      case 'sipdeck':
        return 2;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);
    final l10n = AppLocalizations.of(context);

    // Get game name for better UI
    final gameTranslationKey = 'game_${widget.gameId}';
    final gameName = l10n.get(gameTranslationKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_setup_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: () => _showPresetsSheet(context, ref),
            tooltip: l10n.get('presets_load'),
          ),
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: _selectedPlayerIds.isEmpty
                ? null
                : () => _showSaveGroupDialog(context, ref),
            tooltip: l10n.get('presets_save'),
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddPlayerDialog(context, ref),
            tooltip: l10n.get('add_player'),
          ),
        ],
      ),
      body: playersAsync.when(
        data: (players) {
          if (players.isEmpty) {
            return _buildEmptyState(context, l10n);
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.getWith('game_setup_choose_players', [gameName]),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final p = players[index];
                    final isSelected = _selectedPlayerIds.contains(p.id);
                    return CheckboxListTile(
                      title: Text(p.name),
                      secondary: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                        ),
                        child: Text(p.name.substring(0, 1).toUpperCase()),
                      ),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedPlayerIds.add(p.id);
                          } else {
                            _selectedPlayerIds.remove(p.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              if (_selectedPlayerIds.length < _minPlayers)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    l10n.getWith('game_setup_min_players', [
                      _minPlayers.toString(),
                    ]),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton(
                  onPressed: _selectedPlayerIds.length >= _minPlayers
                      ? () => _startGame(context, players)
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: Text(l10n.get('game_setup_start')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(l10n.get('no_players')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showAddPlayerDialog(context, ref),
            icon: const Icon(Icons.add),
            label: Text(l10n.get('add_player')),
          ),
        ],
      ),
    );
  }

  void _startGame(BuildContext context, List<Player> allPlayers) {
    final selectedPlayers = allPlayers
        .where((p) => _selectedPlayerIds.contains(p.id))
        .toList();

    ref.read(activePlayersProvider.notifier).setPlayers(selectedPlayers);
    ref.read(activeGameIdProvider.notifier).state = widget.gameId;

    // Support legacy providers where still needed (e.g. Wizard) until refactored
    if (widget.gameId == 'wizard') {
      context.push('/games/wizard');
    } else {
      context.push('/games/${widget.gameId}');
    }
  }

  void _showAddPlayerDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        void submit() {
          final name = controller.text.trim();
          if (name.isNotEmpty) {
            final newPlayer = Player(
              id: const Uuid().v4(),
              name: name,
              avatarColor: '#2196F3',
            );
            ref.read(playersProvider.notifier).addPlayer(newPlayer);
            setState(() {
              _selectedPlayerIds.add(newPlayer.id);
            });
          }
          Navigator.pop(dialogContext);
        }

        return AlertDialog(
          title: Text(l10n.get('add_player')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.get('player_name')),
            autofocus: true,
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(onPressed: submit, child: Text(l10n.get('add'))),
          ],
        );
      },
    );
  }

  void _showSaveGroupDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        void submit() async {
          final name = controller.text.trim();
          if (name.isNotEmpty) {
            final group = PlayerGroup(
              id: const Uuid().v4(),
              name: name,
              playerIds: _selectedPlayerIds.toList(),
            );
            final messenger = ScaffoldMessenger.of(context);
            final result = await ref
                .read(playerGroupsProvider.notifier)
                .addGroup(group);

            if (mounted) {
              if (result.isSuccess) {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.get('presets_save_success'))),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.get('presets_save_error'))),
                );
              }
            }
          }
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        }

        return AlertDialog(
          title: Text(l10n.get('presets_save')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: l10n.get('presets_name')),
            autofocus: true,
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(onPressed: submit, child: Text(l10n.get('add'))),
          ],
        );
      },
    );
  }

  void _showPresetsSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final groupsAsync = ref.watch(playerGroupsProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return groupsAsync.when(
          data: (groups) {
            if (groups.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(l10n.get('presets_empty')),
                ),
              );
            }
            return ListView.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return ListTile(
                  title: Text(group.name),
                  subtitle: Text('${group.playerIds.length} players'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      ref
                          .read(playerGroupsProvider.notifier)
                          .deleteGroup(group.id);
                    },
                  ),
                  onTap: () {
                    setState(() {
                      _selectedPlayerIds.clear();
                      _selectedPlayerIds.addAll(group.playerIds);
                    });
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        );
      },
    );
  }
}
