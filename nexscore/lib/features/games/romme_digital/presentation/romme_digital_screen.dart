import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../models/romme_digital_engine.dart';
import '../providers/romme_digital_provider.dart';

class RommeDigitalScreen extends ConsumerStatefulWidget {
  const RommeDigitalScreen({super.key});

  @override
  ConsumerState<RommeDigitalScreen> createState() => _RommeDigitalScreenState();
}

class _RommeDigitalScreenState extends ConsumerState<RommeDigitalScreen> {
  final Set<String> _selectedCardIds = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rommeDigitalProvider);
    final players = ref.watch(activePlayersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Rommé'),
        leading: BackButton(onPressed: () => context.go('/games')),
      ),
      body: MultiplayerClientOverlay(
        child: _buildContent(context, state, players),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    RommeDigitalState state,
    List players,
  ) {
    switch (state.phase) {
      case RommeDigitalPhase.setup:
        return _buildSetup(context, players);
      case RommeDigitalPhase.playing:
        return _buildPlaying(context, state, players);
      case RommeDigitalPhase.finished:
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
            const Icon(Icons.style, size: 80, color: Colors.indigo),
            const SizedBox(height: 24),
            Text(
              'Digital Rommé',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Ziehe, lege aus, lege an — werde deine Karten los!',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            FilledButton.icon(
              onPressed: players.length >= 2
                  ? () => ref
                        .read(rommeDigitalProvider.notifier)
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
    RommeDigitalState state,
    List players,
  ) {
    final currentPlayer = players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => players.first,
    );
    final pState = state.playerStates[state.currentPlayerId!]!;
    final topDiscard = state.discardPile.isNotEmpty
        ? state.discardPile.last
        : null;

    return Column(
      children: [
        // Player info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentPlayer.name}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Runde ${state.roundNumber}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        // Draw area
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Draw pile
              GestureDetector(
                onTap: !pState.hasDrawn
                    ? () =>
                          ref.read(rommeDigitalProvider.notifier).drawFromPile()
                    : null,
                child: Container(
                  width: 60,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.layers, color: Colors.white, size: 20),
                      Text(
                        '${state.drawPile.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                      if (!pState.hasDrawn)
                        const Text(
                          'Ziehen',
                          style: TextStyle(color: Colors.white70, fontSize: 8),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Discard pile
              GestureDetector(
                onTap: !pState.hasDrawn && topDiscard != null
                    ? () => ref
                          .read(rommeDigitalProvider.notifier)
                          .drawFromDiscard()
                    : null,
                child: Container(
                  width: 60,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !pState.hasDrawn ? Colors.green : Colors.grey,
                      width: !pState.hasDrawn ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: topDiscard != null
                        ? Text(
                            topDiscard.shortLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _cardColor(topDiscard),
                            ),
                          )
                        : const Text(
                            'Leer',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Action bar (meld selected / discard)
        if (pState.hasDrawn)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (_selectedCardIds.length >= 3)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        final cards = pState.hand
                            .where((c) => _selectedCardIds.contains(c.id))
                            .toList();
                        ref
                            .read(rommeDigitalProvider.notifier)
                            .meldCards(cards);
                        setState(() => _selectedCardIds.clear());
                      },
                      icon: const Icon(Icons.check),
                      label: Text('Auslegen (${_selectedCardIds.length})'),
                    ),
                  ),
                if (_selectedCardIds.length >= 3) const SizedBox(width: 8),
                if (_selectedCardIds.length == 1)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final card = pState.hand.firstWhere(
                          (c) => _selectedCardIds.contains(c.id),
                        );
                        ref
                            .read(rommeDigitalProvider.notifier)
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16),
                SizedBox(width: 8),
                Text('Ziehe zuerst eine Karte!'),
              ],
            ),
          ),
        // Melds
        if (pState.melds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auslagen:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: pState.melds.map((meld) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        meld.cards.map((c) => c.shortLabel).join(' '),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        // Player hand
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_selectedCardIds.isNotEmpty)
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _selectedCardIds.clear()),
                        icon: const Icon(Icons.close_rounded, size: 14),
                        label: const Text(
                          'Auswahl aufheben',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
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
                            width: 46,
                            height: 66,
                            transform: isSelected
                                ? Matrix4.translationValues(0.0, -8.0, 0.0)
                                : Matrix4.identity(),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue
                                    : _cardColor(card).withValues(alpha: 0.3),
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? Colors.blue.withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.1),
                                  blurRadius: isSelected ? 6 : 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                card.shortLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _cardColor(card),
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
    RommeDigitalState state,
    List players,
  ) {
    final sorted = List<String>.from(state.playerOrder)
      ..sort(
        (a, b) =>
            (state.totalScores[a] ?? 0).compareTo(state.totalScores[b] ?? 0),
      );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
          const SizedBox(height: 16),
          Text(
            'Runde vorbei!',
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
                final score = state.totalScores[pid] ?? 0;
                return Card(
                  color: index == 0
                      ? Colors.green.withValues(alpha: 0.1)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index == 0 ? Colors.green : Colors.grey,
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
                    subtitle: Text(score == 0 ? 'Gewonnen!' : 'Strafpunkte'),
                    trailing: Text(
                      '$score',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: score == 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(rommeDigitalProvider.notifier).nextRound(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Nächste Runde'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }

  Color _cardColor(RommeCard card) {
    if (card.isJoker) return Colors.purple;
    return (card.suit == 2 || card.suit == 3) ? Colors.red : Colors.black87;
  }
}
