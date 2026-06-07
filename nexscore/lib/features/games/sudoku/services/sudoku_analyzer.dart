import '../models/sudoku_models.dart';

class AnalysisResult {
  final int cellIndex;
  final int value;
  final String explanation;

  const AnalysisResult({
    required this.cellIndex,
    required this.value,
    required this.explanation,
  });
}

class SudokuAnalyzer {
  /// Analyzes the grid to find a logical next step.
  /// Returns the first Naked Single or Hidden Single found, or null if no simple logic applies.
  static AnalysisResult? analyze(List<SudokuCell> grid, SudokuVariant variant) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;

    // 1. Calculate candidates for all empty cells
    final candidates = List<Set<int>>.generate(grid.length, (_) => {});
    for (int i = 0; i < grid.length; i++) {
      if (grid[i].currentValue == 0) {
        candidates[i] = _getCandidates(grid, i, variant);
      }
    }

    // 2. Look for Naked Singles (cell with exactly 1 candidate)
    for (int i = 0; i < grid.length; i++) {
      if (grid[i].currentValue == 0 && candidates[i].length == 1) {
        final val = candidates[i].first;
        final r = i ~/ size;
        final c = i % size;
        return AnalysisResult(
          cellIndex: i,
          value: val,
          explanation: 'Naked Single: At Row ${r + 1}, Column ${c + 1}, the only number that can legally fit is $val. All other numbers [1-$size] clash with numbers already present in its row, column, or block.',
        );
      }
    }

    // 3. Look for Hidden Singles in Rows
    for (int r = 0; r < size; r++) {
      for (int val = 1; val <= size; val++) {
        int possibleColsCount = 0;
        int targetIdx = -1;
        for (int c = 0; c < size; c++) {
          final idx = r * size + c;
          if (grid[idx].currentValue == 0 && candidates[idx].contains(val)) {
            possibleColsCount++;
            targetIdx = idx;
          }
        }
        if (possibleColsCount == 1) {
          final c = targetIdx % size;
          return AnalysisResult(
            cellIndex: targetIdx,
            value: val,
            explanation: 'Hidden Single (Row): In Row ${r + 1}, the number $val can only be legally placed in Column ${c + 1}. All other empty cells in this row are blocked by $val in corresponding columns or blocks.',
          );
        }
      }
    }

    // 4. Look for Hidden Singles in Columns
    for (int c = 0; c < size; c++) {
      for (int val = 1; val <= size; val++) {
        int possibleRowsCount = 0;
        int targetIdx = -1;
        for (int r = 0; r < size; r++) {
          final idx = r * size + c;
          if (grid[idx].currentValue == 0 && candidates[idx].contains(val)) {
            possibleRowsCount++;
            targetIdx = idx;
          }
        }
        if (possibleRowsCount == 1) {
          final r = targetIdx ~/ size;
          return AnalysisResult(
            cellIndex: targetIdx,
            value: val,
            explanation: 'Hidden Single (Column): In Column ${c + 1}, the number $val can only be legally placed in Row ${r + 1}. No other empty cells in this column can accept $val due to row or block constraints.',
          );
        }
      }
    }

    // 5. Look for Hidden Singles in Blocks
    final boxRows = size == 6 ? 2 : 3;
    final boxCols = size == 6 ? 3 : 3;
    final numBoxes = size == 6 ? 6 : 9;

    for (int b = 0; b < numBoxes; b++) {
      final startRow = (b ~/ (size ~/ boxRows)) * boxRows;
      final startCol = (b % (size ~/ boxRows)) * boxCols;

      for (int val = 1; val <= size; val++) {
        int possibleCellsCount = 0;
        int targetIdx = -1;

        for (int r = startRow; r < startRow + boxRows; r++) {
          for (int c = startCol; c < startCol + boxCols; c++) {
            final idx = r * size + c;
            if (grid[idx].currentValue == 0 && candidates[idx].contains(val)) {
              possibleCellsCount++;
              targetIdx = idx;
            }
          }
        }

        if (possibleCellsCount == 1) {
          final r = targetIdx ~/ size;
          final c = targetIdx % size;
          return AnalysisResult(
            cellIndex: targetIdx,
            value: val,
            explanation: 'Hidden Single (Block): In Block ${b + 1}, the number $val has only one valid cell where it can fit (Row ${r + 1}, Column ${c + 1}). All other empty spaces in this block are blocked by $val in neighboring rows or columns.',
          );
        }
      }
    }

    // 6. Fallback: return the first empty cell value
    for (int i = 0; i < grid.length; i++) {
      if (grid[i].currentValue == 0) {
        final r = i ~/ size;
        final c = i % size;
        return AnalysisResult(
          cellIndex: i,
          value: grid[i].value,
          explanation: 'Reveal Hint: At Row ${r + 1}, Column ${c + 1}, the correct value is ${grid[i].value}. Use logical elimination to figure out why other digits are blocked!',
        );
      }
    }

    return null;
  }

  static Set<int> _getCandidates(List<SudokuCell> grid, int idx, SudokuVariant variant) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final row = idx ~/ size;
    final col = idx % size;

    final used = <int>{};

    // Row checks
    for (int c = 0; c < size; c++) {
      final val = grid[row * size + c].currentValue;
      if (val > 0) used.add(val);
    }

    // Column checks
    for (int r = 0; r < size; r++) {
      final val = grid[r * size + col].currentValue;
      if (val > 0) used.add(val);
    }

    // Box checks
    if (size == 6) {
      final boxRowStart = (row ~/ 2) * 2;
      final boxColStart = (col ~/ 3) * 3;
      for (int r = boxRowStart; r < boxRowStart + 2; r++) {
        for (int c = boxColStart; c < boxColStart + 3; c++) {
          final val = grid[r * size + c].currentValue;
          if (val > 0) used.add(val);
        }
      }
    } else {
      final boxRowStart = (row ~/ 3) * 3;
      final boxColStart = (col ~/ 3) * 3;
      for (int r = boxRowStart; r < boxRowStart + 3; r++) {
        for (int c = boxColStart; c < boxColStart + 3; c++) {
          final val = grid[r * size + c].currentValue;
          if (val > 0) used.add(val);
        }
      }
    }

    // Diagonal X-Sudoku rules
    if (variant == SudokuVariant.diagonal) {
      if (row == col) {
        for (int i = 0; i < 9; i++) {
          final val = grid[i * 9 + i].currentValue;
          if (val > 0) used.add(val);
        }
      }
      if (row == 8 - col) {
        for (int i = 0; i < 9; i++) {
          final val = grid[i * 9 + (8 - i)].currentValue;
          if (val > 0) used.add(val);
        }
      }
    }

    // Hyper Sudoku shaded region rules
    if (variant == SudokuVariant.hyper) {
      final hyperRegion = _getHyperRegion(row, col);
      if (hyperRegion != null) {
        final (rStart, rEnd, cStart, cEnd) = hyperRegion;
        for (int r = rStart; r <= rEnd; r++) {
          for (int c = cStart; c <= cEnd; c++) {
            final val = grid[r * 9 + c].currentValue;
            if (val > 0) used.add(val);
          }
        }
      }
    }

    final candidates = <int>{};
    for (int i = 1; i <= size; i++) {
      if (!used.contains(i)) {
        candidates.add(i);
      }
    }
    return candidates;
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
}
