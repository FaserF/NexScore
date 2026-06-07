import '../models/sudoku_models.dart';

class AnalysisResult {
  final int cellIndex;
  final int value;
  final String explanationKey;
  final List<String> explanationArgs;

  const AnalysisResult({
    required this.cellIndex,
    required this.value,
    required this.explanationKey,
    required this.explanationArgs,
  });
}

class SudokuAnalyzer {
  /// Analyzes the grid to find a logical next step.
  /// Returns the first Naked Single or Hidden Single found, or null if no simple logic applies.
  static AnalysisResult? analyze(List<SudokuCell> grid, SudokuVariant variant, {int? selectedCellIndex}) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;

    // 1. Calculate candidates for all empty cells
    final candidates = List<Set<int>>.generate(grid.length, (_) => {});
    for (int i = 0; i < grid.length; i++) {
      if (grid[i].currentValue == 0) {
        candidates[i] = _getCandidates(grid, i, variant);
      }
    }

    // 2. Prioritize selected cell if it is empty
    if (selectedCellIndex != null && selectedCellIndex >= 0 && selectedCellIndex < grid.length) {
      final i = selectedCellIndex;
      if (grid[i].currentValue == 0) {
        final r = i ~/ size;
        final c = i % size;

        // Check Naked Single for this cell
        if (candidates[i].length == 1) {
          final val = candidates[i].first;
          return AnalysisResult(
            cellIndex: i,
            value: val,
            explanationKey: 'sudoku_hint_naked_single',
            explanationArgs: ['${r + 1}', '${c + 1}', '$val', '$size'],
          );
        }

        // Check Hidden Single in Row for this cell
        for (int val = 1; val <= size; val++) {
          if (candidates[i].contains(val)) {
            int possibleColsCount = 0;
            for (int colIdx = 0; colIdx < size; colIdx++) {
              final idx = r * size + colIdx;
              if (grid[idx].currentValue == 0 && candidates[idx].contains(val)) {
                possibleColsCount++;
              }
            }
            if (possibleColsCount == 1) {
              return AnalysisResult(
                cellIndex: i,
                value: val,
                explanationKey: 'sudoku_hint_hidden_row',
                explanationArgs: ['${r + 1}', '$val', '${c + 1}'],
              );
            }
          }
        }

        // Check Hidden Single in Column for this cell
        for (int val = 1; val <= size; val++) {
          if (candidates[i].contains(val)) {
            int possibleRowsCount = 0;
            for (int rowIdx = 0; rowIdx < size; rowIdx++) {
              final idx = rowIdx * size + c;
              if (grid[idx].currentValue == 0 && candidates[idx].contains(val)) {
                possibleRowsCount++;
              }
            }
            if (possibleRowsCount == 1) {
              return AnalysisResult(
                cellIndex: i,
                value: val,
                explanationKey: 'sudoku_hint_hidden_col',
                explanationArgs: ['${c + 1}', '$val', '${r + 1}'],
              );
            }
          }
        }

        // Check Hidden Single in Block for this cell
        final boxRows = size == 6 ? 2 : 3;
        final boxCols = size == 6 ? 3 : 3;
        final b = (r ~/ boxRows) * (size ~/ boxRows) + (c ~/ boxCols);
        final startRow = (b ~/ (size ~/ boxRows)) * boxRows;
        final startCol = (b % (size ~/ boxRows)) * boxCols;

        for (int val = 1; val <= size; val++) {
          if (candidates[i].contains(val)) {
            int possibleCellsCount = 0;
            for (int rowIdx = startRow; rowIdx < startRow + boxRows; rowIdx++) {
              for (int colIdx = startCol; colIdx < startCol + boxCols; colIdx++) {
                final idx = rowIdx * size + colIdx;
                if (grid[idx].currentValue == 0 && candidates[idx].contains(val)) {
                  possibleCellsCount++;
                }
              }
            }
            if (possibleCellsCount == 1) {
              return AnalysisResult(
                cellIndex: i,
                value: val,
                explanationKey: 'sudoku_hint_hidden_block',
                explanationArgs: ['${b + 1}', '$val', '${r + 1}', '${c + 1}'],
              );
            }
          }
        }

        // Fallback: Reveal this specific cell if no logic found
        return AnalysisResult(
          cellIndex: i,
          value: grid[i].value,
          explanationKey: 'sudoku_hint_reveal',
          explanationArgs: ['${r + 1}', '${c + 1}', '${grid[i].value}'],
        );
      }
    }

    // 3. Look for Naked Singles anywhere on the board (standard scan)
    for (int i = 0; i < grid.length; i++) {
      if (grid[i].currentValue == 0 && candidates[i].length == 1) {
        final val = candidates[i].first;
        final r = i ~/ size;
        final c = i % size;
        return AnalysisResult(
          cellIndex: i,
          value: val,
          explanationKey: 'sudoku_hint_naked_single',
          explanationArgs: ['${r + 1}', '${c + 1}', '$val', '$size'],
        );
      }
    }

    // 4. Look for Hidden Singles in Rows anywhere on the board
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
            explanationKey: 'sudoku_hint_hidden_row',
            explanationArgs: ['${r + 1}', '$val', '${c + 1}'],
          );
        }
      }
    }

    // 5. Look for Hidden Singles in Columns anywhere on the board
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
            explanationKey: 'sudoku_hint_hidden_col',
            explanationArgs: ['${c + 1}', '$val', '${r + 1}'],
          );
        }
      }
    }

    // 6. Look for Hidden Singles in Blocks anywhere on the board
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
            explanationKey: 'sudoku_hint_hidden_block',
            explanationArgs: ['${b + 1}', '$val', '${r + 1}', '${c + 1}'],
          );
        }
      }
    }

    // 7. Fallback: return the first empty cell value anywhere on the board
    for (int i = 0; i < grid.length; i++) {
      if (grid[i].currentValue == 0) {
        final r = i ~/ size;
        final c = i % size;
        return AnalysisResult(
          cellIndex: i,
          value: grid[i].value,
          explanationKey: 'sudoku_hint_reveal',
          explanationArgs: ['${r + 1}', '${c + 1}', '${grid[i].value}'],
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
