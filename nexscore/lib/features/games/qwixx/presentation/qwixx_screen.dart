import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../models/qwixx_models.dart';

import '../providers/qwixx_provider.dart';

class QwixxScreen extends ConsumerWidget {
  const QwixxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(qwixxStateProvider.notifier)
          .initPlayers(players.map((p) => p.id).toList());
    });

    if (gameState.sheets.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: players.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.get('qwixx_title')),
          leading: BackButton(onPressed: () => context.go('/games')),
          bottom: TabBar(
            isScrollable: players.length > 3,
            tabs: players.map((p) => Tab(text: p.name)).toList(),
          ),
        ),
        body: TabBarView(
          children: players.map((player) {
            final sheet =
                gameState.sheets[player.id] ?? const QwixxPlayerSheet();
            return _QwixxPlayerView(
              player: player,
              sheet: sheet,
              onUpdate: (newSheet) => ref
                  .read(qwixxStateProvider.notifier)
                  .updateSheet(player.id, newSheet),
              l10n: l10n,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _QwixxPlayerView extends StatelessWidget {
  final Player player;
  final QwixxPlayerSheet sheet;
  final Function(QwixxPlayerSheet) onUpdate;
  final AppLocalizations l10n;

  const _QwixxPlayerView({
    required this.player,
    required this.sheet,
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
            l10n.get('qwixx_red'),
            Colors.red.shade300,
            sheet.red,
            true,
            (list) => onUpdate(sheet.copyWith(red: list)),
          ),
          const SizedBox(height: 8),
          _buildRow(
            context,
            l10n.get('qwixx_yellow'),
            Colors.yellow.shade600,
            sheet.yellow,
            true,
            (list) => onUpdate(sheet.copyWith(yellow: list)),
          ),
          const SizedBox(height: 8),
          _buildRow(
            context,
            l10n.get('qwixx_green'),
            Colors.green.shade400,
            sheet.green,
            false,
            (list) => onUpdate(sheet.copyWith(green: list)),
          ),
          const SizedBox(height: 8),
          _buildRow(
            context,
            l10n.get('qwixx_blue'),
            Colors.blue.shade300,
            sheet.blue,
            false,
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
    String colorName,
    Color color,
    List<int> crossed,
    bool ascending,
    Function(List<int>) onRowUpdate,
  ) {
    List<int> numbers = ascending
        ? List.generate(11, (i) => i + 2)
        : List.generate(11, (i) => 12 - i);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
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
                      : color.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color, width: 2),
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
              border: Border.all(color: color, width: 2),
              color: color.withValues(alpha: 0.5),
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

// Add copyWith to QwixxPlayerSheet model dynamically for this file
extension QwixxPlayerSheetCopyWith on QwixxPlayerSheet {
  QwixxPlayerSheet copyWith({
    List<int>? red,
    List<int>? yellow,
    List<int>? green,
    List<int>? blue,
    int? penalties,
  }) {
    return QwixxPlayerSheet(
      red: red ?? this.red,
      yellow: yellow ?? this.yellow,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      penalties: penalties ?? this.penalties,
    );
  }
}
