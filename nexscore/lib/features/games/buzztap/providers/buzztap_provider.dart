import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/buzztap_models.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';

class BuzzTapStateNotifier extends Notifier<BuzzTapGameState> {
  @override
  BuzzTapGameState build() => const BuzzTapGameState();

  void toggleCategory(BuzzTapCategory cat) {
    final cats = List<BuzzTapCategory>.from(state.selectedCategories);
    if (cats.contains(cat)) {
      if (cats.length > 1) cats.remove(cat);
    } else {
      cats.add(cat);
    }
    state = state.copyWith(selectedCategories: cats);
  }

  void drawNextCard(List<Player> activePlayers, AppLocalizations l10n) {
    var available = buzzTapDatabase
        .where((c) => state.selectedCategories.contains(c.category))
        .toList();

    if (state.optimizeForTwoPlayers) {
      available = available.where((c) => c.minPlayers <= 2).toList();
    }

    if (available.isEmpty) return;

    final random = Random();
    final card = available[random.nextInt(available.length)];

    // BuzzTap uses the same hydration logic as SipDeck for now
    String baseText = l10n.get(card.key);
    if (baseText == card.key) {
      baseText = card.text;
    }

    String hydratedText = baseText;

    if (activePlayers.isNotEmpty) {
      final p1 = activePlayers[random.nextInt(activePlayers.length)].name;
      hydratedText = hydratedText.replaceAll('{0}', p1);

      if (activePlayers.length > 1) {
        String p2 = activePlayers[random.nextInt(activePlayers.length)].name;
        while (p2 == p1) {
          p2 = activePlayers[random.nextInt(activePlayers.length)].name;
        }
        hydratedText = hydratedText.replaceAll('{1}', p2);
      }
    }

    final hydratedCard = BuzzTapCard(
      id: card.id,
      text: hydratedText,
      emoji: card.emoji,
      explanation: card.explanation,
      category: card.category,
      sips: card.sips,
      minPlayers: card.minPlayers,
    );

    state = state.copyWith(playedCards: [...state.playedCards, hydratedCard]);
  }

  void incrementSips(String playerId, int amount) {
    final sips = Map<String, int>.from(state.playerSips);
    sips[playerId] = (sips[playerId] ?? 0) + amount;
    state = state.copyWith(playerSips: sips);
  }

  void decrementSips(String playerId, int amount) {
    final sips = Map<String, int>.from(state.playerSips);
    final current = sips[playerId] ?? 0;
    if (current >= amount) {
      sips[playerId] = current - amount;
    } else {
      sips[playerId] = 0;
    }
    state = state.copyWith(playerSips: sips);
  }

  void resetGame() {
    state = state.copyWith(playedCards: [], playerSips: {});
  }

  void toggle2PlayerOptimization(bool value) {
    state = state.copyWith(optimizeForTwoPlayers: value);
  }
}

final buzzTapStateProvider =
    NotifierProvider<BuzzTapStateNotifier, BuzzTapGameState>(
      BuzzTapStateNotifier.new,
    );
