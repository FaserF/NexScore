import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/arschloch_models.dart';

class ArschlochStateNotifier extends Notifier<ArschlochGameState> {
  @override
  ArschlochGameState build() => const ArschlochGameState();

  void addRound(ArschlochRound round) {
    final totalPlayers = state.playerStates.length;
    final updatedStates = Map<String, ArschlochPlayerState>.from(
      state.playerStates,
    );

    for (final entry in round.finishOrder.entries) {
      final playerId = entry.key;
      final position = entry.value;
      final rank = ArschlochGameState.rankFromPosition(position, totalPlayers);
      final points = ArschlochGameState.pointsForRank(rank);
      final existing = updatedStates[playerId] ?? const ArschlochPlayerState();
      updatedStates[playerId] = ArschlochPlayerState(
        roundsAsPresident:
            existing.roundsAsPresident +
            (rank == ArschlochRank.president ? 1 : 0),
        roundsAsArschloch:
            existing.roundsAsArschloch +
            (rank == ArschlochRank.arschloch ? 1 : 0),
        lastRank: rank,
        points: existing.points + points,
      );
    }

    state = state.copyWith(
      playerStates: updatedStates,
      rounds: [...state.rounds, round],
    );
  }

  void initPlayers(List<String> playerIds) {
    final states = <String, ArschlochPlayerState>{
      for (final id in playerIds) id: const ArschlochPlayerState(),
    };
    state = ArschlochGameState(playerStates: states, rounds: const []);
  }
}

final arschlochStateProvider =
    NotifierProvider<ArschlochStateNotifier, ArschlochGameState>(
      ArschlochStateNotifier.new,
    );

class ArschlochScreen extends ConsumerWidget {
  const ArschlochScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(arschlochStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_arschloch')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showRulesDialog(context, l10n),
            tooltip: l10n.get('arschloch_rules'),
          ),
        ],
      ),
      body: players.isEmpty
          ? Center(child: Text(l10n.get('game_no_players')))
          : gameState.playerStates.isEmpty
          ? _buildSetupScreen(context, ref, players, l10n)
          : _buildGameScreen(context, ref, players, gameState, l10n),
    );
  }

  Widget _buildSetupScreen(
    BuildContext context,
    WidgetRef ref,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            Text(
              l10n.get('arschloch_title'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${players.length} ${l10n.get('nav_players')}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.get('arschloch_goal_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            if (players.length < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  l10n.get('arschloch_min_3_players'),
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            FilledButton.icon(
              onPressed: players.length >= 3
                  ? () => ref
                        .read(arschlochStateProvider.notifier)
                        .initPlayers(players.map((p) => p.id).toList())
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(
                l10n.get('sipdeck_start'),
                style: const TextStyle(fontSize: 18),
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(
    BuildContext context,
    WidgetRef ref,
    List<Player> players,
    ArschlochGameState gameState,
    AppLocalizations l10n,
  ) {
    final leaders = gameState.getLeaders();
    final playerMap = {for (final p in players) p.id: p.name};

    // Card exchange instructions from last round
    List<String> exchangeInstructions = [];
    if (gameState.rounds.isNotEmpty) {
      exchangeInstructions = ArschlochGameState.cardExchangeInstructions(
        gameState.rounds.last.finishOrder,
        playerMap,
        players.length,
      );
    }

    return Column(
      children: [
        if (exchangeInstructions.isNotEmpty) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.get('arschloch_exchange_title'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...exchangeInstructions.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('• $i', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Scoreboard
        Expanded(
          child: ListView.separated(
            itemCount: leaders.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final pid = leaders[index];
              final ps = gameState.playerStates[pid]!;
              final player = players.firstWhere(
                (p) => p.id == pid,
                orElse: () => players.first,
              );

              final rankLabel = ps.lastRank == null
                  ? '–'
                  : _labelForRank(ps.lastRank!, l10n);
              final rankColor = switch (ps.lastRank) {
                ArschlochRank.president => Colors.amber.shade700,
                ArschlochRank.vicePresident => Colors.blueGrey.shade400,
                ArschlochRank.arschloch => Colors.red.shade700,
                ArschlochRank.viceArschloch => Colors.orange.shade700,
                _ => Colors.grey,
              };

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    int.parse(player.avatarColor.replaceFirst('#', '0xff')),
                  ),
                  child: Text(
                    player.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  player.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  l10n.getWith('arschloch_rounds', [
                    ps.roundsAsPresident.toString(),
                    ps.roundsAsArschloch.toString(),
                  ]),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rankLabel,
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ps.points > 0 ? '+' : ''}${ps.points} ${l10n.get('history_pts')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ps.points > 0
                            ? Colors.green
                            : ps.points < 0
                            ? Colors.red
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: () =>
                _showRoundEntryDialog(context, ref, players, gameState, l10n),
            icon: const Icon(Icons.add),
            label: Text(
              '${l10n.get('wizard_round')} ${gameState.rounds.length + 1}',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showRoundEntryDialog(
    BuildContext context,
    WidgetRef ref,
    List<Player> players,
    ArschlochGameState gameState,
    AppLocalizations l10n,
  ) async {
    // finishPosition[playerId] = position (1 = finished first)
    final positions = <String, int>{};
    int nextPosition = 1;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final unranked = players
                .where((p) => !positions.containsKey(p.id))
                .toList();
            return AlertDialog(
              title: Text(
                '${l10n.get('wizard_round')} ${gameState.rounds.length + 1} – ${l10n.get('arschloch_finish_order')}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (positions.isNotEmpty) ...[
                      Text(
                        l10n.get('arschloch_ranked'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ...() {
                        final sortedEntries = positions.entries.toList()
                          ..sort((a, b) => a.value.compareTo(b.value));
                        return sortedEntries.map((e) {
                          final player = players.firstWhere(
                            (p) => p.id == e.key,
                          );
                          final rank = ArschlochGameState.rankFromPosition(
                            e.value,
                            players.length,
                          );
                          return ListTile(
                            dense: true,
                            leading: Text(
                              '${e.value}.',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            title: Text(player.name),
                            subtitle: Text(_labelForRank(rank, l10n)),
                            trailing: IconButton(
                              icon: const Icon(Icons.undo, size: 18),
                              onPressed: () => setState(() {
                                positions.remove(e.key);
                                nextPosition = positions.isEmpty
                                    ? 1
                                    : positions.values.reduce(
                                            (a, b) => a > b ? a : b,
                                          ) +
                                          1;
                              }),
                            ),
                          );
                        }).toList();
                      }(),
                      const Divider(),
                    ],
                    if (unranked.isNotEmpty) ...[
                      Text(
                        l10n.get('arschloch_tap_to_rank'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ...unranked.map(
                        (p) => ListTile(
                          dense: true,
                          title: Text(p.name),
                          trailing: const Icon(
                            Icons.touch_app,
                            size: 18,
                            color: Colors.blue,
                          ),
                          onTap: () => setState(() {
                            positions[p.id] = nextPosition++;
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.get('cancel')),
                ),
                FilledButton(
                  onPressed: positions.length == players.length
                      ? () {
                          ref
                              .read(arschlochStateProvider.notifier)
                              .addRound(
                                ArschlochRound(
                                  roundIndex: gameState.rounds.length + 1,
                                  finishOrder: Map.from(positions),
                                ),
                              );
                          Navigator.pop(ctx);
                        }
                      : null,
                  child: Text(l10n.get('wizard_save_round')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRulesDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${l10n.get('game_arschloch')} – ${l10n.get('arschloch_rules')}',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.get('arschloch_goal'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(l10n.get('arschloch_goal_desc')),
              const SizedBox(height: 8),
              Text(
                l10n.get('nav_leaderboard'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(l10n.get('arschloch_ranks_desc')),
              const SizedBox(height: 8),
              Text(
                l10n.get('arschloch_exchange_title'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(l10n.get('arschloch_rules_exchange_p')),
              Text(l10n.get('arschloch_rules_exchange_vp')),
              const SizedBox(height: 8),
              Text(
                l10n.get('arschloch_rules_special'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(l10n.get('arschloch_rules_2_high')),
              Text(l10n.get('arschloch_rules_bomb')),
              Text(l10n.get('arschloch_rules_passing')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.get('close')),
          ),
        ],
      ),
    );
  }

  String _labelForRank(ArschlochRank rank, AppLocalizations l10n) {
    switch (rank) {
      case ArschlochRank.president:
        return l10n.get('arschloch_rank_president');
      case ArschlochRank.vicePresident:
        return l10n.get('arschloch_rank_vice_president');
      case ArschlochRank.neutral:
        return l10n.get('arschloch_rank_neutral');
      case ArschlochRank.viceArschloch:
        return l10n.get('arschloch_rank_vice_arschloch');
      case ArschlochRank.arschloch:
        return l10n.get('arschloch_rank_arschloch');
    }
  }
}
