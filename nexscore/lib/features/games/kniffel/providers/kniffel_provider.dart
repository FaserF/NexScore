import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kniffel_models.dart';

class KniffelStateNotifier extends Notifier<Map<String, YahtzeePlayerSheet>> {
  @override
  Map<String, YahtzeePlayerSheet> build() => {};

  void initPlayers(List<String> playerIds) {
    state = {for (final id in playerIds) id: const YahtzeePlayerSheet()};
  }

  void updateScore(String playerId, YahtzeeCategory category, int value) {
    final updatedMap = Map<String, YahtzeePlayerSheet>.from(state);
    final sheet = updatedMap[playerId] ?? const YahtzeePlayerSheet();
    final newScores = Map<YahtzeeCategory, int>.from(sheet.scores);
    newScores[category] = value;
    updatedMap[playerId] = sheet.copyWith(scores: newScores);
    state = updatedMap;
  }
}

final kniffelStateProvider =
    NotifierProvider<KniffelStateNotifier, Map<String, YahtzeePlayerSheet>>(
      KniffelStateNotifier.new,
    );
