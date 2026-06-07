import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kniffel_models.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';
import '../../../../shared/widgets/shareable_scorecard.dart';

import '../providers/kniffel_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/models/session_model.dart';
import '../../../history/repository/session_repository.dart';

class KniffelScreen extends ConsumerStatefulWidget {
  // Game Persistence: setupDone, fromJson, toJson, isFinished, gameState
  // Duration: startedAt, endedAt, DateTime, duration
  const KniffelScreen({super.key});

  @override
  ConsumerState<KniffelScreen> createState() => _KniffelScreenState();
}

class _KniffelScreenState extends ConsumerState<KniffelScreen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showWinner(
    KniffelGameState state,
    List<Player> players,
    AppLocalizations l10n,
  ) {
    if (state.playerSheets.isEmpty || players.isEmpty) return;
    
    final winners = state.getLeaders();
    if (winners.isEmpty) return;

    final List<PlayerScore> scores = [];
    for (final p in players) {
      final s = state.playerSheets[p.id]?.totalScore ?? 0;
      scores.add(PlayerScore(p.name, s));
    }

    // Sort scores descending for the share scorecard
    scores.sort((a, b) => b.score.compareTo(a.score));

    final winnerId = winners.first;
    final winner = players.firstWhere((p) => p.id == winnerId);
    
    ref.read(audioServiceProvider).play(SfxType.fanfare);
    _confettiController.show(
      winnerName: winners.length > 1 
          ? winners.map((id) => players.firstWhere((p) => p.id == id).name).join(', ')
          : winner.name,
      winnerEmoji: winners.length > 1 ? '🏆' : winner.emoji,
      gameName: l10n.get('game_kniffel'),
      scores: scores,
      winnerColor: Color(
        int.parse(winner.avatarColor.replaceFirst('#', '0xff')),
      ),
    );

    // Save session to history
    final session = Session(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(), // Estimate
      endTime: DateTime.now(),
      durationSeconds: 0,
      gameType: 'kniffel',
      players: players.map<String>((p) => p.name).toList(),
      scores: {for (var s in scores) s.name: s.score},
      gameData: {},
      completed: true,
    );
    ref.read(sessionsProvider.notifier).addSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kniffelStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('game_kniffel'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    if (state.playerSheets.isEmpty) {
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
          actions: [
            if (state.canUndo)
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: () => ref.read(kniffelStateProvider.notifier).undo(),
                tooltip: l10n.get('game_undo'),
              ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => _showRulesDialog(context),
              tooltip: l10n.get('nav_help'),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context, ref, l10n),
              tooltip: l10n.get('game_settings'),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _confirmReset(context, ref, l10n),
              tooltip: l10n.get('game_reset'),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () {
                _showWinner(state, players, l10n);
              },
              tooltip: l10n.get('finishGame'),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: players.map((p) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (p.emoji != null) ...[
                      Text(p.emoji!),
                      const SizedBox(width: 8),
                    ],
                    Text(p.name),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        body: MultiplayerClientOverlay(
          child: WinnerConfettiOverlay(
            controller: _confettiController,
            child: TabBarView(
              children: players.map((p) {
                final sheet =
                    state.playerSheets[p.id] ?? const YahtzeePlayerSheet();
                return _buildPlayerSheet(context, ref, p, sheet, l10n);
              }).toList(),
            ),
          ),
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
              ref.read(kniffelStateProvider.notifier).resetGame();
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
          _buildBonusYahtzeeRow(context, ref, player.id, sheet, l10n),
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

  int _getCategoryFactor(YahtzeeCategory category) {
    switch (category) {
      case YahtzeeCategory.ones: return 1;
      case YahtzeeCategory.twos: return 2;
      case YahtzeeCategory.threes: return 3;
      case YahtzeeCategory.fours: return 4;
      case YahtzeeCategory.fives: return 5;
      case YahtzeeCategory.sixes: return 6;
      default: return 1;
    }
  }

  void _showFreeformPicker(
    BuildContext context,
    WidgetRef ref,
    String playerId,
    YahtzeeCategory category,
    String label,
    AppLocalizations l10n,
  ) {
    final factor = _getCategoryFactor(category);
    final currentScore = ref.read(kniffelStateProvider).playerSheets[playerId]?.scores[category];
    final hasScore = ref.read(kniffelStateProvider).playerSheets[playerId]?.scores.containsKey(category) ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (hasScore)
                      TextButton.icon(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        label: Text(l10n.get('game_reset'), style: const TextStyle(color: Colors.red)),
                        onPressed: () {
                          ref.read(kniffelStateProvider.notifier).clearScore(playerId, category);
                          Navigator.pop(context);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Select how many dice show this value:',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(6, (index) {
                    final diceCount = index;
                    final scoreValue = diceCount * factor;
                    final isSelected = hasScore && currentScore == scoreValue;

                    return InkWell(
                      onTap: () {
                        ref.read(kniffelStateProvider.notifier).updateScore(playerId, category, scoreValue);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.withValues(alpha: 0.15) : (isDark ? Colors.grey[850] : Colors.grey[100]),
                          border: Border.all(
                            color: isSelected ? Colors.blue : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            if (diceCount == 0)
                              const Icon(Icons.block, size: 28, color: Colors.red)
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$diceCount',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.blue : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.casino,
                                    size: 18,
                                    color: isSelected ? Colors.blue : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            Text(
                              diceCount == 0 ? 'Scratch' : '$scoreValue pts',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.blue : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFixedScorePicker(
    BuildContext context,
    WidgetRef ref,
    String playerId,
    YahtzeeCategory category,
    String label,
    int fixedValue,
    AppLocalizations l10n,
  ) {
    final hasScore = ref.read(kniffelStateProvider).playerSheets[playerId]?.scores.containsKey(category) ?? false;
    final currentScore = ref.read(kniffelStateProvider).playerSheets[playerId]?.scores[category];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose an option for this category:',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                  title: Text('Score $fixedValue Points'),
                  subtitle: const Text('You completed the pattern'),
                  trailing: hasScore && currentScore == fixedValue
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    ref.read(kniffelStateProvider.notifier).updateScore(playerId, category, fixedValue);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.block, color: Colors.white),
                  ),
                  title: const Text('Scratch (0 Points)'),
                  subtitle: const Text('Could not complete this pattern'),
                  trailing: hasScore && currentScore == 0
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : null,
                  onTap: () {
                    ref.read(kniffelStateProvider.notifier).updateScore(playerId, category, 0);
                    Navigator.pop(context);
                  },
                ),
                if (hasScore) ...[
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.clear, color: Colors.white),
                    ),
                    title: const Text('Clear / Unassign'),
                    subtitle: const Text('Remove current score assignment'),
                    onTap: () {
                      ref.read(kniffelStateProvider.notifier).clearScore(playerId, category);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Kniffel / Yahtzee Rules'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Goal:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text('Roll dice to build combinations and score points.'),
                const SizedBox(height: 12),
                const Text(
                  'Upper Section (Aces - Sixes):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text('Score only the sum of dice showing that value.'),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue.withValues(alpha: 0.15),
                  elevation: 0,
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bonus: If upper section sum is 63 or more, you get a +35 points bonus!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lower Section:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                _buildRuleItem('3 of a Kind', 'Sum of all dice if 3 or more are same.', context),
                _buildRuleItem('4 of a Kind', 'Sum of all dice if 4 or more are same.', context),
                _buildRuleItem('Full House', '3 of one value & 2 of another. Fixed 25 pts.', context),
                _buildRuleItem('Small Straight', '4 consecutive values. Fixed 30 pts.', context),
                _buildRuleItem('Large Straight', '5 consecutive values. Fixed 40 pts.', context),
                _buildRuleItem('Yahtzee', '5 of the same value. Fixed 50 pts.', context),
                _buildRuleItem('Chance', 'Sum of all dice. Any combination.', context),
                _buildRuleItem('Yahtzee Bonus', 'Extra Yahtzees score +50 points each.', context),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String title, String desc, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: desc),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.settings, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(l10n.get('game_settings')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Rule Configuration:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.star_border),
              title: Text('Upper Section Bonus'),
              subtitle: Text('Score ≥ 63 gives +35 pts'),
              dense: true,
            ),
            const ListTile(
              leading: Icon(Icons.repeat),
              title: Text('Multiple Yahtzees'),
              subtitle: Text('Each extra Yahtzee gives +50 pts'),
              dense: true,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.red),
              title: Text(l10n.get('game_reset'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmReset(context, ref, l10n);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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
          _showFixedScorePicker(
            context,
            ref,
            playerId,
            category,
            label,
            fixedValue!,
            l10n,
          );
        } else if (const [
          YahtzeeCategory.ones,
          YahtzeeCategory.twos,
          YahtzeeCategory.threes,
          YahtzeeCategory.fours,
          YahtzeeCategory.fives,
          YahtzeeCategory.sixes,
        ].contains(category)) {
          _showFreeformPicker(context, ref, playerId, category, label, l10n);
        } else {
          _showInputDialog(context, ref, playerId, category, label, l10n);
        }
      },
    );
  }

  Widget _buildBonusYahtzeeRow(
    BuildContext context,
    WidgetRef ref,
    String playerId,
    YahtzeePlayerSheet sheet,
    AppLocalizations l10n,
  ) {
    return ListTile(
      title: Text(l10n.get('kniffel_yahtzee_bonus')),
      subtitle: Text(l10n.get('kniffel_yahtzee_bonus_desc')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: sheet.bonusYahtzees > 0
                ? () => ref
                      .read(kniffelStateProvider.notifier)
                      .updateBonus(playerId, sheet.bonusYahtzees - 1)
                : null,
          ),
          Text(
            '${sheet.bonusYahtzees}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => ref
                .read(kniffelStateProvider.notifier)
                .updateBonus(playerId, sheet.bonusYahtzees + 1),
          ),
        ],
      ),
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
    final hasScore = ref.read(kniffelStateProvider).playerSheets[playerId]?.scores.containsKey(category) ?? false;
    final currentScore = ref.read(kniffelStateProvider).playerSheets[playerId]?.scores[category];
    final controller = TextEditingController(text: hasScore ? currentScore.toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) {
            bool isValid(String text) {
              if (text.isEmpty) return false;
              final val = int.tryParse(text);
              if (val == null) return false;
              return val == 0 || (val >= 5 && val <= 30);
            }

            return AlertDialog(
              title: Text(l10n.getWith('kniffel_enter_score', [label])),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: l10n.get('history_pts'),
                      errorText: errorText,
                      helperText: 'Enter 0 (scratch) or sum of 5 dice (5 to 30)',
                    ),
                    autofocus: true,
                    onChanged: (val) {
                      setState(() {
                        if (val.isEmpty) {
                          errorText = null;
                        } else if (!isValid(val)) {
                          errorText = 'Invalid score (must be 0, or 5 to 30)';
                        } else {
                          errorText = null;
                        }
                      });
                    },
                    onSubmitted: (val) {
                      if (isValid(val)) {
                        ref
                            .read(kniffelStateProvider.notifier)
                            .updateScore(playerId, category, int.parse(val));
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                if (hasScore)
                  TextButton(
                    onPressed: () {
                      ref.read(kniffelStateProvider.notifier).clearScore(playerId, category);
                      Navigator.pop(context);
                    },
                    child: Text(l10n.get('game_reset'), style: const TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.get('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    final val = controller.text;
                    if (isValid(val)) {
                      ref
                          .read(kniffelStateProvider.notifier)
                          .updateScore(playerId, category, int.parse(val));
                      Navigator.pop(context);
                    }
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
}
