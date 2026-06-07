import 'dart:math';
import '../models/sudoku_models.dart';

class SudokuGenerator {
  static final Random _random = Random();

  /// Generates a new Sudoku game grid.
  /// Returns a list of cells.
  static List<SudokuCell> generate({
    required SudokuVariant variant,
    required SudokuDifficulty difficulty,
  }) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final totalCells = size * size;

    // 1. Generate a complete valid board
    List<int> solution = List.filled(totalCells, 0);
    _fillGrid(solution, variant);

    // 2. Make a copy to create the puzzle board
    List<int> puzzle = List.from(solution);

    // 3. Determine how many clues to leave
    int cluesToRemove;
    if (variant == SudokuVariant.mini6x6) {
      // 6x6 board: easy (20), medium (16), hard (13), expert (10 clues left)
      cluesToRemove = switch (difficulty) {
        SudokuDifficulty.easy => 16,
        SudokuDifficulty.medium => 20,
        SudokuDifficulty.hard => 23,
        SudokuDifficulty.expert => 26,
      };
    } else {
      // 9x9 board: easy (~42 clues left), medium (~34), hard (~26), expert (~21)
      cluesToRemove = switch (difficulty) {
        SudokuDifficulty.easy => 38,
        SudokuDifficulty.medium => 46,
        SudokuDifficulty.hard => 54,
        SudokuDifficulty.expert => 60,
      };
    }

    // 4. Remove cells while maintaining a unique solution
    List<int> indices = List.generate(totalCells, (i) => i)..shuffle(_random);
    int removed = 0;

    for (final index in indices) {
      if (removed >= cluesToRemove) break;

      final originalVal = puzzle[index];
      puzzle[index] = 0;

      // Check if board has a unique solution
      if (_hasUniqueSolution(puzzle, variant)) {
        removed++;
      } else {
        // Revert removal
        puzzle[index] = originalVal;
      }
    }

    // 5. Convert to SudokuCell list
    List<SudokuCell> cells = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final idx = r * size + c;
        final isGiven = puzzle[idx] != 0;
        cells.add(SudokuCell(
          row: r,
          col: c,
          value: solution[idx],
          currentValue: puzzle[idx],
          isOriginal: isGiven,
          notes: {},
        ));
      }
    }

    return cells;
  }

  /// Generates a Sudoku board using a custom string seed.
  static List<SudokuCell> generateSeeded({
    required String seed,
    required SudokuVariant variant,
    required SudokuDifficulty difficulty,
  }) {
    final seedInt = seed.hashCode;
    final seededRandom = Random(seedInt);
    
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final totalCells = size * size;

    List<int> solution = List.filled(totalCells, 0);
    _fillGridSeeded(solution, variant, seededRandom);

    List<int> puzzle = List.from(solution);
    
    int cluesToRemove;
    if (variant == SudokuVariant.mini6x6) {
      cluesToRemove = switch (difficulty) {
        SudokuDifficulty.easy => 16,
        SudokuDifficulty.medium => 20,
        SudokuDifficulty.hard => 23,
        SudokuDifficulty.expert => 26,
      };
    } else {
      cluesToRemove = switch (difficulty) {
        SudokuDifficulty.easy => 38,
        SudokuDifficulty.medium => 46,
        SudokuDifficulty.hard => 54,
        SudokuDifficulty.expert => 60,
      };
    }

    List<int> indices = List.generate(totalCells, (i) => i);
    // Shuffle indices with seeded random
    for (int i = indices.length - 1; i > 0; i--) {
      int n = seededRandom.nextInt(i + 1);
      int temp = indices[i];
      indices[i] = indices[n];
      indices[n] = temp;
    }

    int removed = 0;
    for (final index in indices) {
      if (removed >= cluesToRemove) break;
      final originalVal = puzzle[index];
      puzzle[index] = 0;
      if (_hasUniqueSolution(puzzle, variant)) {
        removed++;
      } else {
        puzzle[index] = originalVal;
      }
    }

    List<SudokuCell> cells = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final idx = r * size + c;
        final isGiven = puzzle[idx] != 0;
        cells.add(SudokuCell(
          row: r,
          col: c,
          value: solution[idx],
          currentValue: puzzle[idx],
          isOriginal: isGiven,
          notes: {},
        ));
      }
    }

    return cells;
  }

  /// Generates a Daily Challenge board using a seeded random based on the date string (e.g. "2026-06-07")
  static List<SudokuCell> generateDaily({
    required String dateStr,
    required SudokuVariant variant,
    required SudokuDifficulty difficulty,
  }) {
    // Generate a simple integer seed from the date string
    final seed = dateStr.hashCode;
    final oldRandom = _random;
    // Temporarily override random with seeded random
    final seededRandom = Random(seed);
    
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final totalCells = size * size;

    List<int> solution = List.filled(totalCells, 0);
    
    // Custom fill using seeded random
    _fillGridSeeded(solution, variant, seededRandom);

    List<int> puzzle = List.from(solution);
    int cluesToRemove = variant == SudokuVariant.mini6x6 
        ? (difficulty == SudokuDifficulty.easy ? 16 : 22)
        : (difficulty == SudokuDifficulty.easy ? 38 : 50);

    List<int> indices = List.generate(totalCells, (i) => i);
    // Shuffle indices with seeded random
    for (int i = indices.length - 1; i > 0; i--) {
      int n = seededRandom.nextInt(i + 1);
      int temp = indices[i];
      indices[i] = indices[n];
      indices[n] = temp;
    }

    int removed = 0;
    for (final index in indices) {
      if (removed >= cluesToRemove) break;
      final originalVal = puzzle[index];
      puzzle[index] = 0;
      if (_hasUniqueSolution(puzzle, variant)) {
        removed++;
      } else {
        puzzle[index] = originalVal;
      }
    }

    List<SudokuCell> cells = [];
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        final idx = r * size + c;
        final isGiven = puzzle[idx] != 0;
        cells.add(SudokuCell(
          row: r,
          col: c,
          value: solution[idx],
          currentValue: puzzle[idx],
          isOriginal: isGiven,
          notes: {},
        ));
      }
    }

    return cells;
  }

  // --- Core Validation and Backtracking Algorithms ---

  static bool _isValid(List<int> board, int val, int idx, SudokuVariant variant) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final row = idx ~/ size;
    final col = idx % size;

    // 1. Row check
    for (int c = 0; c < size; c++) {
      if (c != col && board[row * size + c] == val) return false;
    }

    // 2. Column check
    for (int r = 0; r < size; r++) {
      if (r != row && board[r * size + col] == val) return false;
    }

    // 3. Box check
    if (variant == SudokuVariant.mini6x6) {
      // 2x3 blocks
      final boxRowStart = (row ~/ 2) * 2;
      final boxColStart = (col ~/ 3) * 3;
      for (int r = boxRowStart; r < boxRowStart + 2; r++) {
        for (int c = boxColStart; c < boxColStart + 3; c++) {
          if ((r != row || c != col) && board[r * size + c] == val) return false;
        }
      }
    } else {
      // 3x3 blocks
      final boxRowStart = (row ~/ 3) * 3;
      final boxColStart = (col ~/ 3) * 3;
      for (int r = boxRowStart; r < boxRowStart + 3; r++) {
        for (int c = boxColStart; c < boxColStart + 3; c++) {
          if ((r != row || c != col) && board[r * size + c] == val) return false;
        }
      }
    }

    // 4. Variant: Diagonal (Sudoku X)
    if (variant == SudokuVariant.diagonal) {
      // Main diagonal (top-left to bottom-right)
      if (row == col) {
        for (int i = 0; i < 9; i++) {
          if (i != row && board[i * 9 + i] == val) return false;
        }
      }
      // Anti-diagonal (top-right to bottom-left)
      if (row == 8 - col) {
        for (int i = 0; i < 9; i++) {
          if (i != row && board[i * 9 + (8 - i)] == val) return false;
        }
      }
    }

    // 5. Variant: Hyper Sudoku (Windoku)
    if (variant == SudokuVariant.hyper) {
      // Check if cell lies inside one of the 4 hyper regions:
      // Rows 1,2,3 and Cols 1,2,3
      // Rows 1,2,3 and Cols 5,6,7
      // Rows 5,6,7 and Cols 1,2,3
      // Rows 5,6,7 and Cols 5,6,7
      final hyperRegion = _getHyperRegion(row, col);
      if (hyperRegion != null) {
        final (rStart, rEnd, cStart, cEnd) = hyperRegion;
        for (int r = rStart; r <= rEnd; r++) {
          for (int c = cStart; c <= cEnd; c++) {
            if ((r != row || c != col) && board[r * 9 + c] == val) return false;
          }
        }
      }
    }

    return true;
  }

  static (int, int, int, int)? _getHyperRegion(int r, int c) {
    if (r >= 1 && r <= 3) {
      if (c >= 1 && c <= 3) return (1, 3, 1, 3);
      if (c >= 5 && c <= 7) return (1, 3, 5, 7);
    } else if (r >= 5 && r <= 7) {
      if (c >= 1 && c <= 3) return (5, 7, 1, 3);
      if (c >= 5 && c <= 7) return (5, 7, 5, 7);
    }
    return null;
  }

  static bool _fillGrid(List<int> board, SudokuVariant variant) {
    return _fillGridSeeded(board, variant, _random);
  }

  static bool _fillGridSeeded(List<int> board, SudokuVariant variant, Random rand) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final totalCells = size * size;

    for (int i = 0; i < totalCells; i++) {
      if (board[i] == 0) {
        List<int> nums = List.generate(size, (n) => n + 1)..shuffle(rand);
        for (final val in nums) {
          if (_isValid(board, val, i, variant)) {
            board[i] = val;
            if (_fillGridSeeded(board, variant, rand)) return true;
            board[i] = 0;
          }
        }
        return false;
      }
    }
    return true;
  }

  /// Solves the puzzle grid and returns count of solutions up to 2 (to check uniqueness).
  static int _solveCounter(List<int> board, SudokuVariant variant, int index, int count) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final total = size * size;
    if (index == total) {
      return count + 1;
    }

    if (board[index] != 0) {
      return _solveCounter(board, variant, index + 1, count);
    }

    for (int val = 1; val <= size; val++) {
      if (_isValid(board, val, index, variant)) {
        board[index] = val;
        count = _solveCounter(board, variant, index + 1, count);
        board[index] = 0;
        if (count >= 2) break; // Optimization: stop search if we have multiple solutions
      }
    }
    return count;
  }

  static bool _hasUniqueSolution(List<int> board, SudokuVariant variant) {
    List<int> boardCopy = List.from(board);
    final solutions = _solveCounter(boardCopy, variant, 0, 0);
    return solutions == 1;
  }

  static bool hasUniqueSolution(List<int> board, SudokuVariant variant) {
    return _hasUniqueSolution(board, variant);
  }

  static List<int>? solve(List<int> puzzle, SudokuVariant variant) {
    List<int> board = List.from(puzzle);
    bool solved = _solveBoard(board, variant);
    return solved ? board : null;
  }

  static bool _solveBoard(List<int> board, SudokuVariant variant) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final total = size * size;
    for (int i = 0; i < total; i++) {
      if (board[i] == 0) {
        for (int val = 1; val <= size; val++) {
          if (_isValid(board, val, i, variant)) {
            board[i] = val;
            if (_solveBoard(board, variant)) return true;
            board[i] = 0;
          }
        }
        return false;
      }
    }
    return true;
  }

  /// Check conflicts for a grid where the user is entering numbers
  static List<SudokuCell> validateBoard(List<SudokuCell> originalGrid, SudokuVariant variant) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    List<int> values = originalGrid.map((c) => c.currentValue).toList();
    List<SudokuCell> checkedGrid = [];

    for (int i = 0; i < originalGrid.length; i++) {
      final cell = originalGrid[i];
      if (cell.currentValue == 0) {
        checkedGrid.add(cell.copyWith(isError: false));
      } else {
        // Temporarily clear grid slot to check if it clashes with others
        values[i] = 0;
        final valid = _isValid(values, cell.currentValue, i, variant);
        values[i] = cell.currentValue;
        checkedGrid.add(cell.copyWith(isError: !valid));
      }
    }
    return checkedGrid;
  }
}
