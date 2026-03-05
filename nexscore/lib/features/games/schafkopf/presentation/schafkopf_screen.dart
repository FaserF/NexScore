import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/schafkopf_models.dart';

import '../providers/schafkopf_provider.dart';

class SchafkopfScreen extends ConsumerWidget {
  const SchafkopfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = ref.watch(schafkopfStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_schafkopf')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          if (rounds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: l10n.get('schafkopf_undo'),
              onPressed: () =>
                  ref.read(schafkopfStateProvider.notifier).removeLastRound(),
            ),
        ],
      ),
      body: players.length < 4
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
                _buildScoreHeader(players, rounds, l10n),
                const Divider(height: 1, thickness: 2),
                Expanded(
                  child: rounds.isEmpty
                      ? Center(child: Text(l10n.get('schafkopf_no_rounds')))
                      : ListView.separated(
                          itemCount: rounds.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final round = rounds[index];
                            final payouts = round.calculatePayouts();
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
                                  if (round.runners > 0)
                                    l10n.getWith('schafkopf_runners_count', [
                                      round.runners.toString(),
                                    ]),
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
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 110.0),
                  child: FilledButton.icon(
                    onPressed: () => _showAddRoundDialog(
                      context,
                      ref,
                      players,
                      rounds.length,
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(
                      l10n.getWith('wizard_next_round', [
                        (rounds.length + 1).toString(),
                      ]),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildScoreHeader(
    List<Player> players,
    List<SchafkopfRound> rounds,
    AppLocalizations l10n,
  ) {
    final Map<String, double> totals = {for (var p in players) p.id: 0.0};
    for (final r in rounds) {
      r.calculatePayouts().forEach((pid, val) {
        if (totals.containsKey(pid)) totals[pid] = totals[pid]! + val;
      });
    }

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
    int roundIndex,
  ) async {
    SchafkopfGameType selectedType = SchafkopfGameType.sauspiel;
    String activePlayerId = players[0].id;
    String? partnerPlayerId = players.length > 1 ? players[1].id : null;
    bool schneider = false;
    bool schwarz = false;
    int runners = 0;
    bool activeWon = true;
    double baseValue = 0.10;

    await showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text('${l10n.get('wizard_round')} ${roundIndex + 1}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Game type
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
                  // Active player
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
                  // Partner (only for Sauspiel)
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
                  // Won/Lost
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
                  // Schneider
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
                  // Schwarz
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
                  const SizedBox(height: 8),
                  // Laufende
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
                  if (runners > 0 && runners < 3)
                    Text(
                      l10n.get('schafkopf_runners_warning'),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Base value
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
                  final pointMap = {activePlayerId: activeWon ? 61 : 59};
                  final round = SchafkopfRound(
                    roundIndex: roundIndex + 1,
                    gameType: selectedType,
                    activePlayerId: activePlayerId,
                    partnerPlayerId: selectedType == SchafkopfGameType.sauspiel
                        ? partnerPlayerId
                        : null,
                    points: pointMap,
                    schneider: schneider,
                    schwarz: schwarz,
                    runners: runners,
                    baseTariff: baseValue,
                  );
                  ref.read(schafkopfStateProvider.notifier).addRound(round);
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
}
