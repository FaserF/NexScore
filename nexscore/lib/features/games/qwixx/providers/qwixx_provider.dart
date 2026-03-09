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

  void undo() {
    if (_history.isNotEmpty) {
      state = _history.removeLast();
      state = state.copyWith(canUndo: _history.isNotEmpty);
    }
  }

  void initPlayers(List<String> playerIds) {
    if (state.sheets.isNotEmpty) return;
    _pushState();
    final sheets = {for (var id in playerIds) id: const QwixxPlayerSheet()};
    state = QwixxGameState(sheets: sheets, canUndo: _history.isNotEmpty);
  }

  void setVariant(QwixxVariant variant) {
    _pushState();
    state = state.copyWith(
      variant: variant,
      sheets: {},
      canUndo: _history.isNotEmpty,
    ); // Reset on variant change
  }

  void updateSheet(String playerId, QwixxPlayerSheet newSheet) {
    _pushState();
    final updated = Map<String, QwixxPlayerSheet>.from(state.sheets);
    updated[playerId] = newSheet;
    state = state.copyWith(sheets: updated, canUndo: _history.isNotEmpty);
  }

  void resetGame() {
    _history.clear();
    state = state.copyWith(sheets: {}, canUndo: false);
  }
}

final qwixxStateProvider = NotifierProvider<QwixxStateNotifier, QwixxGameState>(
  QwixxStateNotifier.new,
);
