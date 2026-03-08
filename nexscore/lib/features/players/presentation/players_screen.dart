import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/player_model.dart';
import '../repository/player_repository.dart';
import '../repository/player_group_repository.dart';
import '../../../core/models/player_group.dart';
import '../../../core/theme/widgets/animated_scale_button.dart';
import '../../../core/theme/widgets/glass_container.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersState = ref.watch(playersProvider);
    final groupsState = ref.watch(playerGroupsProvider);
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.get('players'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.get('players')),
              Tab(text: l10n.get('settings_presets')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Players Tab
            _buildPlayersTab(context, ref, playersState, l10n),
            // Groups Tab
            _buildGroupsTab(context, ref, groupsState, playersState, l10n),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            return FloatingActionButton(
              onPressed: () {
                if (DefaultTabController.of(context).index == 0) {
                  _showAddPlayerDialog(context, ref);
                } else {
                  _showAddGroupDialog(context, ref);
                }
              },
              elevation: 4,
              child: const Icon(Icons.add),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayersTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Player>> playersState,
    AppLocalizations l10n,
  ) {
    return playersState.when(
      data: (players) {
        if (players.isEmpty) {
          return _buildEmptyState(
            context,
            l10n,
            l10n.get('no_players'),
            Icons.person_off_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            return _buildPlayerItem(context, ref, player, l10n);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text(l10n.getWith('error_msg', [err.toString()]))),
    );
  }

  Widget _buildGroupsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<PlayerGroup>> groupsState,
    AsyncValue<List<Player>> playersState,
    AppLocalizations l10n,
  ) {
    return groupsState.when(
      data: (groups) {
        if (groups.isEmpty) {
          return _buildEmptyState(
            context,
            l10n,
            l10n.get('presets_empty'),
            Icons.group_off_outlined,
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return _buildGroupItem(context, ref, group, playersState, l10n);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text(l10n.getWith('error_msg', [err.toString()]))),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    String message,
    IconData icon,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerItem(
    BuildContext context,
    WidgetRef ref,
    Player player,
    AppLocalizations l10n,
  ) {
    final playerColor = _parseColor(player.avatarColor);
    final initial = player.name.isNotEmpty
        ? player.name.substring(0, 1).toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedScaleButton(
        onPressed: () {},
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [playerColor.withValues(alpha: 0.8), playerColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: playerColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: player.emoji != null
                      ? Text(
                          player.emoji!,
                          style: const TextStyle(fontSize: 24),
                        )
                      : Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  player.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _showEditPlayerDialog(context, ref, player),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _confirmDeletePlayer(context, ref, player),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupItem(
    BuildContext context,
    WidgetRef ref,
    PlayerGroup group,
    AsyncValue<List<Player>> playersState,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AnimatedScaleButton(
        onPressed: () {},
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.group),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${group.playerIds.length} ${l10n.get('players').toLowerCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => _showEditGroupDialog(context, ref, group),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _confirmDeleteGroup(context, ref, group),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.blue;
    }
  }

  void _confirmDeletePlayer(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.get('delete')),
        content: Text(l10n.getWith('players_delete_confirm', [player.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(playersProvider.notifier).deletePlayer(player.id);
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup(
    BuildContext context,
    WidgetRef ref,
    PlayerGroup group,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.get('presets_delete')),
        content: Text(l10n.getWith('players_delete_confirm', [group.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              ref.read(playerGroupsProvider.notifier).deleteGroup(group.id);
              Navigator.pop(dialogContext);
            },
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final playersState = ref.watch(playersProvider);
    final selectedPlayerIds = <String>{};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.get('presets_save')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: l10n.get('presets_name'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.get('players'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: playersState.when(
                        data: (players) => ListView.builder(
                          shrinkWrap: true,
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final p = players[index];
                            final isSelected = selectedPlayerIds.contains(p.id);
                            return CheckboxListTile(
                              title: Text(p.name),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedPlayerIds.add(p.id);
                                  } else {
                                    selectedPlayerIds.remove(p.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('cancel')),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        selectedPlayerIds.isEmpty) {
                      return;
                    }
                    final group = PlayerGroup(
                      id: const Uuid().v4(),
                      name: nameController.text.trim(),
                      playerIds: selectedPlayerIds.toList(),
                    );
                    await ref
                        .read(playerGroupsProvider.notifier)
                        .addGroup(group);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.get('add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGroupDialog(
    BuildContext context,
    WidgetRef ref,
    PlayerGroup group,
  ) {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: group.name);
    final playersState = ref.watch(playersProvider);
    final selectedPlayerIds = Set<String>.from(group.playerIds);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.get('presets_save')), // Reusing string
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: l10n.get('presets_name'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.get('players'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: playersState.when(
                        data: (players) => ListView.builder(
                          shrinkWrap: true,
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final p = players[index];
                            final isSelected = selectedPlayerIds.contains(p.id);
                            return CheckboxListTile(
                              title: Text(p.name),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedPlayerIds.add(p.id);
                                  } else {
                                    selectedPlayerIds.remove(p.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                        loading: () => const CircularProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('cancel')),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty ||
                        selectedPlayerIds.isEmpty) {
                      return;
                    }
                    final updatedGroup = group.copyWith(
                      name: nameController.text.trim(),
                      playerIds: selectedPlayerIds.toList(),
                    );
                    await ref
                        .read(playerGroupsProvider.notifier)
                        .updateGroup(updatedGroup);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.get('save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddPlayerDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? selectedEmoji;
    final List<String> commonEmojis = [
      '😀',
      '🎮',
      '🎲',
      '🃏',
      '🍺',
      '🍷',
      '🥃',
      '🎯',
      '🏆',
      '👑',
      '🦄',
      '🐱',
      '🐶',
      '🦊',
      '🐼',
      '🦁',
      '👻',
      '👾',
      '🤖',
      '👽',
      '🎃',
      '🎩',
      '🍕',
      '🍦',
      '🚀',
      '💎',
    ];
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            void submit() async {
              setState(() => errorMessage = null);
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final rColor =
                  Colors.primaries[DateTime.now().millisecond %
                      Colors.primaries.length];
              final rColorStr =
                  '#${(rColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

              final newPlayer = Player(
                id: const Uuid().v4(),
                name: name,
                avatarColor: rColorStr,
                emoji: selectedEmoji,
              );

              final result = await ref
                  .read(playersProvider.notifier)
                  .addPlayer(newPlayer);
              result.fold((failure) {
                setState(() => errorMessage = l10n.get(failure.message));
              }, (_) => Navigator.pop(context));
            }

            return AlertDialog(
              title: Text(l10n.get('add_player')),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: l10n.get('player_name'),
                        errorText: errorMessage,
                      ),
                      autofocus: true,
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: commonEmojis.length,
                        itemBuilder: (context, i) {
                          final emoji = commonEmojis[i];
                          final isSelected = selectedEmoji == emoji;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              onPressed: () =>
                                  setState(() => selectedEmoji = emoji),
                              style: IconButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : null,
                                padding: const EdgeInsets.all(8),
                              ),
                              icon: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
      },
    );
  }

  void _showEditPlayerDialog(
    BuildContext context,
    WidgetRef ref,
    Player player,
  ) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: player.name);
    String? selectedEmoji = player.emoji;
    final List<String> commonEmojis = [
      '😀',
      '🎮',
      '🎲',
      '🃏',
      '🍺',
      '🍷',
      '🥃',
      '🎯',
      '🏆',
      '👑',
      '🦄',
      '🐱',
      '🐶',
      '🦊',
      '🐼',
      '🦁',
      '👻',
      '👾',
      '🤖',
      '👽',
      '🎃',
      '🎩',
      '🍕',
      '🍦',
      '🚀',
      '💎',
    ];
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            void submit() async {
              setState(() => errorMessage = null);
              final name = controller.text.trim();
              if (name.isEmpty) return;

              final updatedPlayer = player.copyWith(
                name: name,
                emoji: selectedEmoji,
              );
              final result = await ref
                  .read(playersProvider.notifier)
                  .updatePlayer(updatedPlayer);

              result.fold((failure) {
                setState(() => errorMessage = l10n.get(failure.message));
              }, (_) => Navigator.pop(context));
            }

            return AlertDialog(
              title: Text(l10n.get('edit_player')),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: l10n.get('player_name'),
                        errorText: errorMessage,
                      ),
                      autofocus: true,
                      onSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: commonEmojis.length,
                        itemBuilder: (context, i) {
                          final emoji = commonEmojis[i];
                          final isSelected = selectedEmoji == emoji;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              onPressed: () =>
                                  setState(() => selectedEmoji = emoji),
                              style: IconButton.styleFrom(
                                backgroundColor: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : null,
                                padding: const EdgeInsets.all(8),
                              ),
                              icon: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(l10n.get('cancel')),
                ),
                FilledButton(onPressed: submit, child: Text(l10n.get('save'))),
              ],
            );
          },
        );
      },
    );
  }
}
