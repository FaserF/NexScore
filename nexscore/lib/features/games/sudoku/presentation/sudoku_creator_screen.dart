import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../models/sudoku_models.dart';
import '../services/sudoku_generator.dart';
import '../services/sudoku_share_service.dart';
import '../providers/sudoku_provider.dart';
import '../../../../core/providers/persistence_provider.dart';

class SudokuCreatorScreen extends ConsumerStatefulWidget {
  const SudokuCreatorScreen({super.key});

  @override
  ConsumerState<SudokuCreatorScreen> createState() => _SudokuCreatorScreenState();
}

class _SudokuCreatorScreenState extends ConsumerState<SudokuCreatorScreen> {
  SudokuVariant _selectedVariant = SudokuVariant.standard;
  int? _selectedRow;
  int? _selectedCol;
  late List<int> _gridValues;
  bool _isValidating = false;
  String? _validationStatus; // 'untested', 'unique', 'invalid', 'multiple'
  String? _shareCode;

  @override
  void initState() {
    super.initState();
    _resetGrid();
  }

  void _resetGrid() {
    final size = _selectedVariant == SudokuVariant.mini6x6 ? 6 : 9;
    setState(() {
      _gridValues = List.filled(size * size, 0);
      _selectedRow = null;
      _selectedCol = null;
      _validationStatus = 'untested';
      _shareCode = null;
    });
  }

  void _onCellTap(int r, int c) {
    setState(() {
      _selectedRow = r;
      _selectedCol = c;
    });
  }

  void _onNumpadPress(int num) {
    final r = _selectedRow;
    final c = _selectedCol;
    if (r == null || c == null) return;

    final size = _selectedVariant == SudokuVariant.mini6x6 ? 6 : 9;
    final idx = r * size + c;

    setState(() {
      if (_gridValues[idx] == num) {
        _gridValues[idx] = 0; // Toggle off
      } else {
        _gridValues[idx] = num;
      }
      _validationStatus = 'untested';
      _shareCode = null;
    });
    ref.read(audioServiceProvider).play(SfxType.swipe);
  }

  void _onErasePress() {
    final r = _selectedRow;
    final c = _selectedCol;
    if (r == null || c == null) return;

    final size = _selectedVariant == SudokuVariant.mini6x6 ? 6 : 9;
    final idx = r * size + c;

    setState(() {
      _gridValues[idx] = 0;
      _validationStatus = 'untested';
      _shareCode = null;
    });
    ref.read(audioServiceProvider).play(SfxType.swipe);
  }

  Future<void> _validatePuzzle() async {
    setState(() {
      _isValidating = true;
    });

    // Run solver checks off main frame delay
    await Future.delayed(const Duration(milliseconds: 300));

    final size = _selectedVariant == SudokuVariant.mini6x6 ? 6 : 9;
    
    // Check if there are basic rule violations before running solver
    bool hasClash = false;
    for (int i = 0; i < _gridValues.length; i++) {
      final val = _gridValues[i];
      if (val > 0) {
        // Temporarily clear to validate if it clashes with others
        final copy = List<int>.from(_gridValues)..[i] = 0;
        final isValid = _checkBasicValidity(copy, val, i, _selectedVariant);
        if (!isValid) {
          hasClash = true;
          break;
        }
      }
    }

    if (hasClash) {
      setState(() {
        _validationStatus = 'invalid';
        _isValidating = false;
      });
      ref.read(audioServiceProvider).play(SfxType.swipe); // Error sound
      return;
    }

    // Solve grid
    final solution = SudokuGenerator.solve(_gridValues, _selectedVariant);
    if (solution == null) {
      setState(() {
        _validationStatus = 'invalid';
        _isValidating = false;
      });
      ref.read(audioServiceProvider).play(SfxType.swipe);
      return;
    }

    // Check unique solution
    final isUnique = SudokuGenerator.hasUniqueSolution(_gridValues, _selectedVariant);
    if (isUnique) {
      // Construct temporary cells list to export
      final List<SudokuCell> cells = [];
      for (int r = 0; r < size; r++) {
        for (int c = 0; c < size; c++) {
          final idx = r * size + c;
          cells.add(SudokuCell(
            row: r,
            col: c,
            value: solution[idx],
            currentValue: _gridValues[idx],
            isOriginal: _gridValues[idx] > 0,
            notes: const {},
          ));
        }
      }
      final code = SudokuShareService.exportToCode(cells, _selectedVariant);

      setState(() {
        _validationStatus = 'unique';
        _shareCode = code;
        _isValidating = false;
      });
      ref.read(audioServiceProvider).play(SfxType.fanfare);
    } else {
      setState(() {
        _validationStatus = 'multiple';
        _isValidating = false;
      });
      ref.read(audioServiceProvider).play(SfxType.swipe);
    }
  }

  // Helper check matching the solver check logic
  bool _checkBasicValidity(List<int> board, int val, int idx, SudokuVariant variant) {
    final size = variant == SudokuVariant.mini6x6 ? 6 : 9;
    final row = idx ~/ size;
    final col = idx % size;

    // Row check
    for (int c = 0; c < size; c++) {
      if (board[row * size + c] == val) return false;
    }

    // Column check
    for (int r = 0; r < size; r++) {
      if (board[r * size + col] == val) return false;
    }

    // Box check
    if (variant == SudokuVariant.mini6x6) {
      final boxRowStart = (row ~/ 2) * 2;
      final boxColStart = (col ~/ 3) * 3;
      for (int r = boxRowStart; r < boxRowStart + 2; r++) {
        for (int c = boxColStart; c < boxColStart + 3; c++) {
          if (board[r * size + c] == val) return false;
        }
      }
    } else {
      final boxRowStart = (row ~/ 3) * 3;
      final boxColStart = (col ~/ 3) * 3;
      for (int r = boxRowStart; r < boxRowStart + 3; r++) {
        for (int c = boxColStart; c < boxColStart + 3; c++) {
          if (board[r * size + c] == val) return false;
        }
      }
    }

    return true;
  }

  void _launchCustomGame() {
    if (_shareCode == null) return;
    
    final result = SudokuShareService.importFromCode(_shareCode!);
    if (result != null) {
      final customState = SudokuGameState(
        grid: result.grid,
        difficulty: SudokuDifficulty.medium,
        variant: result.variant,
        mode: SudokuMode.classic,
        theme: SudokuTheme.aether,
      );

      ref.read(sudokuStateProvider.notifier).loadState(customState);
      ref.read(activeGameIdProvider.notifier).state = 'sudoku';
      context.pop(); // Pop back to dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _selectedVariant == SudokuVariant.mini6x6 ? 6 : 9;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      appBar: AppBar(
        title: const Text(
          'BOARD CREATOR',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: _resetGrid,
            tooltip: 'Clear grid canvas',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Button to select variant
              SegmentedButton<SudokuVariant>(
                segments: const [
                  ButtonSegment(value: SudokuVariant.standard, label: Text('Standard')),
                  ButtonSegment(value: SudokuVariant.diagonal, label: Text('Diagonal')),
                  ButtonSegment(value: SudokuVariant.hyper, label: Text('Hyper')),
                  ButtonSegment(value: SudokuVariant.mini6x6, label: Text('6x6')),
                ],
                selected: {_selectedVariant},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedVariant = set.first;
                    _resetGrid();
                  });
                },
              ),
              const SizedBox(height: 20),

              // Validation State Banner
              _buildValidationBanner(),
              const SizedBox(height: 20),

              // Creator Interactive Canvas Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigoAccent, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size,
                        ),
                        itemCount: size * size,
                        itemBuilder: (context, index) {
                          final r = index ~/ size;
                          final c = index % size;
                          final val = _gridValues[index];
                          final isSelected = _selectedRow == r && _selectedCol == c;

                          final borderRight = (c == 2 || c == 5) && size == 9 || (c == 2 && size == 6);
                          final borderBottom = (r == 2 || r == 5) && size == 9 || (r == 1 || r == 3) && size == 6;

                          Color cellBg = isSelected ? Colors.indigoAccent.withAlpha(80) : Colors.transparent;

                          return GestureDetector(
                            onTap: () => _onCellTap(r, c),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cellBg,
                                border: Border(
                                  top: const BorderSide(color: Colors.white10, width: 0.5),
                                  left: const BorderSide(color: Colors.white10, width: 0.5),
                                  right: BorderSide(
                                    color: borderRight ? Colors.indigoAccent : Colors.white10,
                                    width: borderRight ? 2.0 : 0.5,
                                  ),
                                  bottom: BorderSide(
                                    color: borderBottom ? Colors.indigoAccent : Colors.white10,
                                    width: borderBottom ? 2.0 : 0.5,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: val > 0
                                    ? Text(
                                        '$val',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons Panel
              if (_validationStatus == 'unique')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, color: Colors.indigoAccent),
                        label: const Text('COPY CODE', style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          if (_shareCode != null) {
                            Clipboard.setData(ClipboardData(text: _shareCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Board code copied to clipboard!')),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('PLAY PUZZLE'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.indigoAccent),
                        onPressed: _launchCustomGame,
                      ),
                    ),
                  ],
                )
              else
                FilledButton(
                  onPressed: _isValidating ? null : _validatePuzzle,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isValidating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('VERIFY BOARD & PLAY', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 20),

              // Numerical Selector Numpad
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ...List.generate(size, (index) {
                    final num = index + 1;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: AnimatedScaleButton(
                          onPressed: () => _onNumpadPress(num),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.indigoAccent.withAlpha(80)),
                            ),
                            child: Center(
                              child: Text(
                                '$num',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigoAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Erase Button
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: AnimatedScaleButton(
                        onPressed: _onErasePress,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.pinkAccent.withAlpha(80)),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.pinkAccent, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidationBanner() {
    switch (_validationStatus) {
      case 'unique':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.greenAccent),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Board verified! Unique solution found. You can copy the code to share or play it directly.',
                  style: TextStyle(fontSize: 12, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      case 'multiple':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amberAccent),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amberAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Multiple solutions found. Add more clues to enforce a single unique logical design.',
                  style: TextStyle(fontSize: 12, color: Colors.amberAccent),
                ),
              ),
            ],
          ),
        );
      case 'invalid':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent),
          ),
          child: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No solutions possible. Check placed clues for overlapping row, column, or block conflicts.',
                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: const Row(
            children: [
              Icon(Icons.edit_note, color: Colors.indigoAccent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Place numbers on the canvas, then verify that your design holds exactly one solution.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
    }
  }
}
