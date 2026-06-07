import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';

class TutorialStep {
  final String title;
  final String instruction;
  final String targetExplanation;
  final List<int> initialGrid; // 16 values for 4x4
  final List<bool> isGiven;
  final int targetRow;
  final int targetCol;
  final int targetValue;

  const TutorialStep({
    required this.title,
    required this.instruction,
    required this.targetExplanation,
    required this.initialGrid,
    required this.isGiven,
    required this.targetRow,
    required this.targetCol,
    required this.targetValue,
  });
}

class SudokuTutorialScreen extends ConsumerStatefulWidget {
  const SudokuTutorialScreen({super.key});

  @override
  ConsumerState<SudokuTutorialScreen> createState() => _SudokuTutorialScreenState();
}

class _SudokuTutorialScreenState extends ConsumerState<SudokuTutorialScreen> {
  int _currentStepIdx = 0;
  int? _selectedRow;
  int? _selectedCol;
  late List<int> _grid;
  late List<bool> _errorState;
  bool _stepCompleted = false;

  final List<TutorialStep> _steps = const [
    TutorialStep(
      title: '1. Rows & Columns',
      instruction: 'Each row and column must contain digits 1 to 4 without repetition.\n\nLook at the highlighted first row. Only one number is missing to complete the sequence [1, 2, 3, ?].',
      targetExplanation: 'Select the highlighted empty cell in Row 1 and tap "4".',
      initialGrid: [
        1, 2, 3, 0,
        3, 4, 0, 1,
        0, 1, 4, 2,
        4, 3, 1, 0,
      ],
      isGiven: [
        true, true, true, false,
        true, true, false, true,
        false, true, true, true,
        true, true, true, false,
      ],
      targetRow: 0,
      targetCol: 3,
      targetValue: 4,
    ),
    TutorialStep(
      title: '2. Box Areas',
      instruction: 'A 4x4 Sudoku board is divided into four 2x2 box areas. Each box must contain digits 1 to 4.\n\nCheck the bottom-left box. The digits [3, 4, 1] are filled, meaning only one number remains.',
      targetExplanation: 'Select the highlighted cell in the bottom-left box and tap "2" to complete it.',
      initialGrid: [
        1, 2, 3, 4,
        3, 4, 2, 1,
        0, 1, 4, 2,
        4, 3, 1, 0,
      ],
      isGiven: [
        true, true, true, true,
        true, true, true, true,
        false, true, true, true,
        true, true, true, false,
      ],
      targetRow: 2,
      targetCol: 0,
      targetValue: 2,
    ),
    TutorialStep(
      title: '3. Diagonal X-Sudoku',
      instruction: 'In Diagonal (X) Sudoku, the two main diagonals (top-left to bottom-right, and top-right to bottom-left) must also contain digits 1 to 4 without repeats.',
      targetExplanation: 'Select the bottom-right corner cell on the main diagonal and tap "3" to complete the diagonal.',
      initialGrid: [
        1, 2, 3, 4,
        3, 4, 2, 1,
        2, 1, 4, 3,
        4, 3, 1, 0,
      ],
      isGiven: [
        true, true, true, true,
        true, true, true, true,
        true, true, true, true,
        true, true, true, false,
      ],
      targetRow: 3,
      targetCol: 3,
      targetValue: 2,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStep(_currentStepIdx);
  }

  void _loadStep(int index) {
    final step = _steps[index];
    _grid = List.from(step.initialGrid);
    _errorState = List.filled(16, false);
    _selectedRow = step.targetRow;
    _selectedCol = step.targetCol;
    _stepCompleted = false;
  }

  void _onCellTap(int row, int col) {
    if (_stepCompleted) return;
    setState(() {
      _selectedRow = row;
      _selectedCol = col;
    });
  }

  void _onNumpadPress(int num) {
    if (_stepCompleted) return;
    final r = _selectedRow;
    final c = _selectedCol;
    if (r == null || c == null) return;

    final step = _steps[_currentStepIdx];
    final idx = r * 4 + c;

    if (step.isGiven[idx]) return;

    setState(() {
      _grid[idx] = num;
      if (r == step.targetRow && c == step.targetCol && num == step.targetValue) {
        _errorState[idx] = false;
        _stepCompleted = true;
        ref.read(audioServiceProvider).play(SfxType.fanfare);
      } else {
        _errorState[idx] = true;
        ref.read(audioServiceProvider).play(SfxType.swipe); // error beep
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = _steps[_currentStepIdx];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E15),
      appBar: AppBar(
        title: const Text(
          'SUDOKU ACADEMY: LEARN',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Slide instruction area
              GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.indigoAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.instruction,
                      style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.pinkAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.targetExplanation,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.pinkAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Interactive 4x4 Playground Grid
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.indigoAccent, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                        ),
                        itemCount: 16,
                        itemBuilder: (context, index) {
                          final r = index ~/ 4;
                          final c = index % 4;
                          final val = _grid[index];
                          final isGiven = step.isGiven[index];
                          final isSelected = _selectedRow == r && _selectedCol == c;
                          final isError = _errorState[index];

                          // Custom shading based on step focus
                          bool isFocusArea = false;
                          if (_currentStepIdx == 0 && r == step.targetRow) {
                            isFocusArea = true; // highlight row
                          } else if (_currentStepIdx == 1 && r >= 2 && c <= 1) {
                            isFocusArea = true; // highlight bottom-left box
                          } else if (_currentStepIdx == 2 && (r == c || r == 3 - c)) {
                            isFocusArea = true; // highlight diagonals
                          }

                          Color cellBg = Colors.transparent;
                          if (isSelected) {
                            cellBg = Colors.indigoAccent.withAlpha(100);
                          } else if (isFocusArea) {
                            cellBg = Colors.indigoAccent.withAlpha(25);
                          }

                          // Outer block borders for 2x2 divisions
                          final borderRight = c == 1;
                          final borderBottom = r == 1;

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
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: isError
                                              ? Colors.redAccent
                                              : (isGiven ? Colors.white54 : Colors.greenAccent),
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
              const SizedBox(height: 24),

              // Completed success overlay or normal actions
              if (_stepCompleted) ...[
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Correct! Well done.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                        ),
                      ),
                      if (_currentStepIdx < _steps.length - 1)
                        // ignore: unstyled_button
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentStepIdx++;
                              _loadStep(_currentStepIdx);
                            });
                          },
                          child: const Text('NEXT STEP', style: TextStyle(color: Colors.indigoAccent)),
                        )
                      else
                        // ignore: unstyled_button
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('FINISH', style: TextStyle(color: Colors.indigoAccent)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Custom 4-digit Numpad for Tutorial
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final val = index + 1;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: AnimatedScaleButton(
                          onPressed: () => _onNumpadPress(val),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.indigoAccent.withAlpha(100)),
                            ),
                            child: Center(
                              child: Text(
                                '$val',
                                style: const TextStyle(
                                  fontSize: 22,
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
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
