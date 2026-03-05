import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qwixx_models.dart';

class QwixxStateNotifier extends Notifier<QwixxGameState> {
  @override
  QwixxGameState build() => const QwixxGameState();

  void initPlayers(List<String> playerIds) {
    if (state.sheets.isNotEmpty) return;
    final sheets = {for (var id in playerIds) id: const QwixxPlayerSheet()};
    state = QwixxGameState(sheets: sheets);
  }

  void updateSheet(String playerId, QwixxPlayerSheet newSheet) {
    final updated = Map<String, QwixxPlayerSheet>.from(state.sheets);
    updated[playerId] = newSheet;
    state = QwixxGameState(sheets: updated);
  }
}

final qwixxStateProvider = NotifierProvider<QwixxStateNotifier, QwixxGameState>(
  QwixxStateNotifier.new,
);
