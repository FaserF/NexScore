import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../models/phase10_digital_engine.dart';
import '../providers/phase10_digital_provider.dart';

class Phase10DigitalScreen extends ConsumerStatefulWidget {
  const Phase10DigitalScreen({super.key});

  @override
  ConsumerState<Phase10DigitalScreen> createState() =>
      _Phase10DigitalScreenState();
}

class _Phase10DigitalScreenState extends ConsumerState<Phase10DigitalScreen> {
  final Set<String> _selectedCardIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(phase10DigitalProvider);
    final players = ref.watch(activePlayersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Phase 10'),
        leading: BackButton(onPressed: () => context.go('/games')),
      ),
      body: MultiplayerClientOverlay(
        child: _buildContent(context, state, players),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Phase10DigitalState state,
    List players,
  ) {
    switch (state.phase) {
      case Phase10DigitalPhase.setup:
        return _buildSetup(context, players);
      case Phase10DigitalPhase.playing:
        return _buildPlaying(context, state, players);
      case Phase10DigitalPhase.finished:
        return _buildFinished(context, state, players);
    }
  }

  Widget _buildSetup(BuildContext context, List players) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.format_list_numbered,
              size: 80,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
            Text(
              'Digital Phase 10',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '10 Phasen, wer schafft sie zuerst?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: players.length >= 2
                  ? () => ref
                        .read(phase10DigitalProvider.notifier)
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
            if (players.length < 2) ...[
              const SizedBox(height: 16),
              const Text(
                'Mindestens 2 Spieler benötigt',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaying(
    BuildContext context,
    Phase10DigitalState state,
    List players,
  ) {
    final currentPlayer = players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => players.first,
    );
    final pState = state.playerStates[state.currentPlayerId!]!;
    final phaseDef = Phase10PhaseDefinition.allPhases[pState.currentPhase - 1];
    final topDiscard = state.discardPile.isNotEmpty
        ? state.discardPile.last
        : null;

    return Column(
      children: [
        // Phase info
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currentPlayer.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Phase ${pState.currentPhase}: ${phaseDef.descriptionDe}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Runde ${state.roundNumber}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (pState.hasLaidPhase)
                    const Text(
                      '✓ Phase gelegt',
                      style: TextStyle(color: Colors.green, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Draw area
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: !pState.hasDrawn
                    ? () => ref
                          .read(phase10DigitalProvider.notifier)
                          .drawFromPile()
                    : null,
                child: Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.layers, color: Colors.white, size: 16),
                      Text(
                        '${state.drawPile.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: !pState.hasDrawn && topDiscard != null
                    ? () => ref
                          .read(phase10DigitalProvider.notifier)
                          .drawFromDiscard()
                    : null,
                child: Container(
                  width: 50,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !pState.hasDrawn ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Center(
                    child: topDiscard != null
                        ? Text(
                            topDiscard.shortLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _cardColor(topDiscard),
                            ),
                          )
                        : const Text(
                            'Leer',
                            style: TextStyle(color: Colors.grey, fontSize: 9),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Action bar
        if (pState.hasDrawn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                if (!pState.hasLaidPhase && _selectedCardIds.length >= 3)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final cards = pState.hand
                            .where((c) => _selectedCardIds.contains(c.id))
                            .toList();
                        ref
                            .read(phase10DigitalProvider.notifier)
                            .layPhase(cards);
                        setState(() => _selectedCardIds.clear());
                      },
                      icon: const Icon(Icons.check),
                      label: Text('Phase legen (${_selectedCardIds.length})'),
                    ),
                  ),
                if (!pState.hasLaidPhase && _selectedCardIds.length >= 3)
                  const SizedBox(width: 8),
                if (_selectedCardIds.length == 1)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final card = pState.hand.firstWhere(
                          (c) => _selectedCardIds.contains(c.id),
                        );
                        ref
                            .read(phase10DigitalProvider.notifier)
                            .discardCard(card);
                        setState(() => _selectedCardIds.clear());
                      },
                      icon: const Icon(Icons.move_down),
                      label: const Text('Abwerfen'),
                    ),
                  ),
              ],
            ),
          ),
        if (!pState.hasDrawn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14),
                SizedBox(width: 6),
                Text(
                  'Ziehe zuerst eine Karte!',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        // Player status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: state.playerOrder.map((pid) {
              final player = players.firstWhere(
                (p) => p.id == pid,
                orElse: () => players.first,
              );
              final ps = state.playerStates[pid]!;
              final isActive = pid == state.currentPlayerId;
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        player.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'P${ps.currentPhase}',
                        style: const TextStyle(fontSize: 9),
                      ),
                      Text(
                        '${ps.hand.length}🃏',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Hand
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Deine Karten (${pState.hand.length}):',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    if (_selectedCardIds.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedCardIds.clear()),
                        child: const Text(
                          'Auswahl aufheben',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: pState.hand.map((card) {
                        final isSelected = _selectedCardIds.contains(card.id);
                        return GestureDetector(
                          onTap: pState.hasDrawn
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedCardIds.remove(card.id);
                                    } else {
                                      _selectedCardIds.add(card.id);
                                    }
                                  });
                                }
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 44,
                            height: 62,
                            transform: isSelected
                                ? (Matrix4.identity()..translate(0.0, -8.0))
                                : Matrix4.identity(),
                            decoration: BoxDecoration(
                              color: card.isWild
                                  ? Colors.purple.shade50
                                  : card.isSkip
                                  ? Colors.grey.shade200
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : _cardColor(card).withValues(alpha: 0.4),
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? Colors.blue.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.1),
                                  blurRadius: isSelected ? 6 : 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                card.shortLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: card.isWild || card.isSkip
                                      ? 14
                                      : 16,
                                  color: card.isWild
                                      ? Colors.purple
                                      : card.isSkip
                                      ? Colors.grey
                                      : _cardColor(card),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinished(
    BuildContext context,
    Phase10DigitalState state,
    List players,
  ) {
    final sorted = List<String>.from(state.playerOrder)
      ..sort((a, b) {
        final aPhase = state.playerStates[a]!.currentPhase;
        final bPhase = state.playerStates[b]!.currentPhase;
        if (aPhase != bPhase) return bPhase.compareTo(aPhase);
        return (state.playerStates[a]?.totalPoints ?? 0).compareTo(
          state.playerStates[b]?.totalPoints ?? 0,
        );
      });

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
                final ps = state.playerStates[pid]!;
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
                      'Phase ${ps.currentPhase} · ${ps.totalPoints} Strafpunkte',
                    ),
                    trailing: Text(
                      'P${ps.currentPhase}',
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

  Color _cardColor(Phase10Card card) {
    if (card.isWild) return Colors.purple;
    if (card.isSkip) return Colors.grey;
    return [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.amber.shade700,
    ][card.colorIndex];
  }
}
