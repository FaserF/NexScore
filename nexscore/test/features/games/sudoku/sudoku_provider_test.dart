import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nexscore/features/games/sudoku/models/sudoku_models.dart';
import 'package:nexscore/features/games/sudoku/providers/sudoku_provider.dart';
import 'package:nexscore/features/games/sudoku/services/sudoku_generator.dart';
import 'package:nexscore/features/games/sudoku/services/sudoku_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Sudoku Generator & Solver', () {
    test('Standard 9x9 generates correct cell counts', () {
      final cells = SudokuGenerator.generate(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.easy,
      );
      expect(cells.length, 81);
      
      // Check that correct solution values are generated
      for (final cell in cells) {
        expect(cell.value, inClosedOpenRange(1, 10));
      }
    });

    test('Mini 6x6 generates correct cell counts', () {
      final cells = SudokuGenerator.generate(
        variant: SudokuVariant.mini6x6,
        difficulty: SudokuDifficulty.medium,
      );
      expect(cells.length, 36);
      
      for (final cell in cells) {
        expect(cell.value, inClosedOpenRange(1, 7));
      }
    });

    test('Sudoku X diagonals contain no duplicate clues', () {
      final cells = SudokuGenerator.generate(
        variant: SudokuVariant.diagonal,
        difficulty: SudokuDifficulty.easy,
      );
      
      final diag1 = <int>{};
      final diag2 = <int>{};
      for (int i = 0; i < 9; i++) {
        final val1 = cells[i * 9 + i].currentValue;
        final val2 = cells[i * 9 + (8 - i)].currentValue;
        if (val1 > 0) expect(diag1.add(val1), isTrue);
        if (val2 > 0) expect(diag2.add(val2), isTrue);
      }
    });
  });

  group('SudokuStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('setupMatch sets up correct game values', () {
      final notifier = container.read(sudokuStateProvider.notifier);
      notifier.setupMatch(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.medium,
        mode: SudokuMode.classic,
      );

      final state = container.read(sudokuStateProvider);
      expect(state.grid.length, 81);
      expect(state.difficulty, SudokuDifficulty.medium);
      expect(state.variant, SudokuVariant.standard);
      expect(state.mode, SudokuMode.classic);
      expect(state.mistakes, 0);
      expect(state.isFinished, isFalse);
    });

    test('zen mode allows unlimited mistakes', () {
      final notifier = container.read(sudokuStateProvider.notifier);
      notifier.setupMatch(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.easy,
        mode: SudokuMode.zen,
      );

      final state = container.read(sudokuStateProvider);
      expect(state.maxMistakes, 9999);
    });

    test('selecting cell updates selectedRow and selectedCol', () {
      final notifier = container.read(sudokuStateProvider.notifier);
      notifier.setupMatch(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.easy,
        mode: SudokuMode.classic,
      );

      notifier.selectCell(2, 4);
      final state = container.read(sudokuStateProvider);
      expect(state.selectedRow, 2);
      expect(state.selectedCol, 4);
    });

    test('notes mode toggles pencil notes correctly', () {
      final notifier = container.read(sudokuStateProvider.notifier);
      notifier.setupMatch(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.medium,
        mode: SudokuMode.classic,
      );

      notifier.toggleNotesMode();
      expect(container.read(sudokuStateProvider).notesMode, isTrue);

      // Find an empty cell to edit
      final grid = container.read(sudokuStateProvider).grid;
      final emptyIdx = grid.indexWhere((c) => !c.isOriginal);
      final emptyCell = grid[emptyIdx];
      
      notifier.selectCell(emptyCell.row, emptyCell.col);
      
      // Enter a pencil note
      notifier.enterNumber(5, 'Player');
      expect(container.read(sudokuStateProvider).grid[emptyIdx].notes.contains(5), isTrue);

      // Toggle note off
      notifier.enterNumber(5, 'Player');
      expect(container.read(sudokuStateProvider).grid[emptyIdx].notes.contains(5), isFalse);
    });

    test('entering incorrect number increments mistakes and flags error', () {
      final notifier = container.read(sudokuStateProvider.notifier);
      notifier.setupMatch(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.easy,
        mode: SudokuMode.classic,
      );

      // Find an empty cell
      final grid = container.read(sudokuStateProvider).grid;
      final emptyIdx = grid.indexWhere((c) => !c.isOriginal);
      final emptyCell = grid[emptyIdx];
      
      notifier.selectCell(emptyCell.row, emptyCell.col);

      // Calculate an incorrect number (anything other than correct value)
      final incorrectVal = emptyCell.value == 9 ? 1 : emptyCell.value + 1;
      
      notifier.enterNumber(incorrectVal, 'Player');
      
      final state = container.read(sudokuStateProvider);
      expect(state.mistakes, 1);
      expect(state.grid[emptyIdx].isError, isTrue);
    });

    test('entering correct number auto-erases notes in same row/col/box', () {
      final notifier = container.read(sudokuStateProvider.notifier);
      notifier.setupMatch(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.easy,
        mode: SudokuMode.classic,
      );

      // Find an empty cell
      final grid = container.read(sudokuStateProvider).grid;
      final emptyIdx = grid.indexWhere((c) => !c.isOriginal);
      final cell = grid[emptyIdx];

      // Place a pencil note of correct value in another empty cell of same row
      final siblingIdx = grid.indexWhere((c) => !c.isOriginal && c.row == cell.row && c.col != cell.col);
      
      if (siblingIdx != -1) {
        notifier.selectCell(grid[siblingIdx].row, grid[siblingIdx].col);
        notifier.toggleNotesMode();
        notifier.enterNumber(cell.value, 'Player'); // Put note
        
        expect(container.read(sudokuStateProvider).grid[siblingIdx].notes.contains(cell.value), isTrue);

        // Fill cell with correct value
        notifier.toggleNotesMode(); // Standard mode
        notifier.selectCell(cell.row, cell.col);
        notifier.enterNumber(cell.value, 'Player');

        // Note in sibling cell should be auto-erased
        expect(container.read(sudokuStateProvider).grid[siblingIdx].notes.contains(cell.value), isFalse);
      }
    });

    test('undo restores previous grid state', () {
      final notifier = container.read(sudokuStateProvider.notifier);
      notifier.setupMatch(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.easy,
        mode: SudokuMode.classic,
      );

      final gridBefore = container.read(sudokuStateProvider).grid;
      final emptyIdx = gridBefore.indexWhere((c) => !c.isOriginal);
      final cell = gridBefore[emptyIdx];

      notifier.selectCell(cell.row, cell.col);
      notifier.enterNumber(cell.value, 'Player');

      expect(container.read(sudokuStateProvider).grid[emptyIdx].currentValue, cell.value);

      // Undo input
      notifier.undo();
      expect(container.read(sudokuStateProvider).grid[emptyIdx].currentValue, 0);
    });

    test('setupCampaignLevel initializes level and completing unlocks next', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = container.read(sudokuStateProvider.notifier);
      
      notifier.setupCampaignLevel(1);
      var state = container.read(sudokuStateProvider);
      
      expect(state.campaignLevelId, 1);
      expect(state.variant, SudokuVariant.mini6x6);
      expect(state.difficulty, SudokuDifficulty.easy);

      final emptyCellsIndices = <int>[];
      for (int i = 0; i < state.grid.length; i++) {
        if (state.grid[i].currentValue == 0) {
          emptyCellsIndices.add(i);
        }
      }

      for (int i = 0; i < emptyCellsIndices.length - 1; i++) {
        final idx = emptyCellsIndices[i];
        final cell = state.grid[idx];
        notifier.selectCell(cell.row, cell.col);
        notifier.enterNumber(cell.value, 'Tester');
      }

      state = container.read(sudokuStateProvider);
      expect(state.isFinished, isFalse);

      final lastIdx = emptyCellsIndices.last;
      final lastCell = state.grid[lastIdx];
      notifier.selectCell(lastCell.row, lastCell.col);
      notifier.enterNumber(lastCell.value, 'Tester');

      state = container.read(sudokuStateProvider);
      expect(state.isFinished, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sudoku_academy_level_completed_1'), isTrue);
    });

    test('SudokuAnalyzer identifies logical singles correctly', () {
      final cells = SudokuGenerator.generate(
        variant: SudokuVariant.standard,
        difficulty: SudokuDifficulty.easy,
      );

      final analysis = SudokuAnalyzer.analyze(cells, SudokuVariant.standard);
      expect(analysis, isNotNull);
      expect(analysis!.explanation, contains('Single'));
    });
  });
}
