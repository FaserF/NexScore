import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sudoku_models.dart';
import '../services/sudoku_generator.dart';
import '../services/sudoku_sync_service.dart';

class SudokuStateNotifier extends Notifier<SudokuGameState> {
  final List<List<SudokuCell>> _history = [];
  Timer? _timer;

  @override
  SudokuGameState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    
    // Default initial empty state
    return const SudokuGameState(
      grid: [],
      difficulty: SudokuDifficulty.medium,
      variant: SudokuVariant.standard,
      mode: SudokuMode.classic,
      theme: SudokuTheme.aether,
    );
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isFinished) {
        timer.cancel();
        return;
      }
      state = state.copyWith(timeSeconds: state.timeSeconds + 1);
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void _pushHistory() {
    // Save deep copy of the grid
    final gridCopy = state.grid.map((c) => c.copyWith()).toList();
    _history.add(gridCopy);
    if (_history.length > 30) {
      _history.removeAt(0);
    }
  }

  bool get canUndo => _history.isNotEmpty;

  void undo() {
    if (_history.isNotEmpty) {
      final prevGrid = _history.removeLast();
      state = state.copyWith(grid: prevGrid);
    }
  }

  void setupMatch({
    required SudokuVariant variant,
    required SudokuDifficulty difficulty,
    required SudokuMode mode,
  }) {
    _history.clear();
    _timer?.cancel();

    final grid = SudokuGenerator.generate(variant: variant, difficulty: difficulty);

    state = SudokuGameState(
      grid: grid,
      difficulty: difficulty,
      variant: variant,
      mode: mode,
      theme: state.theme, // Preserve current theme
      mistakes: 0,
      maxMistakes: mode == SudokuMode.zen ? 9999 : 3,
      timeSeconds: 0,
      isFinished: false,
    );

    startTimer();
  }

  void setupDaily(
    String dateStr, {
    required SudokuVariant variant,
    required SudokuDifficulty difficulty,
  }) {
    _history.clear();
    _timer?.cancel();

    final grid = SudokuGenerator.generateDaily(
      dateStr: dateStr,
      variant: variant,
      difficulty: difficulty,
    );

    state = SudokuGameState(
      grid: grid,
      difficulty: difficulty,
      variant: variant,
      mode: SudokuMode.classic,
      theme: state.theme,
      mistakes: 0,
      maxMistakes: 3,
      timeSeconds: 0,
      isFinished: false,
      isDailyChallenge: true,
      dailyDate: dateStr,
    );

    startTimer();
  }

  void loadState(SudokuGameState savedState) {
    _history.clear();
    _timer?.cancel();
    state = savedState;
    if (!state.isFinished) {
      startTimer();
    }
  }

  void selectCell(int row, int col) {
    if (state.isFinished) return;
    state = state.copyWith(selectedRow: row, selectedCol: col);
  }

  void selectTheme(SudokuTheme theme) {
    state = state.copyWith(theme: theme);
  }

  void toggleNotesMode() {
    state = state.copyWith(notesMode: !state.notesMode);
  }

  void enterNumber(int num, String currentUsername) {
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null || state.isFinished) return;

    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;
    final cellIdx = r * size + c;
    final cell = state.grid[cellIdx];

    if (cell.isOriginal || cell.currentValue == cell.value) return;

    _pushHistory();

    if (state.notesMode) {
      // Toggle note/pencil mark
      final newNotes = Set<int>.from(cell.notes);
      if (newNotes.contains(num)) {
        newNotes.remove(num);
      } else {
        newNotes.add(num);
      }
      final newGrid = List<SudokuCell>.from(state.grid);
      newGrid[cellIdx] = cell.copyWith(notes: newNotes, currentValue: 0);
      state = state.copyWith(grid: newGrid);
    } else {
      // Standard input mode
      final isCorrect = cell.value == num;
      
      final newGrid = List<SudokuCell>.from(state.grid);
      newGrid[cellIdx] = cell.copyWith(
        currentValue: num,
        notes: {}, // Clear pencil notes when placing a number
        isError: !isCorrect,
      );

      // Validate board errors
      final validatedGrid = SudokuGenerator.validateBoard(newGrid, state.variant);

      int mistakes = state.mistakes;
      int penalty = 0;
      if (!isCorrect) {
        mistakes++;
        if (state.mode == SudokuMode.timeAttack) {
          penalty = 30; // 30s penalty for incorrect input in Time Attack
        }
      }

      // Check if grid is solved
      bool solved = true;
      for (final cell in validatedGrid) {
        if (cell.currentValue != cell.value) {
          solved = false;
          break;
        }
      }

      state = state.copyWith(
        grid: validatedGrid,
        mistakes: mistakes,
        timeSeconds: state.timeSeconds + penalty,
        isFinished: solved || mistakes >= state.maxMistakes,
      );

      if (state.isFinished) {
        _timer?.cancel();
        if (solved) {
          // Submit completed game to sync service
          SudokuSyncService.saveAndSyncScore(
            playerName: currentUsername.isEmpty ? 'Player' : currentUsername,
            timeSeconds: state.timeSeconds,
            variant: state.variant.name,
            difficulty: state.difficulty.name,
            mode: state.mode.name,
            isDaily: state.isDailyChallenge,
            dailyDate: state.dailyDate,
          );
        }
      }
    }
  }

  void eraseCell() {
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null || state.isFinished) return;

    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;
    final cellIdx = r * size + c;
    final cell = state.grid[cellIdx];

    if (cell.isOriginal || cell.currentValue == cell.value) return;

    _pushHistory();

    final newGrid = List<SudokuCell>.from(state.grid);
    newGrid[cellIdx] = cell.copyWith(currentValue: 0, notes: {}, isError: false);

    // Validate board errors
    final validatedGrid = SudokuGenerator.validateBoard(newGrid, state.variant);

    state = state.copyWith(grid: validatedGrid);
  }

  void useHint() {
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null || state.isFinished) return;

    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;
    final cellIdx = r * size + c;
    final cell = state.grid[cellIdx];

    if (cell.isOriginal || cell.currentValue == cell.value) return;

    _pushHistory();

    final newGrid = List<SudokuCell>.from(state.grid);
    newGrid[cellIdx] = cell.copyWith(
      currentValue: cell.value,
      notes: {},
      isError: false,
    );

    // Validate board errors
    final validatedGrid = SudokuGenerator.validateBoard(newGrid, state.variant);

    // Check if grid is solved
    bool solved = true;
    for (final cell in validatedGrid) {
      if (cell.currentValue != cell.value) {
        solved = false;
        break;
      }
    }

    state = state.copyWith(
      grid: validatedGrid,
      hasUsedHint: true,
      isFinished: solved,
    );

    if (state.isFinished) {
      _timer?.cancel();
    }
  }
}

final sudokuStateProvider = NotifierProvider<SudokuStateNotifier, SudokuGameState>(
  SudokuStateNotifier.new,
);
