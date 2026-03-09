import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wayquest_models.dart';
import '../models/wayquest_database.dart';
import '../../../../core/models/player_model.dart';
import '../../../../core/i18n/app_localizations.dart';

class WayQuestStateNotifier extends Notifier<WayQuestGameState> {
  final List<WayQuestGameState> _history = [];

  @override
  WayQuestGameState build() => const WayQuestGameState();

  void _pushState() {
    _history.add(state);
    if (_history.length > 20) _history.removeAt(0);
  }

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void toggleCategory(WayQuestCategory cat) {
    _pushState();
    final cats = List<WayQuestCategory>.from(state.selectedCategories);
    if (cats.contains(cat)) {
      if (cats.length > 1) cats.remove(cat);
    } else {
      cats.add(cat);
    }
    state = state.copyWith(
      selectedCategories: cats,
      canUndo: _history.isNotEmpty,
    );
  }

  void drawNextCard(List<Player> activePlayers, AppLocalizations l10n) {
    _pushState();
    final available = wayQuestDatabase.where((c) {
      final isCategorySelected = state.selectedCategories.contains(c.category);
      if (!isCategorySelected) return false;
      return activePlayers.length >= c.minPlayers;
    }).toList();

    if (available.isEmpty) return;

    final random = Random();
    // Simple logic: filter out cards that were just played if possible,
    // otherwise just pick a random one.
    final playedIds = state.playedCards.map((c) => c.id).toSet();
    final fresh = available.where((c) => !playedIds.contains(c.id)).toList();

    final pool = fresh.isNotEmpty ? fresh : available;
    final card = pool[random.nextInt(pool.length)];

    // Use localization key if available, otherwise fallback to original text
    String baseText = l10n.get(card.key);
    if (baseText == card.key) {
      baseText = card.text;
    }

    String hydratedText = baseText;
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
        }
      }
    }

    final hydratedCard = WayQuestCard(
      id: card.id,
      text: hydratedText,
      emoji: card.emoji,
      category: card.category,
      minPlayers: card.minPlayers,
    );

    state = state.copyWith(
      playedCards: [...state.playedCards, hydratedCard],
      canUndo: _history.isNotEmpty,
      startedAt: state.startedAt ?? DateTime.now(),
    );
  }

  void resetGame() {
    _history.clear();
    state = const WayQuestGameState();
  }

  void finishGame() {
    _pushState();
    state = state.copyWith(
      endedAt: DateTime.now(),
      canUndo: _history.isNotEmpty,
    );
  }

  void initPlayers(List<String> playerIds) {
    _pushState();
    state = state.copyWith(
      activePlayerIds: playerIds,
      canUndo: _history.isNotEmpty,
    );
  }
}

final wayQuestStateProvider =
    NotifierProvider<WayQuestStateNotifier, WayQuestGameState>(
      WayQuestStateNotifier.new,
    );
