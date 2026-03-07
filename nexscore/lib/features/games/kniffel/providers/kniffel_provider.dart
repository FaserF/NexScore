import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kniffel_models.dart';

class KniffelStateNotifier extends Notifier<KniffelGameState> {
  final List<KniffelGameState> _history = [];

  @override
  KniffelGameState build() => const KniffelGameState();

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
    state = KniffelGameState(
      playerSheets: {
        for (final id in playerIds) id: const YahtzeePlayerSheet(),
      },
    );
  }

  void updateScore(String playerId, YahtzeeCategory category, int value) {
    _pushState();
    final updatedMap = Map<String, YahtzeePlayerSheet>.from(state.playerSheets);
    final sheet = updatedMap[playerId] ?? const YahtzeePlayerSheet();
    final newScores = Map<YahtzeeCategory, int>.from(sheet.scores);
    newScores[category] = value;
    updatedMap[playerId] = sheet.copyWith(scores: newScores);
    state = state.copyWith(playerSheets: updatedMap);
  }

  void updateBonus(String playerId, int value) {
    _pushState();
    final updatedMap = Map<String, YahtzeePlayerSheet>.from(state.playerSheets);
    final sheet = updatedMap[playerId] ?? const YahtzeePlayerSheet();
    updatedMap[playerId] = sheet.copyWith(bonusYahtzees: value);
    state = state.copyWith(playerSheets: updatedMap);
  }

  void resetGame() {
    _pushState();
    state = const KniffelGameState();
  }
}

final kniffelStateProvider =
    NotifierProvider<KniffelStateNotifier, KniffelGameState>(
      KniffelStateNotifier.new,
    );
