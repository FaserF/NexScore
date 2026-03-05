import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/darts_models.dart';

class DartsStateNotifier extends Notifier<DartsGameState> {
  @override
  DartsGameState build() => const DartsGameState();

  void addRound(String playerId, DartRound round) {
    final currentState =
        state.playerStates[playerId] ??
        DartPlayerState(startingScore: state.targetScore);
    final updatedStates = Map<String, DartPlayerState>.from(state.playerStates);

    updatedStates[playerId] = currentState.copyWith(
      rounds: [...currentState.rounds, round],
    );

    state = state.copyWith(playerStates: updatedStates);
  }

  void setTargetScore(int score) {
    // Reset all local player states when changing game type
    state = DartsGameState(targetScore: score, playerStates: {});
  }
}

final dartsStateProvider = NotifierProvider<DartsStateNotifier, DartsGameState>(
  DartsStateNotifier.new,
);

class DartsPlayersNotifier extends Notifier<List<Player>> {
  @override
  List<Player> build() => [];

  void setPlayers(List<Player> players) {
    state = players;
  }
}

final dartsPlayersProvider = activePlayersProvider;

class DartsScreen extends ConsumerWidget {
  const DartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(dartsStateProvider);
    final players = ref.watch(dartsPlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('darts_title'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.getWith('darts_target', [gameState.targetScore.toString()]),
        ),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.settings),
            onSelected: (val) =>
                ref.read(dartsStateProvider.notifier).setTargetScore(val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 301, child: Text('301')),
              const PopupMenuItem(value: 501, child: Text('501')),
              const PopupMenuItem(value: 701, child: Text('701')),
              const PopupMenuItem(value: 1001, child: Text('1001')),
            ],
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: players.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final p = players[index];
          final pState =
              gameState.playerStates[p.id] ??
              DartPlayerState(startingScore: gameState.targetScore);
          final currentScore = pState.currentScore;
          final isWinner = currentScore == 0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            leading: CircleAvatar(
              backgroundColor: Color(
                int.parse(p.avatarColor.replaceFirst('#', '0xff')),
              ),
              child: isWinner
                  ? const Icon(Icons.emoji_events, color: Colors.amber)
                  : Text(p.name.substring(0, 1).toUpperCase()),
            ),
            title: Text(
              p.name,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner ? Colors.green : null,
              ),
            ),
            subtitle: Text(
              '${l10n.getWith('darts_avg', [pState.averagePerDart.toStringAsFixed(1)])} | ${l10n.getWith('darts_thrown', [(pState.rounds.length * 3).toString()])}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$currentScore',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isWinner
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: isWinner
                      ? null
                      : () => _showPointsDialog(context, ref, p, pState, l10n),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPointsDialog(
    BuildContext context,
    WidgetRef ref,
    Player player,
    DartPlayerState pState,
    AppLocalizations l10n,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.getWith('darts_enter_score', [player.name])),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.get('darts_input_desc'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixText: l10n.get('history_pts'),
                    ),
                    onSubmitted: (val) {
                      final score = int.tryParse(val) ?? 0;
                      if (score <= 180) {
                        final round = DartRound(
                          throws: [DartThrow(score: score, multiplier: 1)],
                        );
                        ref
                            .read(dartsStateProvider.notifier)
                            .addRound(player.id, round);
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 300,
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      childAspectRatio: 1.5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (int i = 1; i <= 9; i++)
                          _KeypadButton(
                            label: '$i',
                            onPressed: () {
                              controller.text = '${controller.text}$i';
                              focusNode.requestFocus();
                            },
                          ),
                        _KeypadButton(
                          label: 'C',
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          onPressed: () {
                            controller.clear();
                            focusNode.requestFocus();
                          },
                        ),
                        _KeypadButton(
                          label: '0',
                          onPressed: () {
                            if (controller.text.isNotEmpty) {
                              controller.text = '${controller.text}0';
                            }
                            focusNode.requestFocus();
                          },
                        ),
                        _KeypadButton(
                          label: l10n.get('darts_bust'),
                          color: Colors.orange.withValues(alpha: 0.1),
                          onPressed: () {
                            final round = DartRound(
                              throws: [DartThrow(score: 0, multiplier: 1)],
                            );
                            ref
                                .read(dartsStateProvider.notifier)
                                .addRound(player.id, round);
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    final score = int.tryParse(controller.text) ?? 0;
                    if (score <= 180) {
                      final round = DartRound(
                        throws: [DartThrow(score: score, multiplier: 1)],
                      );
                      ref
                          .read(dartsStateProvider.notifier)
                          .addRound(player.id, round);
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l10n.get('add')),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    focusNode.dispose();
  }
}

class _KeypadButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _KeypadButton({
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      style: FilledButton.styleFrom(
        backgroundColor:
            color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        foregroundColor: color != null
            ? Colors.white
            : Theme.of(context).colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }
}
