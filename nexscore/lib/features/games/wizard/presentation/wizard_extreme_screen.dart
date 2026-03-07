import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/wizard_extreme_models.dart';
import '../providers/wizard_extreme_provider.dart';

class WizardExtremeScreen extends ConsumerWidget {
  const WizardExtremeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wizardExtremeStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wizard Extreme')),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wizard Extreme'),
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
          _buildScoreHeader(context, state, players),
          const Divider(height: 1),
          Expanded(
            child: state.rounds.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No rounds yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.rounds.length,
                    itemBuilder: (context, index) {
                      final round = state.rounds[index];
                      return _buildRoundCard(
                        context,
                        ref,
                        index,
                        round,
                        players,
                        l10n,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRoundDialog(context, ref, players, l10n),
        label: Text(l10n.get('add_round')),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScoreHeader(
    BuildContext context,
    WizardExtremeGameState state,
    List<Player> players,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: players.map((p) {
          final score = state.getPlayerTotalScore(p.id);
          return Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(
                  int.parse(p.avatarColor.replaceFirst('#', '0xff')),
                ),
                child: Text(
                  p.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: score < 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRoundCard(
    BuildContext context,
    WidgetRef ref,
    int index,
    Map<String, WizardExtremePlayerRound> round,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        title: Text('${l10n.get('wizard_round')} ${index + 1}'),
        subtitle: Row(
          children: players.map((p) {
            final pRound = round[p.id]!;
            final pts = pRound.calculatePoints();
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                '${p.name}: $pts',
                style: TextStyle(
                  fontSize: 11,
                  color: pts < 0 ? Colors.red : Colors.green,
                ),
              ),
            );
          }).toList(),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: players.map((p) {
                final pRound = round[p.id]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: [
                            ...pRound.predictedSeals.map(
                              (s) => _SealChip(seal: s, isPredicted: true),
                            ),
                            const Icon(Icons.arrow_right_alt, size: 16),
                            ...pRound.actualSeals.map(
                              (s) => _SealChip(seal: s, isPredicted: false),
                            ),
                            if (pRound.blackSeals > 0)
                              _SealChip(
                                seal: WizardExtremeSeal(
                                  color: WizardExtremeSealColor.black,
                                  count: pRound.blackSeals,
                                ),
                                isPredicted: false,
                              ),
                            if (pRound.isBlackMagician)
                              const Chip(
                                label: Text(
                                  'BM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: Colors.black,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${pRound.calculatePoints()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _confirmDeleteRound(context, ref, index, l10n),
                child: Text(
                  l10n.get('delete'),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddRoundDialog(
    BuildContext context,
    WidgetRef ref,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          _WizardExtremeRoundDialog(players: players, l10n: l10n),
    ).then((result) {
      if (result != null && result is Map<String, WizardExtremePlayerRound>) {
        ref.read(wizardExtremeStateProvider.notifier).addRound(result);
      }
    });
  }

  void _confirmDeleteRound(
    BuildContext context,
    WidgetRef ref,
    int index,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('delete')),
        content: const Text('Delete this round?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              // Note: We need updateRound logic to remove actually. sublist for now
              final state = ref.read(wizardExtremeStateProvider);
              final newRounds =
                  List<Map<String, WizardExtremePlayerRound>>.from(
                    state.rounds,
                  );
              newRounds.removeAt(index);
              ref.read(wizardExtremeStateProvider.notifier).resetGame();
              for (final r in newRounds) {
                ref.read(wizardExtremeStateProvider.notifier).addRound(r);
              }
              Navigator.pop(context);
            },
            child: Text(
              l10n.get('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
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
              ref.read(wizardExtremeStateProvider.notifier).resetGame();
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

class _SealChip extends StatelessWidget {
  final WizardExtremeSeal seal;
  final bool isPredicted;

  const _SealChip({required this.seal, required this.isPredicted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor(seal.color),
        borderRadius: BorderRadius.circular(4),
        border: isPredicted
            ? Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Text(
        '${seal.count}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color:
              seal.color == WizardExtremeSealColor.yellow ||
                  seal.color == WizardExtremeSealColor.white
              ? Colors.black
              : Colors.white,
        ),
      ),
    );
  }

  Color _getColor(WizardExtremeSealColor color) {
    switch (color) {
      case WizardExtremeSealColor.red:
        return Colors.red;
      case WizardExtremeSealColor.yellow:
        return Colors.yellow;
      case WizardExtremeSealColor.green:
        return Colors.green;
      case WizardExtremeSealColor.blue:
        return Colors.blue;
      case WizardExtremeSealColor.white:
        return Colors.white;
      case WizardExtremeSealColor.black:
        return Colors.black;
    }
  }
}

class _WizardExtremeRoundDialog extends StatefulWidget {
  final List<Player> players;
  final AppLocalizations l10n;

  const _WizardExtremeRoundDialog({required this.players, required this.l10n});

  @override
  State<_WizardExtremeRoundDialog> createState() =>
      _WizardExtremeRoundDialogState();
}

class _WizardExtremeRoundDialogState extends State<_WizardExtremeRoundDialog> {
  final Map<String, WizardExtremePlayerRound> _playerRounds = {};
  int _currentPlayerIndex = 0;

  @override
  void initState() {
    super.initState();
    for (final p in widget.players) {
      _playerRounds[p.id] = const WizardExtremePlayerRound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.players[_currentPlayerIndex];
    final pRound = _playerRounds[player.id]!;

    return AlertDialog(
      title: Text(
        'Player: ${player.name} (${_currentPlayerIndex + 1}/${widget.players.length})',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: const Text('Black Magician?'),
              value: pRound.isBlackMagician,
              onChanged: (val) {
                setState(() {
                  _playerRounds[player.id] = pRound.copyWith(
                    isBlackMagician: val ?? false,
                  );
                });
              },
            ),
            const Divider(),
            const Text(
              'Predicted Seals:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildSealInputs(
              pRound.predictedSeals,
              (seals) => setState(
                () => _playerRounds[player.id] = _playerRounds[player.id]!
                    .copyWith(predictedSeals: seals),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Actual Tricks (Returned Seals):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            _buildSealInputs(
              pRound.actualSeals,
              (seals) => setState(
                () => _playerRounds[player.id] = _playerRounds[player.id]!
                    .copyWith(actualSeals: seals),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Black Seals (Penalty): '),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: pRound.blackSeals > 0
                      ? () => setState(
                          () => _playerRounds[player.id] = pRound.copyWith(
                            blackSeals: pRound.blackSeals - 1,
                          ),
                        )
                      : null,
                ),
                Text(
                  '${pRound.blackSeals}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(
                    () => _playerRounds[player.id] = pRound.copyWith(
                      blackSeals: pRound.blackSeals + 1,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        if (_currentPlayerIndex > 0)
          TextButton(
            onPressed: () => setState(() => _currentPlayerIndex--),
            child: const Text('Back'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l10n.get('cancel')),
        ),
        FilledButton(
          onPressed: () {
            if (_currentPlayerIndex < widget.players.length - 1) {
              setState(() => _currentPlayerIndex++);
            } else {
              Navigator.pop(context, _playerRounds);
            }
          },
          child: Text(
            _currentPlayerIndex < widget.players.length - 1
                ? 'Next'
                : 'Save Round',
          ),
        ),
      ],
    );
  }

  Widget _buildSealInputs(
    List<WizardExtremeSeal> currentSeals,
    Function(List<WizardExtremeSeal>) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      children: WizardExtremeSealColor.values
          .where((c) => c != WizardExtremeSealColor.black)
          .map((color) {
            final seal = currentSeals.firstWhere(
              (s) => s.color == color,
              orElse: () => WizardExtremeSeal(color: color, count: 0),
            );
            return Column(
              children: [
                _SealChip(
                  seal: WizardExtremeSeal(color: color, count: 0),
                  isPredicted: true,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: seal.count > 0
                          ? () {
                              final newList = List<WizardExtremeSeal>.from(
                                currentSeals,
                              );
                              newList.removeWhere((s) => s.color == color);
                              if (seal.count > 1) {
                                newList.add(
                                  WizardExtremeSeal(
                                    color: color,
                                    count: seal.count - 1,
                                  ),
                                );
                              }
                              onChanged(newList);
                            }
                          : null,
                    ),
                    Text('${seal.count}'),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () {
                        final newList = List<WizardExtremeSeal>.from(
                          currentSeals,
                        );
                        newList.removeWhere((s) => s.color == color);
                        newList.add(
                          WizardExtremeSeal(
                            color: color,
                            count: seal.count + 1,
                          ),
                        );
                        onChanged(newList);
                      },
                    ),
                  ],
                ),
              ],
            );
          })
          .toList(),
    );
  }
}

extension on WizardExtremePlayerRound {
  WizardExtremePlayerRound copyWith({
    List<WizardExtremeSeal>? predictedSeals,
    List<WizardExtremeSeal>? actualSeals,
    int? blackSeals,
    bool? isBlackMagician,
  }) {
    return WizardExtremePlayerRound(
      predictedSeals: predictedSeals ?? this.predictedSeals,
      actualSeals: actualSeals ?? this.actualSeals,
      blackSeals: blackSeals ?? this.blackSeals,
      isBlackMagician: isBlackMagician ?? this.isBlackMagician,
    );
  }
}
