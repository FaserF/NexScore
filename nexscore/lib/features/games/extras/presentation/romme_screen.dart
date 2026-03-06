import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/romme_models.dart';

class RommeStateNotifier extends Notifier<RommeGameState> {
  @override
  RommeGameState build() => const RommeGameState();

  void addRound(RommeRound round) {
    state = state.copyWith(rounds: [...state.rounds, round]);
  }

  void resetGame() {
    state = const RommeGameState();
  }
}

final rommeStateProvider = NotifierProvider<RommeStateNotifier, RommeGameState>(
  RommeStateNotifier.new,
);

class RommePlayersNotifier extends Notifier<List<Player>> {
  @override
  List<Player> build() => [];

  void setPlayers(List<Player> players) {
    state = players;
  }
}

final rommePlayersProvider = activePlayersProvider;

class RommeScreen extends ConsumerWidget {
  const RommeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(rommeStateProvider);
    final players = ref.watch(rommePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('romme_title'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    final playerIds = players.map((p) => p.id).toList();
    final leaders = gameState.getLeaders(playerIds);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('romme_title')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scoreboard header
          _RommeScoreHeader(players: players, gameState: gameState),
          const Divider(height: 1, thickness: 2),
          // Rounds list
          Expanded(
            child: gameState.rounds.isEmpty
                ? Center(child: Text(l10n.get('romme_no_rounds')))
                : ListView.separated(
                    itemCount: gameState.rounds.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final round = gameState.rounds[i];
                      return ListTile(
                        title: Text(
                          '${l10n.get('romme_round')} ${round.roundIndex}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: players.map((p) {
                            final pts = round.penaltyPoints[p.id] ?? 0;
                            return SizedBox(
                              width: 56,
                              child: Text(
                                '$pts',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: pts > 0 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: () => _showAddRoundDialog(
                context,
                ref,
                players,
                gameState.rounds.length + 1,
                l10n,
              ),
              icon: const Icon(Icons.add),
              label: Text(l10n.get('add_round')),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: leaders.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: null,
              label: Text(
                l10n.getWith('romme_leader', [
                  players
                      .firstWhere(
                        (p) => p.id == leaders.first,
                        orElse: () => players.first,
                      )
                      .name,
                ]),
              ),
              icon: const Icon(Icons.emoji_events, color: Colors.amber),
            )
          : null,
    );
  }

  Future<void> _showAddRoundDialog(
    BuildContext context,
    WidgetRef ref,
    List<Player> players,
    int roundIndex,
    AppLocalizations l10n,
  ) async {
    final penalties = <String, int>{for (var p in players) p.id: 0};
    final controllers = <String, TextEditingController>{
      for (var p in players) p.id: TextEditingController(text: '0'),
    };

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.getWith('romme_penalty_title', [roundIndex.toString()]),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: players.map((p) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(p.name, style: const TextStyle(fontSize: 16)),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controllers[p.id],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textInputAction: p.id == players.last.id
                            ? TextInputAction.done
                            : TextInputAction.next,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          suffixText: l10n.get('history_pts'),
                        ),
                        onChanged: (val) {
                          penalties[p.id] = int.tryParse(val) ?? 0;
                        },
                        onSubmitted: (_) {
                          if (p.id == players.last.id) {
                            // Save and close
                            for (final player in players) {
                              penalties[player.id] =
                                  int.tryParse(controllers[player.id]!.text) ??
                                  0;
                            }
                            final round = RommeRound(
                              roundIndex: roundIndex,
                              penaltyPoints: Map.from(penalties),
                            );
                            ref
                                .read(rommeStateProvider.notifier)
                                .addRound(round);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('cancel')),
            ),
            FilledButton(
              onPressed: () {
                // Read final values from controllers
                for (final p in players) {
                  penalties[p.id] = int.tryParse(controllers[p.id]!.text) ?? 0;
                }
                final round = RommeRound(
                  roundIndex: roundIndex,
                  penaltyPoints: Map.from(penalties),
                );
                ref.read(rommeStateProvider.notifier).addRound(round);
                Navigator.pop(context);
              },
              child: Text(l10n.get('wizard_save_round')),
            ),
          ],
        );
      },
    );

    for (final c in controllers.values) {
      c.dispose();
    }
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
              ref.read(rommeStateProvider.notifier).resetGame();
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

class _RommeScoreHeader extends StatelessWidget {
  final List<Player> players;
  final RommeGameState gameState;

  const _RommeScoreHeader({required this.players, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        children: [
          const Expanded(child: Text('')),
          ...players.map((p) {
            final total = gameState.getPlayerScore(p.id);
            return SizedBox(
              width: 56,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(
                      int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                    ),
                    child: Text(
                      p.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
}
