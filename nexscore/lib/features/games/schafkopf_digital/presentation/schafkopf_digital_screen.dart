import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/multiplayer/widgets/multiplayer_client_overlay.dart';
import '../models/bavarian_card_models.dart';
import '../models/schafkopf_digital_state.dart';
import '../providers/schafkopf_digital_provider.dart';

class SchafkopfDigitalScreen extends ConsumerWidget {
  const SchafkopfDigitalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schafkopfDigitalProvider);
    final players = ref.watch(activePlayersProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Digital ${l10n.get("game_schafkopf")}'),
        leading: BackButton(onPressed: () => context.go('/games')),
        actions: [
          if (state.phase != SchafkopfDigitalPhase.setup)
            IconButton(
              icon: const Icon(Icons.scoreboard_outlined),
              onPressed: () => _showScoreboard(context, state, players),
            ),
        ],
      ),
      body: MultiplayerClientOverlay(
        child: _buildPhaseContent(context, ref, state, players, l10n),
      ),
    );
  }

  Widget _buildPhaseContent(
    BuildContext context,
    WidgetRef ref,
    SchafkopfDigitalState state,
    List players,
    AppLocalizations l10n,
  ) {
    switch (state.phase) {
      case SchafkopfDigitalPhase.setup:
        return _buildSetup(context, ref, players);
      case SchafkopfDigitalPhase.gameSelect:
        return _buildGameSelect(context, ref, state, players, l10n);
      case SchafkopfDigitalPhase.playing:
        return _buildPlaying(context, ref, state, players);
      case SchafkopfDigitalPhase.scoring:
        return _buildScoring(context, ref, state, players, l10n);
      case SchafkopfDigitalPhase.finished:
        return _buildScoring(context, ref, state, players, l10n);
    }
  }

  Widget _buildSetup(BuildContext context, WidgetRef ref, List players) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.style, size: 80, color: Colors.brown),
            const SizedBox(height: 24),
            Text(
              'Digital Schafkopf',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bayerisches Kartenspiel — Sauspiel, Solo & Wenz',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Text(
              '${players.length} Spieler bereit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: players.length == 4
                  ? () => ref
                        .read(schafkopfDigitalProvider.notifier)
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
            if (players.length != 4) ...[
              const SizedBox(height: 16),
              const Text(
                'Genau 4 Spieler benötigt',
                style: TextStyle(color: Colors.orange),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameSelect(
    BuildContext context,
    WidgetRef ref,
    SchafkopfDigitalState state,
    List players,
    AppLocalizations l10n,
  ) {
    final currentPlayer = players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => players.first,
    );
    final hand = state.hands[state.currentPlayerId] ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${currentPlayer.name} — Spiel wählen oder weiter',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Show hand
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deine Karten:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: hand.map((c) => _BavarianCardChip(card: c)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Game type selection
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              const Text(
                'Spiel ansagen:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              // Sauspiel options — can call any Ace suit you don't hold yourself
              ...BavarianSuit.values
                  .where(
                    (s) => s != BavarianSuit.herz,
                  ) // Can't call Herz in Sauspiel
                  .where(
                    (s) => !hand.any(
                      (c) => c.suit == s && c.rank == BavarianRank.ass,
                    ),
                  )
                  .map(
                    (suit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FilledButton.tonal(
                        onPressed: () => ref
                            .read(schafkopfDigitalProvider.notifier)
                            .selectGame(
                              state.currentPlayerId!,
                              SchafkopfDigitalGameType.sauspiel,
                              calledSuit: suit,
                            ),
                        child: Text('Sauspiel auf ${_suitName(suit)}'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => ref
                    .read(schafkopfDigitalProvider.notifier)
                    .selectGame(
                      state.currentPlayerId!,
                      SchafkopfDigitalGameType.wenz,
                    ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Wenz'),
              ),
              const SizedBox(height: 8),
              ...BavarianSuit.values.map(
                (suit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    onPressed: () {
                      final soloType = switch (suit) {
                        BavarianSuit.herz => SchafkopfDigitalGameType.soloHerz,
                        BavarianSuit.eichel =>
                          SchafkopfDigitalGameType.soloEichel,
                        BavarianSuit.gras => SchafkopfDigitalGameType.soloGras,
                        BavarianSuit.schellen =>
                          SchafkopfDigitalGameType.soloSchellen,
                      };
                      ref
                          .read(schafkopfDigitalProvider.notifier)
                          .selectGame(state.currentPlayerId!, soloType);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text('Solo ${_suitName(suit)}'),
                  ),
                ),
              ),
              const Divider(height: 32),
              OutlinedButton.icon(
                onPressed: () => ref
                    .read(schafkopfDigitalProvider.notifier)
                    .selectGame(state.currentPlayerId!, null),
                icon: const Icon(Icons.skip_next),
                label: const Text('Weiter (ich spiel nicht)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaying(
    BuildContext context,
    WidgetRef ref,
    SchafkopfDigitalState state,
    List players,
  ) {
    final currentPlayer = players.firstWhere(
      (p) => p.id == state.currentPlayerId,
      orElse: () => players.first,
    );
    final hand = state.hands[state.currentPlayerId] ?? [];

    final gameLabel = switch (state.gameType!) {
      SchafkopfDigitalGameType.sauspiel =>
        'Sauspiel auf ${_suitName(state.calledSuit!)}',
      SchafkopfDigitalGameType.wenz => 'Wenz',
      SchafkopfDigitalGameType.soloHerz => 'Solo Herz',
      SchafkopfDigitalGameType.soloEichel => 'Solo Eichel',
      SchafkopfDigitalGameType.soloGras => 'Solo Gras',
      SchafkopfDigitalGameType.soloSchellen => 'Solo Schellen',
    };

    return Column(
      children: [
        // Game info header
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                gameLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Stich ${state.completedTricks.length + 1}/8',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Trick area
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: state.playerOrder.map((pid) {
              final card = state.currentTrick.playedCards[pid];
              final player = players.firstWhere(
                (p) => p.id == pid,
                orElse: () => players.first,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: pid == state.currentPlayerId
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    card != null
                        ? _BavarianCardChip(card: card, large: true)
                        : Container(
                            width: 50,
                            height: 70,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: pid == state.currentPlayerId
                                ? const Center(
                                    child: Icon(
                                      Icons.hourglass_top,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  )
                                : null,
                          ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.pointsWon[pid] ?? 0} Pkt',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        // Current player info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${currentPlayer.name} ist dran',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Stiche: ${state.tricksWon[state.currentPlayerId] ?? 0}'),
            ],
          ),
        ),
        // Player's hand
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Deine Karten:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: hand.map((card) {
                        final isValid = ref
                            .read(schafkopfDigitalProvider.notifier)
                            .isValidPlay(state.currentPlayerId!, card);
                        return GestureDetector(
                          onTap: isValid
                              ? () => ref
                                    .read(schafkopfDigitalProvider.notifier)
                                    .playCard(state.currentPlayerId!, card)
                              : null,
                          child: AnimatedOpacity(
                            opacity: isValid ? 1.0 : 0.4,
                            duration: const Duration(milliseconds: 200),
                            child: _BavarianCardWidget(
                              card: card,
                              isPlayable: isValid,
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

  Widget _buildScoring(
    BuildContext context,
    WidgetRef ref,
    SchafkopfDigitalState state,
    List players,
    AppLocalizations l10n,
  ) {
    final activePlayer = players.firstWhere(
      (p) => p.id == state.activePlayerId,
      orElse: () => players.first,
    );
    final activePoints =
        (state.pointsWon[state.activePlayerId] ?? 0) +
        (state.partnerPlayerId != null
            ? (state.pointsWon[state.partnerPlayerId] ?? 0)
            : 0);
    final activeWon = activePoints >= 61;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            activeWon ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 64,
            color: activeWon ? Colors.amber : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            '${activePlayer.name} hat ${activeWon ? "gewonnen" : "verloren"}!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Punkte: $activePoints / 120',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: state.playerOrder.map((pid) {
                final player = players.firstWhere(
                  (p) => p.id == pid,
                  orElse: () => players.first,
                );
                final pts = state.pointsWon[pid] ?? 0;
                final total = state.totalScores[pid] ?? 0;
                final isActive =
                    pid == state.activePlayerId || pid == state.partnerPlayerId;
                return Card(
                  color: isActive
                      ? (activeWon
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1))
                      : null,
                  child: ListTile(
                    title: Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Kartenpunkte: $pts${isActive ? " (Spieler)" : ""}',
                    ),
                    trailing: Text(
                      '${total >= 0 ? "+" : ""}$total ct',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: total >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                ref.read(schafkopfDigitalProvider.notifier).nextRound(),
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

  void _showScoreboard(
    BuildContext context,
    SchafkopfDigitalState state,
    List players,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spielstand'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: state.playerOrder.map((pid) {
            final player = players.firstWhere(
              (p) => p.id == pid,
              orElse: () => players.first,
            );
            final total = state.totalScores[pid] ?? 0;
            return ListTile(
              title: Text(player.name),
              trailing: Text(
                '${total >= 0 ? "+" : ""}$total ct',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: total >= 0 ? Colors.green : Colors.red,
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _suitName(BavarianSuit suit) {
    return switch (suit) {
      BavarianSuit.eichel => 'Eichel',
      BavarianSuit.gras => 'Gras',
      BavarianSuit.herz => 'Herz',
      BavarianSuit.schellen => 'Schellen',
    };
  }
}

/// Compact Bavarian card chip
class _BavarianCardChip extends StatelessWidget {
  final BavarianCard card;
  final bool large;

  const _BavarianCardChip({required this.card, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = _suitColor(card.suit);
    return Container(
      width: large ? 50 : 44,
      height: large ? 70 : 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          card.shortLabel,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: large ? 13 : 10,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _suitColor(BavarianSuit suit) {
    return switch (suit) {
      BavarianSuit.eichel => Colors.brown,
      BavarianSuit.gras => Colors.green,
      BavarianSuit.herz => Colors.red,
      BavarianSuit.schellen => Colors.orange,
    };
  }
}

/// Full card widget for player hand
class _BavarianCardWidget extends StatelessWidget {
  final BavarianCard card;
  final bool isPlayable;

  const _BavarianCardWidget({required this.card, required this.isPlayable});

  @override
  Widget build(BuildContext context) {
    final color = _suitColor(card.suit);
    final icon = _suitIcon(card.suit);

    return Container(
      width: 65,
      height: 95,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.25)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPlayable ? color : Colors.grey.withValues(alpha: 0.3),
          width: isPlayable ? 2 : 1,
        ),
        boxShadow: isPlayable
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            card.shortLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
          Text(
            '${card.points}',
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Color _suitColor(BavarianSuit suit) {
    return switch (suit) {
      BavarianSuit.eichel => Colors.brown,
      BavarianSuit.gras => Colors.green,
      BavarianSuit.herz => Colors.red,
      BavarianSuit.schellen => Colors.orange,
    };
  }

  IconData _suitIcon(BavarianSuit suit) {
    return switch (suit) {
      BavarianSuit.eichel => Icons.park,
      BavarianSuit.gras => Icons.eco,
      BavarianSuit.herz => Icons.favorite,
      BavarianSuit.schellen => Icons.notifications,
    };
  }
}
