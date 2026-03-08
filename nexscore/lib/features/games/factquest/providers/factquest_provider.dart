import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/factquest_models.dart';
import '../models/factquest_database.dart';

export '../models/factquest_models.dart';

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

  void initPlayers(List<String> playerIds) {
    _pushState();
    state = state.copyWith(activePlayerIds: playerIds);
  }

  void toggleCategory(FactQuestCategory category) {
    _pushState();
    final newCategories = List<FactQuestCategory>.from(
      state.selectedCategories,
    );
    if (newCategories.contains(category)) {
      if (newCategories.length > 1) {
        newCategories.remove(category);
      }
    } else {
      newCategories.add(category);
    }
    state = state.copyWith(selectedCategories: newCategories);
  }

  void drawNextCard() {
    _pushState();
    final available = factQuestDatabase.where((card) {
      return state.selectedCategories.contains(card.category);
    }).toList();

    if (available.isEmpty) return;

    final random = Random();
    final card = available[random.nextInt(available.length)];

    state = state.copyWith(playedCards: [...state.playedCards, card]);
  }

  void resetGame() {
    _pushState();
    state = const FactQuestGameState();
  }

  void updateFromSync(FactQuestGameState newState) {
    if (state != newState) state = newState;
  }
}

final factQuestStateProvider =
    NotifierProvider<FactQuestStateNotifier, FactQuestGameState>(
      FactQuestStateNotifier.new,
    );
