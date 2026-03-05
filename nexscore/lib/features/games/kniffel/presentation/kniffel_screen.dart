import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kniffel_models.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';

import '../providers/kniffel_provider.dart';

class KniffelScreen extends ConsumerWidget {
  const KniffelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheets = ref.watch(kniffelStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('game_kniffel'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    if (sheets.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(kniffelStateProvider.notifier)
            .initPlayers(players.map((p) => p.id).toList());
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: players.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.get('game_kniffel')),
          bottom: TabBar(
            isScrollable: true,
            tabs: players.map((p) => Tab(text: p.name)).toList(),
          ),
        ),
        body: TabBarView(
          children: players.map((p) {
            final sheet = sheets[p.id] ?? const YahtzeePlayerSheet();
            return _buildPlayerSheet(context, ref, p, sheet, l10n);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPlayerSheet(
    BuildContext context,
    WidgetRef ref,
    Player player,
    YahtzeePlayerSheet sheet,
    AppLocalizations l10n,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTotalRow(
            l10n.get('kniffel_total'),
            sheet.totalScore.toString(),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(l10n.get('kniffel_upper')),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.ones,
            l10n.get('kniffel_cat_aces'),
            l10n,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.twos,
            l10n.get('kniffel_cat_twos'),
            l10n,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.threes,
            l10n.get('kniffel_cat_threes'),
            l10n,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.fours,
            l10n.get('kniffel_cat_fours'),
            l10n,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.fives,
            l10n.get('kniffel_cat_fives'),
            l10n,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.sixes,
            l10n.get('kniffel_cat_sixes'),
            l10n,
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.get('kniffel_bonus')),
            trailing: Text(
              '${sheet.upperSectionSum} / ${sheet.upperSectionBonus}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(l10n.get('kniffel_lower')),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.threeOfAKind,
            l10n.get('kniffel_cat_3ofakind'),
            l10n,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.fourOfAKind,
            l10n.get('kniffel_cat_4ofakind'),
            l10n,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.fullHouse,
            l10n.get('kniffel_cat_fullhouse'),
            l10n,
            isFixed: true,
            fixedValue: 25,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.smallStraight,
            l10n.get('kniffel_cat_smstraight'),
            l10n,
            isFixed: true,
            fixedValue: 30,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.largeStraight,
            l10n.get('kniffel_cat_lgstraight'),
            l10n,
            isFixed: true,
            fixedValue: 40,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.yahtzee,
            l10n.get('kniffel_cat_yahtzee'),
            l10n,
            isFixed: true,
            fixedValue: 50,
          ),
          _buildScoreRow(
            context,
            ref,
            player.id,
            sheet,
            YahtzeeCategory.chance,
            l10n.get('kniffel_cat_chance'),
            l10n,
          ),
          const Divider(),
          _buildSectionTotalRow(
            l10n.get('kniffel_lower'),
            sheet.lowerSectionSum.toString(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTotalRow(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildScoreRow(
    BuildContext context,
    WidgetRef ref,
    String playerId,
    YahtzeePlayerSheet sheet,
    YahtzeeCategory category,
    String label,
    AppLocalizations l10n, {
    bool isFixed = false,
    int? fixedValue,
  }) {
    final hasScore = sheet.scores.containsKey(category);
    final score = sheet.scores[category];

    return ListTile(
      title: Text(label),
      trailing: hasScore
          ? Text(
              score.toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )
          : const Icon(Icons.edit, size: 20, color: Colors.grey),
      onTap: () {
        if (isFixed) {
          int newValue = (!hasScore || score == 0) ? fixedValue! : 0;
          ref
              .read(kniffelStateProvider.notifier)
              .updateScore(playerId, category, newValue);
        } else {
          _showInputDialog(context, ref, playerId, category, label, l10n);
        }
      },
    );
  }

  void _showInputDialog(
    BuildContext context,
    WidgetRef ref,
    String playerId,
    YahtzeeCategory category,
    String label,
    AppLocalizations l10n,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.getWith('kniffel_enter_score', [label])),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: l10n.get('history_pts')),
          autofocus: true,
          onSubmitted: (val) {
            final v = int.tryParse(val);
            if (v != null) {
              ref
                  .read(kniffelStateProvider.notifier)
                  .updateScore(playerId, category, v);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) {
                ref
                    .read(kniffelStateProvider.notifier)
                    .updateScore(playerId, category, val);
              }
              Navigator.pop(context);
            },
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }
}
