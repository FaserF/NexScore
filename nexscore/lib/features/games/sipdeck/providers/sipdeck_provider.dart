import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sipdeck_models.dart';
import '../../../../core/models/player_model.dart';

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

  void drawNextCard(List<Player> activePlayers) {
    final available = sipDeckDatabase
        .where((c) => state.selectedCategories.contains(c.category))
        .toList();
    if (available.isEmpty) return;

    final random = Random();
    final card = available[random.nextInt(available.length)];

    String hydratedText = card.text;
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

    final hydratedCard = SipDeckCard(
      id: card.id,
      text: hydratedText,
      category: card.category,
      sips: card.sips,
      isVirus: card.isVirus,
    );

    state = state.copyWith(playedCards: [...state.playedCards, hydratedCard]);
  }
}

final sipDeckStateProvider =
    NotifierProvider<SipDeckStateNotifier, SipDeckGameState>(
      SipDeckStateNotifier.new,
    );
