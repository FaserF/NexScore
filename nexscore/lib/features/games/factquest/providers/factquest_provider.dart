import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/factquest_models.dart';
import '../models/factquest_database.dart';
import '../../../../core/i18n/app_localizations.dart';

class FactQuestStateNotifier extends Notifier<FactQuestGameState> {
  final List<FactQuestGameState> _history = [];

  @override
  FactQuestGameState build() => const FactQuestGameState();

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

  void toggleCategory(FactQuestCategory cat) {
    _pushState();
    final cats = List<FactQuestCategory>.from(state.selectedCategories);
    if (cats.contains(cat)) {
      if (cats.length > 1) cats.remove(cat);
    } else {
      cats.add(cat);
    }
    state = state.copyWith(selectedCategories: cats);
  }

  void drawNextCard(AppLocalizations l10n) {
    _pushState();
    final available = factQuestDatabase.where((c) {
      return state.selectedCategories.contains(c.category);
    }).toList();

    if (available.isEmpty) return;

    final random = Random();
    final playedIds = state.playedCards.map((c) => c.id).toSet();
    final fresh = available.where((c) => !playedIds.contains(c.id)).toList();

    final pool = fresh.isNotEmpty ? fresh : available;
    final card = pool[random.nextInt(pool.length)];

    // Resolve localized text – fall back to raw key if not found
    String localizedText = l10n.get(card.textKey);
    if (localizedText == card.textKey) {
      localizedText = card.text;
    }
    String localizedExpl = l10n.get(card.explanationKey);
    if (localizedExpl == card.explanationKey) {
      localizedExpl = card.explanation;
    }

    final hydratedCard = FactQuestCard(
      id: card.id,
      text: localizedText,
      explanation: localizedExpl,
      sourceUrl: card.sourceUrl,
      emoji: card.emoji,
      category: card.category,
    );

    state = state.copyWith(playedCards: [...state.playedCards, hydratedCard]);
  }

  void resetGame() {
    _pushState();
    state = state.copyWith(playedCards: []);
  }

  void initPlayers(List<String> playerIds) {
    _pushState();
    state = state.copyWith(activePlayerIds: playerIds);
  }
}

final factQuestStateProvider =
    NotifierProvider<FactQuestStateNotifier, FactQuestGameState>(
      FactQuestStateNotifier.new,
    );
