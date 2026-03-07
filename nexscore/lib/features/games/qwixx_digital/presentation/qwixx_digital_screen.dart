import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../models/qwixx_digital_engine.dart';
import '../providers/qwixx_digital_provider.dart';

class QwixxDigitalScreen extends ConsumerWidget {
  const QwixxDigitalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qwixxDigitalProvider);
    final players = ref.watch(activePlayersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Qwixx'),
        leading: BackButton(onPressed: () => context.go('/games')),
      ),
      body: MultiplayerClientOverlay(
        child: _buildContent(context, ref, state, players),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    QwixxDigitalState state,
    List players,
  ) {
    switch (state.phase) {
      case QwixxDigitalPhase.setup:
        return _buildSetup(context, ref, players);
      case QwixxDigitalPhase.rolling:
        return _buildRolling(context, ref, state, players);
      case QwixxDigitalPhase.whiteChoice:
      case QwixxDigitalPhase.colorChoice:
      case QwixxDigitalPhase.otherPlayers:
      case QwixxDigitalPhase.roundEnd:
        return _buildPlaying(context, ref, state, players);
      case QwixxDigitalPhase.finished:
        return _buildFinished(context, state, players);
    }
  }

  Widget _buildSetup(BuildContext context, WidgetRef ref, List players) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_on, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            Text(
              'Digital Qwixx',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '6 Würfel, 4 Farbreihen, kreuze clever an!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: players.isNotEmpty
                  ? () => ref
                        .read(qwixxDigitalProvider.notifier)
                        .startGame(
                          players.map<String>((p) => p.id as String).toList(),
                        )
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Spiel starten'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(250, 60),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolling(
    BuildContext context,
    WidgetRef ref,
    QwixxDigitalState state,
    List players,
  ) {
    final activePlayer = players.firstWhere(
      (p) => p.id == state.activePlayerId,
      orElse: () => players.first,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${activePlayer.name} würfelt',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(qwixxDigitalProvider.notifier).rollDice(),
              icon: const Icon(Icons.casino, size: 32),
              label: const Text('Würfeln!'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 64),
                textStyle: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaying(
    BuildContext context,
    WidgetRef ref,
    QwixxDigitalState state,
    List players,
  ) {
    final activePlayer = players.firstWhere(
      (p) => p.id == state.activePlayerId,
      orElse: () => players.first,
    );
    final pState = state.playerStates[state.activePlayerId!]!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Dice display
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  '${activePlayer.name} · Runde ${state.roundNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DiceChip(value: state.whiteDice[0], color: Colors.white),
                    const SizedBox(width: 6),
                    _DiceChip(value: state.whiteDice[1], color: Colors.white),
                    const SizedBox(width: 16),
                    _DiceChip(value: state.colorDice[0], color: Colors.red),
                    const SizedBox(width: 6),
                    _DiceChip(value: state.colorDice[1], color: Colors.yellow),
                    const SizedBox(width: 6),
                    _DiceChip(value: state.colorDice[2], color: Colors.green),
                    const SizedBox(width: 6),
                    _DiceChip(value: state.colorDice[3], color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Weiß-Summe: ${state.whiteSum}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          // Phase indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _phaseLabel(state.phase),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (state.phase == QwixxDigitalPhase.otherPlayers) {
                      ref.read(qwixxDigitalProvider.notifier).endRound();
                    } else {
                      ref.read(qwixxDigitalProvider.notifier).skipPhase();
                    }
                  },
                  icon: Icon(
                    state.phase == QwixxDigitalPhase.otherPlayers
                        ? Icons.check_circle_outline
                        : Icons.skip_next,
                    size: 18,
                  ),
                  label: Text(
                    state.phase == QwixxDigitalPhase.otherPlayers
                        ? 'Runde beenden'
                        : 'Überspringen',
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ..._buildRows(context, ref, state, pState),
          // Penalties
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fehlwürfe: ${pState.penalties} × (−5) = ${pState.penalties * -5}',
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.red),
                  onPressed: () => ref
                      .read(qwixxDigitalProvider.notifier)
                      .addPenalty(state.activePlayerId!),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Gesamt: ${pState.totalScore}',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRows(
    BuildContext context,
    WidgetRef ref,
    QwixxDigitalState state,
    QwixxDigitalPlayerState pState,
  ) {
    return QwixxColor.values.map((color) {
      final row = pState.rows[color]!;
      final rowColor = _qwixxColor(color);
      final isLocked = row.isLocked || state.globalLockedRows.contains(color);

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: rowColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isLocked ? Colors.grey : rowColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            ...row.numbers.map((number) {
              final isCrossed = row.crossedNumbers.contains(number);
              final canCross = !isLocked && row.canCross(number);

              // Check if this number matches white sum or color sum
              bool isWhiteOption =
                  number == state.whiteSum &&
                  state.phase == QwixxDigitalPhase.whiteChoice;
              bool isColorOption =
                  number == state.colorSums[color] &&
                  state.phase == QwixxDigitalPhase.colorChoice;

              return Expanded(
                child: GestureDetector(
                  onTap: canCross && (isWhiteOption || isColorOption)
                      ? () {
                          if (isWhiteOption) {
                            ref
                                .read(qwixxDigitalProvider.notifier)
                                .crossWhiteSum(state.activePlayerId!, color);
                          } else if (isColorOption) {
                            ref
                                .read(qwixxDigitalProvider.notifier)
                                .crossColorSum(state.activePlayerId!, color);
                          }
                        }
                      : null,
                  child: Container(
                    height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isCrossed
                          ? rowColor.withValues(alpha: 0.7)
                          : (isWhiteOption || isColorOption) && canCross
                          ? rowColor.withValues(alpha: 0.3)
                          : rowColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: (isWhiteOption || isColorOption) && canCross
                          ? Border.all(color: rowColor, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCrossed
                          ? const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            )
                          : Text(
                              '$number',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: rowColor,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }),
            // Lock icon
            Container(
              width: 30,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLocked ? rowColor : rowColor.withValues(alpha: 0.1),
              ),
              child: Icon(
                isLocked ? Icons.lock : Icons.lock_outline,
                size: 14,
                color: isLocked ? Colors.white : rowColor,
              ),
            ),
            // Row score
            SizedBox(
              width: 28,
              child: Text(
                '${row.score}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: rowColor,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildFinished(
    BuildContext context,
    QwixxDigitalState state,
    List players,
  ) {
    final sorted = List<String>.from(state.playerOrder)
      ..sort(
        (a, b) => (state.playerStates[b]?.totalScore ?? 0).compareTo(
          state.playerStates[a]?.totalScore ?? 0,
        ),
      );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Spiel beendet!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final pid = sorted[index];
                final player = players.firstWhere(
                  (p) => p.id == pid,
                  orElse: () => players.first,
                );
                final pState = state.playerStates[pid]!;
                return Card(
                  color: index == 0
                      ? Colors.amber.withValues(alpha: 0.15)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0 ? Colors.amber : Colors.grey,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Rot: ${pState.rows[QwixxColor.red]?.score ?? 0} · '
                      'Gelb: ${pState.rows[QwixxColor.yellow]?.score ?? 0} · '
                      'Grün: ${pState.rows[QwixxColor.green]?.score ?? 0} · '
                      'Blau: ${pState.rows[QwixxColor.blue]?.score ?? 0} · '
                      'Fehlwürfe: −${pState.penalties * 5}',
                    ),
                    trailing: Text(
                      '${pState.totalScore}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _phaseLabel(QwixxDigitalPhase phase) {
    return switch (phase) {
      QwixxDigitalPhase.whiteChoice => 'Weiß-Summe ankreuzen?',
      QwixxDigitalPhase.colorChoice => 'Weiß+Farbe ankreuzen?',
      QwixxDigitalPhase.otherPlayers => 'Andere Spieler (Weiß)',
      _ => '',
    };
  }

  Color _qwixxColor(QwixxColor color) {
    return switch (color) {
      QwixxColor.red => Colors.red,
      QwixxColor.yellow => Colors.amber.shade700,
      QwixxColor.green => Colors.green,
      QwixxColor.blue => Colors.blue,
    };
  }
}

/// Dice display chip.
class _DiceChip extends StatelessWidget {
  final int value;
  final Color color;

  const _DiceChip({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isWhite = color == Colors.white;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWhite ? Colors.grey : color.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2),
        ],
      ),
      child: Center(
        child: Text(
          '$value',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isWhite ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
