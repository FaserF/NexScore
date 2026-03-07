import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/romme_models.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';

class RommeStateNotifier extends Notifier<RommeGameState> {
  @override
  RommeGameState build() => const RommeGameState();

  void addRound(RommeRound round) {
    state = state.copyWith(rounds: [...state.rounds, round]);
  }

  void resetGame() {
    state = state.copyWith(rounds: []);
  }

  void updateSettings({int? firstMeldPoints, bool? doubleOnHandRomme}) {
    state = state.copyWith(
      firstMeldPoints: firstMeldPoints,
      doubleOnHandRomme: doubleOnHandRomme,
      rounds: [], // Reset on setting change
    );
  }

  void removeLastRound() {
    if (state.rounds.isNotEmpty) {
      state = state.copyWith(
        rounds: state.rounds.sublist(0, state.rounds.length - 1),
      );
    }
  }
}

final rommeStateProvider = NotifierProvider<RommeStateNotifier, RommeGameState>(
  RommeStateNotifier.new,
);

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
          if (gameState.rounds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () =>
                  ref.read(rommeStateProvider.notifier).removeLastRound(),
              tooltip: l10n.get('schafkopf_undo'),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context, ref, gameState, l10n),
            tooltip: l10n.get('romme_settings'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
        ],
      ),
      body: MultiplayerClientOverlay(
        child: Column(
          children: [
            _RommeScoreHeader(players: players, gameState: gameState),
            const Divider(height: 1, thickness: 2),
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
                          subtitle: round.isHandRomme
                              ? Text(
                                  l10n.get('romme_hand_romme'),
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
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
                  gameState,
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
      ),
      floatingActionButton: leaders.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showScoreBreakdown(context, players, gameState, l10n),
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
    RommeGameState gameState,
    AppLocalizations l10n,
  ) async {
    final penalties = <String, int>{for (var p in players) p.id: 0};
    final controllers = <String, TextEditingController>{
      for (var p in players) p.id: TextEditingController(text: '0'),
    };
    String selectedWinnerId = players.first.id;
    bool isHandRomme = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(
              l10n.getWith('romme_penalty_title', [roundIndex.toString()]),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.get('winner'),
                      border: const OutlineInputBorder(),
                    ),
                    initialValue: selectedWinnerId,
                    onChanged: (val) => setState(() => selectedWinnerId = val!),
                    items: players
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(l10n.get('romme_hand_romme')),
                    subtitle: Text(l10n.get('romme_hand_romme_desc')),
                    value: isHandRomme,
                    onChanged: (val) => setState(() => isHandRomme = val),
                  ),
                  const Divider(height: 32),
                  ...players.map((p) {
                    final isWinner = p.id == selectedWinnerId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isWinner
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isWinner ? Colors.green : null,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: controllers[p.id],
                              enabled: !isWinner,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                suffixText: l10n.get('history_pts'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.get('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  for (final p in players) {
                    int pts = int.tryParse(controllers[p.id]!.text) ?? 0;
                    if (isHandRomme &&
                        p.id != selectedWinnerId &&
                        gameState.doubleOnHandRomme) {
                      pts *= 2;
                    }
                    penalties[p.id] = pts;
                  }
                  final round = RommeRound(
                    roundIndex: roundIndex,
                    penaltyPoints: Map.from(penalties),
                    winnerId: selectedWinnerId,
                    isHandRomme: isHandRomme,
                  );
                  ref.read(rommeStateProvider.notifier).addRound(round);
                  Navigator.pop(context);
                },
                child: Text(l10n.get('wizard_save_round')),
              ),
            ],
          ),
        );
      },
    );

    for (final c in controllers.values) {
      c.dispose();
    }
  }

  void _showScoreBreakdown(
    BuildContext context,
    List<Player> players,
    RommeGameState gameState,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final sortedPlayers = List<Player>.from(players)
          ..sort(
            (a, b) => gameState
                .getPlayerScore(a.id)
                .compareTo(gameState.getPlayerScore(b.id)),
          );

        return AlertDialog(
          title: Text(l10n.get('romme_breakdown')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...sortedPlayers.map((p) {
                final score = gameState.getPlayerScore(p.id);
                final isLeader =
                    score == gameState.getPlayerScore(sortedPlayers.first.id);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(
                      int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                    ),
                    child: Text(
                      p.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(p.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLeader)
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        '$score',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.get('close')),
            ),
          ],
        );
      },
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    WidgetRef ref,
    RommeGameState state,
    AppLocalizations l10n,
  ) {
    int selectedMeld = state.firstMeldPoints;
    bool doubleHand = state.doubleOnHandRomme;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.get('romme_settings')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.get('romme_first_meld'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('0')),
                  ButtonSegment(value: 30, label: Text('30')),
                  ButtonSegment(value: 40, label: Text('40')),
                ],
                selected: {selectedMeld},
                onSelectionChanged: (val) =>
                    setState(() => selectedMeld = val.first),
              ),
              const Divider(height: 32),
              SwitchListTile(
                title: Text(l10n.get('romme_hand_romme')),
                subtitle: const Text('x2 Points'),
                value: doubleHand,
                onChanged: (val) => setState(() => doubleHand = val),
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
                ref
                    .read(rommeStateProvider.notifier)
                    .updateSettings(
                      firstMeldPoints: selectedMeld,
                      doubleOnHandRomme: doubleHand,
                    );
                Navigator.pop(context);
              },
              child: Text(l10n.get('ok')),
            ),
          ],
        ),
      ),
    );
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
