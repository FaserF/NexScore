import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/models/player_model.dart';
import '../repository/player_repository.dart';
import '../../../core/theme/widgets/animated_scale_button.dart';
import '../../../core/theme/widgets/glass_container.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersState = ref.watch(playersProvider);
    final l10n = AppLocalizations.of(context);

    // Provide a consistent gradient based on color string
    Color parseColor(String colorStr) {
      try {
        return Color(int.parse(colorStr.replaceFirst('#', '0xff')));
      } catch (e) {
        return Colors.blue;
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l10n.get('players'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            centerTitle: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
          ),
          playersState.when(
            data: (players) {
              if (players.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.get('no_players'),
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final player = players[index];
                    final playerColor = parseColor(player.avatarColor);
                    final initial = player.name.isNotEmpty
                        ? player.name.substring(0, 1).toUpperCase()
                        : '?';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: AnimatedScaleButton(
                        onPressed: () {
                          // Can add edit player modal logic here later
                        },
                        child: GlassContainer(
                          borderRadius: 20,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      playerColor.withValues(alpha: 0.8),
                                      playerColor,
                                    ],
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
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.shuffle,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () {
                                  final rColor =
                                      Colors.primaries[DateTime.now()
                                              .millisecond %
                                          Colors.primaries.length];
                                  final rColorStr =
                                      '#${(rColor.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
                                  ref
                                      .read(playersProvider.notifier)
                                      .updatePlayer(
                                        player.copyWith(avatarColor: rColorStr),
                                      );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () =>
                                    _showEditPlayerDialog(context, ref, player),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, ref, player),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: players.length),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text(l10n.getWith('error_msg', [err.toString()])),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddPlayerDialog(context, ref),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Player player) {
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
