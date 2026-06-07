import '../models/sudoku_models.dart';
import 'sudoku_generator.dart';

class ImportResult {
  final SudokuVariant variant;
  final List<SudokuCell> grid;

  const ImportResult({
    required this.variant,
    required this.grid,
  });
}

class SudokuShareService {
  /// Exports the grid puzzle configurations to a shareable code string.
  static String exportToCode(List<SudokuCell> grid, SudokuVariant variant) {
    final values = grid.map((c) => c.isOriginal ? c.value : 0).join('');
    return '${variant.name}:$values';
  }

  /// Imports a shareable code string into a playable grid setup.
  /// Returns null if the code is invalid or can't be solved.
  static ImportResult? importFromCode(String code) {
    try {
      final parts = code.trim().split(':');
      if (parts.length != 2) return null;

      final variantStr = parts[0];
      final valuesStr = parts[1];

      final variant = SudokuVariant.values.firstWhere(
        (v) => v.name == variantStr,
        orElse: () => throw Exception('Invalid variant'),
      );

      final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
      final expectedLength = size * size;
      if (valuesStr.length != expectedLength) return null;

      final clues = valuesStr.split('').map((char) => int.parse(char)).toList();

      // Solve the board to populate solution values
      final solution = SudokuGenerator.solve(clues, variant);
      if (solution == null) return null;

      // Construct grid cells
      final List<SudokuCell> cells = [];
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          final idx = r * size + c;
          final clue = clues[idx];
          cells.add(SudokuCell(
            row: r,
            col: c,
            value: solution[idx],
            currentValue: clue,
            isOriginal: clue > 0,
          ));
        }
      }

      return ImportResult(variant: variant, grid: cells);
    } catch (_) {
      return null;
    }
  }
}
