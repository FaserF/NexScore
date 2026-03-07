import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../models/qwixx_models.dart';

import '../providers/qwixx_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../../../../shared/widgets/winner_confetti_overlay.dart';

class QwixxScreen extends ConsumerStatefulWidget {
  const QwixxScreen({super.key});

  @override
  ConsumerState<QwixxScreen> createState() => _QwixxScreenState();
}

class _QwixxScreenState extends ConsumerState<QwixxScreen> {
  final _confettiController = WinnerConfettiController();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _showWinner(Map<String, QwixxPlayerSheet> sheets, List<Player> players) {
    if (sheets.isEmpty || players.isEmpty) return;
    String? winnerId;
    int maxScore = -1;
    for (final p in players) {
      final score = sheets[p.id]?.totalScore ?? 0;
      if (score > maxScore) {
        maxScore = score;
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
    final gameState = ref.watch(qwixxStateProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    if (players.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.get('qwixx_title'))),
        body: Center(child: Text(l10n.get('game_no_players'))),
      );
    }

    // Initialize sheets if not already done
    if (gameState.sheets.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(qwixxStateProvider.notifier)
            .initPlayers(players.map((p) => p.id).toList());
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final variantLabel = switch (gameState.variant) {
      QwixxVariant.original => l10n.get('qwixx_variant_original'),
      QwixxVariant.mixedColors => 'Mixx A (Colors)',
      QwixxVariant.mixedNumbers => 'Mixx B (Numbers)',
    };

    return DefaultTabController(
      length: players.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.get('qwixx_title')),
          leading: BackButton(onPressed: () => context.go('/games')),
          actions: [
            IconButton(
              icon: const Icon(Icons.emoji_events, color: Colors.amber),
              onPressed: () => _showWinner(gameState.sheets, players),
              tooltip: l10n.get('game_show_winner'),
            ),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                launchUrl(
                  Uri.parse(
                    'https://faserf.github.io/NexScore/docs/user_guide/games/#qwixx',
                  ),
                );
              },
              tooltip: l10n.get('nav_help'),
            ),
            Chip(
              label: Text(variantLabel),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () =>
                  _showVariantDialog(context, ref, gameState.variant, l10n),
              tooltip: l10n.get('game_settings'),
            ),
            if (ref.watch(qwixxStateProvider.notifier).canUndo)
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: () => ref.read(qwixxStateProvider.notifier).undo(),
                tooltip: l10n.get('game_undo'),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _confirmReset(context, ref, l10n),
              tooltip: l10n.get('game_reset'),
            ),
          ],
          bottom: TabBar(
            isScrollable: players.length > 3,
            tabs: players
                .map(
                  (p) => Tab(
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
                  ),
                )
                .toList(),
          ),
        ),
        body: WinnerConfettiOverlay(
          controller: _confettiController,
          child: MultiplayerClientOverlay(
            child: TabBarView(
              children: players.map((player) {
                final sheet =
                    gameState.sheets[player.id] ?? const QwixxPlayerSheet();
                return _QwixxPlayerView(
                  player: player,
                  sheet: sheet,
                  variant: gameState.variant,
                  onUpdate: (newSheet) => ref
                      .read(qwixxStateProvider.notifier)
                      .updateSheet(player.id, newSheet),
                  l10n: l10n,
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  void _showVariantDialog(
    BuildContext context,
    WidgetRef ref,
    QwixxVariant current,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('game_settings')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: QwixxVariant.values.map((v) {
            final label = switch (v) {
              QwixxVariant.original => l10n.get('qwixx_variant_original'),
              QwixxVariant.mixedColors => 'Mixx A (Mixed Colors)',
              QwixxVariant.mixedNumbers => 'Mixx B (Mixed Numbers)',
            };
            return RadioListTile<QwixxVariant>(
              title: Text(label),
              value: v,
              // ignore: deprecated_member_use
              groupValue: current,
              // ignore: deprecated_member_use
              onChanged: (newV) {
                if (newV != null) {
                  ref.read(qwixxStateProvider.notifier).setVariant(newV);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
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
              ref.read(qwixxStateProvider.notifier).resetGame();
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

class _QwixxPlayerView extends StatelessWidget {
  final Player player;
  final QwixxPlayerSheet sheet;
  final QwixxVariant variant;
  final Function(QwixxPlayerSheet) onUpdate;
  final AppLocalizations l10n;

  const _QwixxPlayerView({
    required this.player,
    required this.sheet,
    required this.variant,
    required this.onUpdate,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              l10n.getWith('qwixx_score_label', [sheet.totalScore.toString()]),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          _buildRow(
            context,
            0,
            Colors.red.shade300,
            sheet.red,
            (list) => onUpdate(sheet.copyWith(red: list)),
          ),
          const SizedBox(height: 8),
          _buildRow(
            context,
            1,
            Colors.yellow.shade600,
            sheet.yellow,
            (list) => onUpdate(sheet.copyWith(yellow: list)),
          ),
          const SizedBox(height: 8),
          _buildRow(
            context,
            2,
            Colors.green.shade400,
            sheet.green,
            (list) => onUpdate(sheet.copyWith(green: list)),
          ),
          const SizedBox(height: 8),
          _buildRow(
            context,
            3,
            Colors.blue.shade300,
            sheet.blue,
            (list) => onUpdate(sheet.copyWith(blue: list)),
          ),
          const SizedBox(height: 24),
          _buildPenaltiesRow(context),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    int rowIndex,
    Color baseColor,
    List<int> crossed,
    Function(List<int>) onRowUpdate,
  ) {
    final numbers = QwixxGameState.getRowNumbers(rowIndex, variant);

    // Mixx A (Mixed Colors) official mapping (simplified: we still use the row's base color mostly)
    // In a real Mixx A app, each cell would have its own color.
    // For now, we use the base row color.

    return Container(
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor, width: 2),
      ),
      padding: const EdgeInsets.all(8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...numbers.map((number) {
            bool isCrossed = crossed.contains(number);
            return GestureDetector(
              onTap: () {
                List<int> newList = List.from(crossed);
                if (isCrossed) {
                  newList.remove(number);
                } else {
                  newList.add(number);
                }
                onRowUpdate(newList);
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isCrossed
                      ? Colors.white
                      : baseColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: baseColor, width: 2),
                ),
                alignment: Alignment.center,
                child: isCrossed
                    ? const Icon(Icons.close, color: Colors.black, size: 32)
                    : Text(
                        '$number',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
              ),
            );
          }),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: baseColor, width: 2),
              color: baseColor.withValues(alpha: 0.4),
            ),
            child: const Icon(Icons.lock_outline, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPenaltiesRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${l10n.get('qwixx_penalties')}: ',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...List.generate(4, (index) {
          bool isChecked = index < sheet.penalties;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () {
                int newPenalties = isChecked ? index : index + 1;
                onUpdate(sheet.copyWith(penalties: newPenalties));
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isChecked
                    ? const Icon(Icons.close, color: Colors.red)
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }
}
