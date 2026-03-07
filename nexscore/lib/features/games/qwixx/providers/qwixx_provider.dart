import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qwixx_models.dart';

class QwixxStateNotifier extends Notifier<QwixxGameState> {
  final List<QwixxGameState> _history = [];

  @override
  QwixxGameState build() => const QwixxGameState();

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
    if (state.sheets.isNotEmpty) return;
    _pushState();
    final sheets = {for (var id in playerIds) id: const QwixxPlayerSheet()};
    state = QwixxGameState(sheets: sheets);
  }

  void setVariant(QwixxVariant variant) {
    _pushState();
    state = state.copyWith(
      variant: variant,
      sheets: {},
    ); // Reset on variant change
  }

  void updateSheet(String playerId, QwixxPlayerSheet newSheet) {
    _pushState();
    final updated = Map<String, QwixxPlayerSheet>.from(state.sheets);
    updated[playerId] = newSheet;
    state = state.copyWith(sheets: updated);
  }

  void resetGame() {
    _pushState();
    state = state.copyWith(sheets: {});
  }
}

final qwixxStateProvider = NotifierProvider<QwixxStateNotifier, QwixxGameState>(
  QwixxStateNotifier.new,
);
