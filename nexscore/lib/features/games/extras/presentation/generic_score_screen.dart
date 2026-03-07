import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../providers/generic_score_provider.dart';

class GenericScoreScreen extends ConsumerWidget {
  const GenericScoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(genericScoreProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('game_generic'))),
        body: Center(child: Text(l10n.get('sipdeck_no_players'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('game_generic')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _confirmReset(context, ref, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => ref.read(genericScoreProvider.notifier).addRound(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTableHeader(context, players),
            ...List.generate(state.rounds.length, (roundIndex) {
              return _buildRoundRow(
                context,
                ref,
                roundIndex,
                state.rounds[roundIndex],
                players,
              );
            }),
            const Divider(height: 32, thickness: 2),
            _buildFooterTotals(context, state, players, l10n),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, List players) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          const SizedBox(
            width: 50,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...players.map(
            (p) => Expanded(
              child: Text(
                p.name,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: p.color),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundRow(
    BuildContext context,
    WidgetRef ref,
    int roundIndex,
    List<int> roundScores,
    List players,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '${roundIndex + 1}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ...List.generate(players.length, (playerIndex) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: TextField(
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hintText: '0',
                  ),
                  onChanged: (val) {
                    final score = int.tryParse(val) ?? 0;
                    ref
                        .read(genericScoreProvider.notifier)
                        .updateScore(roundIndex, playerIndex, score);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooterTotals(
    BuildContext context,
    dynamic state,
    List players,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Row(
        children: [
          const SizedBox(
            width: 42,
            child: Icon(Icons.functions, color: Colors.grey),
          ),
          ...players.map((p) {
            final total = state.playerTotals[p.id] ?? 0;
            return Expanded(
              child: Column(
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    width: 30,
                    decoration: BoxDecoration(
                      color: p.color,
                      borderRadius: BorderRadius.circular(2),
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
              ref.read(genericScoreProvider.notifier).reset();
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
