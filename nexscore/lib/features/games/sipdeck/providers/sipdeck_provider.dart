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
    final List<String> targetIds = [];
    SipTargetType targetType = SipTargetType.manual;

    if (activePlayers.isNotEmpty) {
      final p1Index = random.nextInt(activePlayers.length);
      final p1 = activePlayers[p1Index];
      hydratedText = hydratedText.replaceAll('{0}', p1.name);
      hydratedExpl = hydratedExpl.replaceAll('{0}', p1.name);

      if (hydratedText.contains('{1}') || hydratedExpl.contains('{1}')) {
        if (activePlayers.length > 1) {
          int p2Index = random.nextInt(activePlayers.length);
          while (p2Index == p1Index) {
            p2Index = random.nextInt(activePlayers.length);
          }
          final p2 = activePlayers[p2Index];
          hydratedText = hydratedText.replaceAll('{1}', p2.name);
          hydratedExpl = hydratedExpl.replaceAll('{1}', p2.name);
          targetIds.addAll([p1.id, p2.id]);
          targetType = SipTargetType.dual;
        } else {
          // Fallback if {1} is requested but only 1 player available
          targetIds.add(p1.id);
          targetType = SipTargetType.single;
        }
      } else {
        targetIds.add(p1.id);
        targetType = SipTargetType.single;
      }
    }

    // Detect "Everyone" tasks
    if (baseText.toLowerCase().contains('everyone') ||
        baseText.toLowerCase().contains('last place') ||
        baseText.toLowerCase().contains('group vote') ||
        baseText.toLowerCase().contains('group challenge')) {
      targetIds.clear();
      targetIds.addAll(activePlayers.map((p) => p.id));
      targetType = SipTargetType.everyone;
    }

    final hydratedCard = SipDeckCard(
      id: card.id,
      text: hydratedText,
      explanation: hydratedExpl.isNotEmpty ? hydratedExpl : null,
      emoji: card.emoji,
      category: card.category,
      sips: card.sips,
      isVirus: card.isVirus,
      targetIds: targetIds,
      targetType: targetType,
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

  void completeCard(bool skipped) {
    if (state.currentCard == null) return;

    final card = state.currentCard!;
    if (!skipped && card.sips > 0) {
      final sips = Map<String, int>.from(state.playerSips);
      for (final pid in card.targetIds) {
        sips[pid] = (sips[pid] ?? 0) + card.sips;
      }
      state = state.copyWith(playerSips: sips);
    }
    // We don't advance the card automatically here as the UI handles the "Tap to continue" or "Next"
    // But we might want to flag it as "resolved" if sips are handled.
    // For now, let's just update the sips. The UI will call drawNextCard to continue.
  }

  void resetGame() {
    state = state.copyWith(playedCards: [], playerSips: {});
  }
}

final sipDeckStateProvider =
    NotifierProvider<SipDeckStateNotifier, SipDeckGameState>(
      SipDeckStateNotifier.new,
    );
