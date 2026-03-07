import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../models/arschloch_models.dart';
import '../providers/arschloch_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';

class ArschlochScreen extends ConsumerStatefulWidget {
  const ArschlochScreen({super.key});

  @override
  ConsumerState<ArschlochScreen> createState() => _ArschlochScreenState();
}

class _ArschlochScreenState extends ConsumerState<ArschlochScreen> {
  bool _isBannerDismissed = false;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arschlochStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('game_arschloch'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    final leaders = state.getLeaders();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_arschloch')),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              launchUrl(
                Uri.parse(
                  'https://faserf.github.io/NexScore/docs/user_guide/games/#arschloch',
                ),
              );
            },
            tooltip: l10n.get('nav_help'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
            tooltip: l10n.get('settings'),
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
            if (players.length == 2 && !_isBannerDismissed)
              MaterialBanner(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                content: Text(
                  l10n.get('arschloch_2player_warning'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                actions: [
                  TextButton(
                    onPressed: () => setState(() => _isBannerDismissed = true),
                    child: Text(l10n.get('ok')),
                  ),
                ],
              ),

            // Instructions for card exchange
            if (state.rounds.isNotEmpty)
              _buildExchangeBanner(state, players, l10n),

            Expanded(
              child: ListView.builder(
                itemCount: leaders.length,
                itemBuilder: (context, index) {
                  final playerId = leaders[index];
                  final player = players.firstWhere((p) => p.id == playerId);
                  final pState = state.playerStates[playerId]!;

                  final rankLabel = pState.lastRank != null
                      ? (state.customRankNames?[pState.lastRank!] ??
                            (l10n.locale.languageCode == 'de'
                                ? pState.lastRank!.labelDe()
                                : pState.lastRank!.labelEn()))
                      : l10n.get('arschloch_no_rank');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                        int.parse(player.avatarColor.replaceFirst('#', '0xff')),
                      ),
                      child: Text(player.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(player.name),
                    subtitle: Text(
                      '${l10n.get('leaderboard_score')}: ${pState.points} · $rankLabel',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (pState.roundsAsPresident > 0)
                          _buildStatChip(
                            context,
                            'P: ${pState.roundsAsPresident}',
                            Colors.amber.shade700,
                          ),
                        const SizedBox(width: 4),
                        if (pState.roundsAsArschloch > 0)
                          _buildStatChip(
                            context,
                            'A: ${pState.roundsAsArschloch}',
                            Colors.brown,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FilledButton.icon(
                onPressed: () =>
                    _showAddRoundDialog(context, ref, players, state),
                icon: const Icon(Icons.add),
                label: Text(
                  l10n.getWith('wizard_next_round', [
                    (state.rounds.length + 1).toString(),
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
    );
  }

  Widget _buildExchangeBanner(
    ArschlochGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    final lastRound = state.rounds.last;
    final playerNames = {for (var p in players) p.id: p.name};
    final instructions = ArschlochGameState.cardExchangeInstructions(
      lastRound.finishOrder,
      playerNames,
      players.length,
      state.cardSwappingCount,
    );

    if (instructions.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Karten-Tausch',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...instructions.map(
            (ins) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $ins',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(arschlochStateProvider);
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l10n.get('settings')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Punkte zählen'),
                    value: state.usePoints,
                    onChanged: (val) {
                      ref
                          .read(arschlochStateProvider.notifier)
                          .updateState(state.copyWith(usePoints: val));
                    },
                  ),
                  const Divider(),
                  const Text(
                    'Karten-Tausch (Präsident)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [0, 1, 2]
                        .map(
                          (count) => ChoiceChip(
                            label: Text('$count'),
                            selected: state.cardSwappingCount == count,
                            onSelected: (val) {
                              if (val) {
                                ref
                                    .read(arschlochStateProvider.notifier)
                                    .updateState(
                                      state.copyWith(cardSwappingCount: count),
                                    );
                              }
                            },
                          ),
                        )
                        .toList(),
                  ),
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
      },
    );
  }

  Future<void> _showAddRoundDialog(
    BuildContext context,
    WidgetRef ref,
    List<Player> players,
    ArschlochGameState gameState,
  ) async {
    final List<String?> finishOrder = List.filled(players.length, null);
    final List<String> availablePlayerIds = players.map((p) => p.id).toList();

    await showDialog(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                '${l10n.get('wizard_round')} ${gameState.rounds.length + 1}',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(players.length, (index) {
                    final position = index + 1;
                    final rank = ArschlochGameState.rankFromPosition(
                      position,
                      players.length,
                    );

                    final rankLabel =
                        gameState.customRankNames?[rank] ??
                        (l10n.locale.languageCode == 'de'
                            ? rank.labelDe()
                            : rank.labelEn());

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            alignment: Alignment.center,
                            child: Text(
                              '$position.',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: finishOrder[index],
                              hint: Text(rankLabel),
                              items: availablePlayerIds
                                  .where(
                                    (id) =>
                                        !finishOrder.contains(id) ||
                                        finishOrder[index] == id,
                                  )
                                  .map((id) {
                                    final p = players.firstWhere(
                                      (p) => p.id == id,
                                    );
                                    return DropdownMenuItem(
                                      value: id,
                                      child: Text(p.name),
                                    );
                                  })
                                  .toList(),
                              onChanged: (id) {
                                setDialogState(() {
                                  finishOrder[index] = id;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('cancel')),
                ),
                FilledButton(
                  onPressed: finishOrder.contains(null)
                      ? null
                      : () {
                          final Map<String, int> order = {
                            for (int i = 0; i < finishOrder.length; i++)
                              finishOrder[i]!: i + 1,
                          };
                          ref
                              .read(arschlochStateProvider.notifier)
                              .addRound(
                                ArschlochRound(
                                  roundIndex: gameState.rounds.length + 1,
                                  finishOrder: order,
                                ),
                              );
                          Navigator.pop(context);
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
              ref.read(arschlochStateProvider.notifier).resetGame();
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
