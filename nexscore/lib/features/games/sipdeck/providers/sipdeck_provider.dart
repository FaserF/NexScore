import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sipdeck_models.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';

class SipDeckStateNotifier extends Notifier<SipDeckGameState> {
  @override
  SipDeckGameState build() => const SipDeckGameState();

  void toggleCategory(SipDeckCategory cat) {
    final cats = List<SipDeckCategory>.from(state.selectedCategories);
    if (cats.contains(cat)) {
      if (cats.length > 1) cats.remove(cat);
    } else {
      cats.add(cat);
    }
    state = state.copyWith(selectedCategories: cats);
  }

  void toggleFilterMultiplayerOnly(bool value) {
    state = state.copyWith(filterMultiplayerOnly: value);
  }

  void drawNextCard(List<Player> activePlayers, AppLocalizations l10n) {
    final available = sipDeckDatabase.where((c) {
      final isCategorySelected = state.selectedCategories.contains(c.category);
      if (!isCategorySelected) return false;

      // Apply 2-player optimization filter
      if (state.filterMultiplayerOnly && activePlayers.length <= 2) {
        return c.minPlayers <= 2;
      }

      return true;
    }).toList();

    if (available.isEmpty) return;

    final random = Random();
    final card = available[random.nextInt(available.length)];

    // Use localization key if available, otherwise fallback to original text
    String baseText = l10n.get(card.key);
    if (baseText == card.key) {
      baseText = card.text;
    }

    String baseExpl = l10n.get(card.explanationKey);
    if (baseExpl == card.explanationKey) {
      baseExpl = card.explanation ?? '';
    }

    String hydratedText = baseText;
    String hydratedExpl = baseExpl;

    if (activePlayers.isNotEmpty) {
      final p1 = activePlayers[random.nextInt(activePlayers.length)].name;
      hydratedText = hydratedText.replaceAll('{0}', p1);
      hydratedExpl = hydratedExpl.replaceAll('{0}', p1);

      if (activePlayers.length > 1) {
        String p2 = activePlayers[random.nextInt(activePlayers.length)].name;
        while (p2 == p1) {
          p2 = activePlayers[random.nextInt(activePlayers.length)].name;
        }
        hydratedText = hydratedText.replaceAll('{1}', p2);
        hydratedExpl = hydratedExpl.replaceAll('{1}', p2);
      }
    }

    final hydratedCard = SipDeckCard(
      id: card.id,
      text: hydratedText,
      explanation: hydratedExpl.isNotEmpty ? hydratedExpl : null,
      emoji: card.emoji, // Primary emoji stays from DB or could be in l10n too
      category: card.category,
      sips: card.sips,
      isVirus: card.isVirus,
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
}

final sipDeckStateProvider =
    NotifierProvider<SipDeckStateNotifier, SipDeckGameState>(
      SipDeckStateNotifier.new,
    );
