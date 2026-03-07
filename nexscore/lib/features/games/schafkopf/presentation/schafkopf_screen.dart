import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/schafkopf_models.dart';

import '../providers/schafkopf_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';

class SchafkopfScreen extends ConsumerStatefulWidget {
  const SchafkopfScreen({super.key});

  @override
  ConsumerState<SchafkopfScreen> createState() => _SchafkopfScreenState();
}

class _SchafkopfScreenState extends ConsumerState<SchafkopfScreen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showWinner(SchafkopfGameState gameState, List<Player> players) {
    if (players.isEmpty) return;
    String? winnerId;
    double maxBalance = double.negativeInfinity;
    final playerIds = players.map((p) => p.id).toList();
    for (final p in players) {
      final balance = gameState.getPlayerBalance(p.id, playerIds);
      if (balance > maxBalance) {
        maxBalance = balance;
        winnerId = p.id;
      }
    }
    if (winnerId != null) {
      final winnerName = players.firstWhere((p) => p.id == winnerId).name;
      _confettiController.show(winnerName: winnerName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(schafkopfStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_schafkopf')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events, color: Colors.amber),
            onPressed: () => _showWinner(gameState, players),
            tooltip: l10n.get('game_show_winner'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://faserf.github.io/NexScore/docs/user_guide/games/#schafkopf',
                ),
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          if (gameState.rounds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: l10n.get('schafkopf_undo'),
              onPressed: () =>
                  ref.read(schafkopfStateProvider.notifier).removeLastRound(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
            tooltip: l10n.get('game_reset'),
          ),
        ],
      ),
      body: WinnerConfettiOverlay(
        controller: _confettiController,
        child: MultiplayerClientOverlay(
          child: players.length < 4
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.get('schafkopf_requires_4'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    _buildScoreHeader(players, gameState, l10n),
                    _buildStockInfo(context, ref, gameState, l10n),
                    const Divider(height: 1, thickness: 2),
                    Expanded(
                      child: gameState.rounds.isEmpty
                          ? Center(child: Text(l10n.get('schafkopf_no_rounds')))
                          : ListView.separated(
                              itemCount: gameState.rounds.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final round = gameState.rounds[index];
                                final payouts = round.calculatePayouts(
                                  players.map((p) => p.id).toList(),
                                );
                                final activePlayer = players.firstWhere(
                                  (p) => p.id == round.activePlayerId,
                                  orElse: () => Player(
                                    id: '',
                                    name: 'Unknown',
                                    avatarColor: '#000000',
                                    ownerUid: null,
                                  ),
                                );
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(
                                      int.parse(
                                        activePlayer.avatarColor.replaceFirst(
                                          '#',
                                          '0xff',
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      activePlayer.name.substring(0, 1),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  title: Text(
                                    '${l10n.get('schafkopf_gt_${round.gameType.name}')} – ${activePlayer.name}',
                                  ),
                                  subtitle: Text(
                                    [
                                      if (round.isBockRound) 'BOCK',
                                      if (round.isMussSpiel) 'MUSS',
                                      if (round.runners > 0)
                                        l10n.getWith(
                                          'schafkopf_runners_count',
                                          [round.runners.toString()],
                                        ),
                                      if (round.schneider)
                                        l10n.get('schafkopf_schneider'),
                                      if (round.schwarz)
                                        l10n.get('schafkopf_schwarz'),
                                    ].join(' · '),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: players.map((p) {
                                      final val = payouts[p.id] ?? 0.0;
                                      return Container(
                                        width: 56,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          val > 0
                                              ? '+${val.toStringAsFixed(2)}'
                                              : val.toStringAsFixed(2),
                                          style: TextStyle(
                                            color: val > 0
                                                ? Colors.green
                                                : val < 0
                                                ? Colors.red
                                                : Colors.grey,
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
                          gameState,
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(
                          l10n.getWith('wizard_next_round', [
                            (gameState.rounds.length + 1).toString(),
                          ]),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStockInfo(
    BuildContext context,
    WidgetRef ref,
    SchafkopfGameState state,
    AppLocalizations l10n,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, size: 16),
          const SizedBox(width: 8),
          Text(
            'Stock: ${state.stock.toStringAsFixed(2)} €',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (state.bockRoundsRemaining > 0)
            Chip(
              label: Text('BOCK: ${state.bockRoundsRemaining}'),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.orange.shade200,
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 16),
            onPressed: () => _showStockDialog(context, ref, l10n, state),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _showStockDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    SchafkopfGameState state,
  ) {
    final controller = TextEditingController(
      text: state.stock.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stock / Bock Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Amount (€)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Set Bock Rounds:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [0, 4, 8, 12]
                  .map(
                    (count) => ActionChip(
                      label: Text('$count'),
                      onPressed: () {
                        ref
                            .read(schafkopfStateProvider.notifier)
                            .setBockRounds(count);
                        Navigator.pop(ctx);
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                ref
                    .read(schafkopfStateProvider.notifier)
                    .updateStock(val - state.stock);
              }
              Navigator.pop(ctx);
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHeader(
    List<Player> players,
    SchafkopfGameState gameState,
    AppLocalizations l10n,
  ) {
    final Map<String, double> totals = {
      for (var p in players)
        p.id: gameState.getPlayerBalance(
          p.id,
          players.map((p) => p.id).toList(),
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.get('schafkopf_payouts'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...players.map((p) {
            final total = totals[p.id] ?? 0.0;
            return Container(
              width: 56,
              alignment: Alignment.centerRight,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Color(
                      int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                    ),
                    child: Text(
                      p.name.substring(0, 1),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total.toStringAsFixed(2),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: total > 0
                          ? Colors.green
                          : total < 0
                          ? Colors.red
                          : null,
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

  Future<void> _showAddRoundDialog(
    BuildContext context,
    WidgetRef ref,
    List<Player> players,
    SchafkopfGameState gameState,
  ) async {
    SchafkopfGameType selectedType = SchafkopfGameType.sauspiel;
    String activePlayerId = players[0].id;
    String? partnerPlayerId = players.length > 1 ? players[1].id : null;
    bool schneider = false;
    bool schwarz = false;
    int runners = 0;
    bool activeWon = true;
    double baseValue = 0.10;
    bool isBockRound = gameState.bockRoundsRemaining > 0;
    bool isMussSpiel = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(
              '${l10n.get('wizard_round')} ${gameState.rounds.length + 1}',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.get('schafkopf_game_type'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<SchafkopfGameType>(
                    value: selectedType,
                    isExpanded: true,
                    items: SchafkopfGameType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(l10n.get('schafkopf_gt_${t.name}')),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selectedType = v!),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.get('schafkopf_active_player'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: activePlayerId,
                    isExpanded: true,
                    items: players
                        .map(
                          (p) => DropdownMenuItem(
                            value: p.id,
                            child: Text(p.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => activePlayerId = v!),
                  ),
                  if (selectedType == SchafkopfGameType.sauspiel) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.get('schafkopf_partner'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: partnerPlayerId,
                      isExpanded: true,
                      items: players
                          .where((p) => p.id != activePlayerId)
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => partnerPlayerId = v),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(l10n.get('schafkopf_active_won')),
                      const Spacer(),
                      Switch(
                        value: activeWon,
                        onChanged: (v) => setState(() => activeWon = v),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(l10n.get('schafkopf_schneider')),
                      const Spacer(),
                      Switch(
                        value: schneider,
                        onChanged: (v) => setState(() {
                          schneider = v;
                          if (!v) schwarz = false;
                        }),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(l10n.get('schafkopf_schwarz')),
                      const Spacer(),
                      Switch(
                        value: schwarz,
                        onChanged: schneider
                            ? (v) => setState(() => schwarz = v)
                            : null,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Bock-Runde (x2)'),
                      const Spacer(),
                      Switch(
                        value: isBockRound,
                        onChanged: (v) => setState(() => isBockRound = v),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('Muss-Spiel'),
                      const Spacer(),
                      Switch(
                        value: isMussSpiel,
                        onChanged: (v) => setState(() => isMussSpiel = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(l10n.get('schafkopf_runners')),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: runners > 0
                                ? () => setState(() => runners--)
                                : null,
                          ),
                          Text(
                            '$runners',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: runners < 14
                                ? () => setState(() => runners++)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(l10n.get('schafkopf_base_tariff')),
                      const Spacer(),
                      DropdownButton<double>(
                        value: baseValue,
                        items: [0.05, 0.10, 0.25, 0.50, 1.00]
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text('${v.toStringAsFixed(2)} €'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => baseValue = v!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.get('cancel')),
              ),
              FilledButton(
                onPressed: () {
                  final round = SchafkopfRound(
                    roundIndex: gameState.rounds.length + 1,
                    gameType: selectedType,
                    activePlayerId: activePlayerId,
                    partnerPlayerId: selectedType == SchafkopfGameType.sauspiel
                        ? partnerPlayerId
                        : null,
                    points: {activePlayerId: activeWon ? 61 : 59},
                    schneider: schneider,
                    schwarz: schwarz,
                    runners: runners,
                    baseTariff: baseValue,
                    isBockRound: isBockRound,
                    isMussSpiel: isMussSpiel,
                  );
                  ref.read(schafkopfStateProvider.notifier).addRound(round);

                  // Automatically pay out Stock if player won a Muss-Spiel or if user wants to clear it
                  // For now, simple manual management via Stock Dialog is safer.

                  Navigator.pop(ctx);
                },
                child: Text(l10n.get('wizard_save_round')),
              ),
            ],
          ),
        );
      },
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
              ref.read(schafkopfStateProvider.notifier).resetGame();
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
