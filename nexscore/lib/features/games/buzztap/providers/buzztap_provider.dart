import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/models/drink_intensity.dart';
import '../models/buzztap_models.dart';

class BuzzTapStateNotifier extends Notifier<BuzzTapGameState> {
  final List<BuzzTapGameState> _history = [];

  @override
  BuzzTapGameState build() => const BuzzTapGameState();

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

  void toggleCategory(BuzzTapCategory cat) {
    _pushState();
    final cats = List<BuzzTapCategory>.from(state.selectedCategories);
    if (cats.contains(cat)) {
      if (cats.length > 1) cats.remove(cat);
    } else {
      cats.add(cat);
    }
    state = state.copyWith(selectedCategories: cats);
  }

  void drawNextCard(List<Player> activePlayers, AppLocalizations l10n) {
    _pushState();
    var available = getBuzzTapDatabase(
      l10n,
    ).where((c) => state.selectedCategories.contains(c.category)).toList();

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
    final List<String> targetIds = [];
    BuzzTapTargetType targetType = BuzzTapTargetType.manual;

    if (activePlayers.isNotEmpty) {
      final p1Index = random.nextInt(activePlayers.length);
      final p1 = activePlayers[p1Index];
      hydratedText = hydratedText.replaceAll('{0}', p1.name);

      if (hydratedText.contains('{1}')) {
        if (activePlayers.length > 1) {
          int p2Index = random.nextInt(activePlayers.length);
          while (p2Index == p1Index) {
            p2Index = random.nextInt(activePlayers.length);
          }
          final p2 = activePlayers[p2Index];
          hydratedText = hydratedText.replaceAll('{1}', p2.name);
          targetIds.addAll([p1.id, p2.id]);
          targetType = BuzzTapTargetType.dual;
        } else {
          targetIds.add(p1.id);
          targetType = BuzzTapTargetType.single;
        }
      } else {
        targetIds.add(p1.id);
        targetType = BuzzTapTargetType.single;
      }
    }

    // Detect "Everyone" tasks
    if (baseText.toLowerCase().contains('everyone') ||
        baseText.toLowerCase().contains('last place') ||
        baseText.toLowerCase().contains('cheers')) {
      targetIds.clear();
      targetIds.addAll(activePlayers.map((p) => p.id));
      targetType = BuzzTapTargetType.everyone;
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

    final hydratedCard = BuzzTapCard(
      id: card.id,
      text: hydratedText,
      emoji: card.emoji,
      explanation: card.explanation,
      category: card.category,
      sips: finalSips,
      minPlayers: card.minPlayers,
      targetIds: targetIds,
      targetType: targetType,
    );

    state = state.copyWith(playedCards: [...state.playedCards, hydratedCard]);
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
  }

  void resetGame() {
    _pushState();
    state = state.copyWith(playedCards: [], playerSips: {});
  }

  void toggle2PlayerOptimization(bool value) {
    _pushState();
    state = state.copyWith(optimizeForTwoPlayers: value);
  }

  void toggleIntensity(DrinkIntensity intensity) {
    _pushState();
    state = state.copyWith(intensity: intensity);
  }

  void setCustomIntensity(double multiplier) {
    _pushState();
    state = state.copyWith(customIntensityMultiplier: multiplier);
  }
}

final buzzTapStateProvider =
    NotifierProvider<BuzzTapStateNotifier, BuzzTapGameState>(
      BuzzTapStateNotifier.new,
    );
