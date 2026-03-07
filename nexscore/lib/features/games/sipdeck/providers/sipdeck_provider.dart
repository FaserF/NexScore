import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/models/drink_intensity.dart';
import '../models/sipdeck_models.dart';

class SipDeckStateNotifier extends Notifier<SipDeckGameState> {
  final List<SipDeckGameState> _history = [];

  @override
  SipDeckGameState build() => const SipDeckGameState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 20) _history.removeAt(0);
  }

  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
    }
  }

  void toggleCategory(SipDeckCategory cat) {
    _pushState();
    final cats = List<SipDeckCategory>.from(state.selectedCategories);
    if (cats.contains(cat)) {
      if (cats.length > 1) cats.remove(cat);
    } else {
      cats.add(cat);
    }
    state = state.copyWith(selectedCategories: cats);
  }

  void toggleTag(SipDeckTaskTag tag) {
    _pushState();
    final tags = Set<SipDeckTaskTag>.from(state.disabledTags);
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    state = state.copyWith(disabledTags: tags);
  }

  void toggleFilterMultiplayerOnly(bool value) {
    _pushState();
    state = state.copyWith(filterMultiplayerOnly: value);
  }

  void toggleIntensity(DrinkIntensity intensity) {
    _pushState();
    state = state.copyWith(intensity: intensity);
  }

  void setCustomIntensity(double multiplier) {
    _pushState();
    state = state.copyWith(customIntensityMultiplier: multiplier);
  }

  void toggleHydrationCards(bool value) {
    _pushState();
    state = state.copyWith(enableHydrationCards: value);
  }

  void drawNextCard(List<Player> activePlayers, AppLocalizations l10n) {
    _pushState();
    final available = getSipDeckDatabase(l10n).where((c) {
      final isCategorySelected = state.selectedCategories.contains(c.category);
      if (!isCategorySelected) return false;

      // Apply 2-player optimization filter
      if (state.filterMultiplayerOnly && activePlayers.length <= 2) {
        if (c.minPlayers > 2) return false;
      }

      // Apply granular tag filters
      for (final tag in c.tags) {
        if (state.disabledTags.contains(tag)) return false;
      }

      return true;
    }).toList();

    if (available.isEmpty) return;

    final random = Random();

    // --- Hydration Card Logic ---
    if (state.enableHydrationCards && state.playedCards.isNotEmpty) {
      // Scale frequency based on intensity
      double baseProbability = 0.08; // Normal (~1 in 12.5 cards)
      if (state.intensity == DrinkIntensity.chill) {
        baseProbability = 0.05; // ~1 in 20
      } else if (state.intensity == DrinkIntensity.extreme) {
        baseProbability = 0.15; // ~1 in 6.7
      } else if (state.intensity == DrinkIntensity.custom) {
        baseProbability = 0.08 * state.customIntensityMultiplier;
      }

      // Ensure we don't have hydration cards back-to-back
      final lastCardWasHydration = state.playedCards.last.id == 'hydration';

      if (!lastCardWasHydration && random.nextDouble() < baseProbability) {
        final hydrationCard = SipDeckCard(
          id: 'hydration',
          text: l10n.get('sipdeck_hydration_card_text'),
          emoji: '💧',
          category: SipDeckCategory.warmUp,
          sips: 0,
          targetType: SipTargetType.everyone,
          targetIds: activePlayers.map((p) => p.id).toList(),
        );
        state = state.copyWith(
          playedCards: [...state.playedCards, hydrationCard],
        );
        return;
      }
    }
    // ----------------------------

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

    // Apply Drink Intensity
    final initialSips = card.sips;
    final finalSips = state.intensity.calculateSips(
      initialSips,
      customMultiplier: state.customIntensityMultiplier,
    );

    // If the intensity altered the sips string, append an explicit hint
    if (finalSips != initialSips && initialSips > 0) {
      String intensityName;
      if (state.intensity == DrinkIntensity.custom) {
        intensityName = l10n.getWith('drink_intensity_custom_slider', [
          state.customIntensityMultiplier.toStringAsFixed(1),
        ]);
      } else {
        intensityName = state.intensity == DrinkIntensity.chill
            ? l10n.get('drink_intensity_chill')
            : l10n.get('drink_intensity_extreme');
      }
      final modeStrKey = finalSips == 1
          ? 'mode_sips_adjusted_1'
          : 'mode_sips_adjusted';
      final modeStr = l10n
          .get(modeStrKey)
          .replaceAll('{0}', intensityName)
          .replaceAll('{1}', finalSips.toString());
      hydratedText += '\n\n$modeStr';
    }

    final hydratedCard = SipDeckCard(
      id: card.id,
      text: hydratedText,
      explanation: hydratedExpl.isNotEmpty ? hydratedExpl : null,
      emoji: card.emoji,
      category: card.category,
      sips: finalSips,
      isVirus: card.isVirus,
      targetIds: targetIds,
      targetType: targetType,
    );

    List<SipDeckCard> activeViruses = List.from(state.activeViruses);
    if (hydratedCard.isVirus) {
      activeViruses.add(hydratedCard);
    }

    // Special case: Virus Cured card
    if (hydratedCard.id == 'wc009') {
      activeViruses.clear();
    }

    state = state.copyWith(
      playedCards: [...state.playedCards, hydratedCard],
      activeViruses: activeViruses,
    );
  }

  void incrementSips(String playerId, int amount) {
    _pushState();
    final sips = Map<String, int>.from(state.playerSips);
    sips[playerId] = (sips[playerId] ?? 0) + amount;
    state = state.copyWith(playerSips: sips);
  }

  void decrementSips(String playerId, int amount) {
    _pushState();
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
    _pushState();
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
    _pushState();
    state = state.copyWith(playedCards: [], playerSips: {});
  }
}

final sipDeckStateProvider =
    NotifierProvider<SipDeckStateNotifier, SipDeckGameState>(
      SipDeckStateNotifier.new,
    );
