import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../models/sudoku_models.dart';
import '../providers/sudoku_provider.dart';
import '../services/sudoku_sync_service.dart';
import '../services/sudoku_stats_service.dart';

class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({super.key});

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen> {
  final _confettiController = ConfettiController(duration: const Duration(seconds: 4));
  final FocusNode _keyboardFocusNode = FocusNode();
  AudioPlayer? _bgMusicPlayer;
  bool _isMusicPlaying = false;
  bool _showLeaderboard = false;
  bool _showStats = false;
  List<Map<String, dynamic>> _leaderboardScores = [];
  bool _loadingLeaderboard = false;

  // Selected setup properties
  SudokuVariant _selectedVariant = SudokuVariant.standard;
  SudokuDifficulty _selectedDifficulty = SudokuDifficulty.medium;
  SudokuMode _selectedMode = SudokuMode.classic;
  
  // Stats details
  SudokuStats? _cachedStats;

  @override
  void initState() {
    super.initState();
    _bgMusicPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _bgMusicPlayer?.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _toggleBackgroundMusic() async {
    final player = _bgMusicPlayer;
    if (player == null) return;

    if (_isMusicPlaying) {
      await player.pause();
      setState(() => _isMusicPlaying = false);
    } else {
      try {
        await player.play(UrlSource('https://coderadio-admin.freecodecamp.org/radio/8010/radio.mp3'));
        await player.setVolume(0.25);
        setState(() => _isMusicPlaying = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to stream ambient music. Check internet.')),
          );
        }
      }
    }
  }

  Future<void> _loadLeaderboardData(SudokuGameState state) async {
    setState(() {
      _loadingLeaderboard = true;
      _showLeaderboard = true;
    });
    final scores = await SudokuSyncService.fetchLeaderboard(
      variant: state.variant.name,
      difficulty: state.difficulty.name,
      mode: state.mode.name,
    );
    if (mounted) {
      setState(() {
        _leaderboardScores = scores;
        _loadingLeaderboard = false;
      });
    }
  }

  Future<void> _loadStatsData() async {
    final stats = await SudokuStatsService.getStats(_selectedVariant.name, _selectedDifficulty.name);
    setState(() {
      _cachedStats = stats;
      _showStats = true;
    });
  }

  void _handleKeyboardInput(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final state = ref.read(sudokuStateProvider);
    if (state.grid.isEmpty || state.isFinished) return;

    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;
    final key = event.logicalKey;

    // Number Inputs
    int? enteredNum;
    if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) enteredNum = 1;
    if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) enteredNum = 2;
    if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) enteredNum = 3;
    if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) enteredNum = 4;
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) enteredNum = 5;
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) enteredNum = 6;
    if (size == 9) {
      if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) enteredNum = 7;
      if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) enteredNum = 8;
      if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) enteredNum = 9;
    }

    if (enteredNum != null) {
      ref.read(audioServiceProvider).play(SfxType.swipe);
      ref.read(sudokuStateProvider.notifier).enterNumber(enteredNum, '');
      return;
    }

    // Controls
    if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      ref.read(sudokuStateProvider.notifier).eraseCell();
    }
    if (key == LogicalKeyboardKey.keyN) {
      ref.read(sudokuStateProvider.notifier).toggleNotesMode();
    }
    if (key == LogicalKeyboardKey.keyH) {
      ref.read(sudokuStateProvider.notifier).useHint();
    }
    if (key == LogicalKeyboardKey.keyU) {
      if (ref.read(sudokuStateProvider.notifier).canUndo) {
        ref.read(sudokuStateProvider.notifier).undo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gameState = ref.watch(sudokuStateProvider);

    // Get theme colors
    final colors = _getThemeColors(gameState.theme, Theme.of(context).colorScheme);

    // Confetti and fanfare trigger when completed successfully
    ref.listen<SudokuGameState>(sudokuStateProvider, (prev, next) {
      if (next.isFinished && !(prev?.isFinished ?? false)) {
        final solved = next.grid.every((c) => c.currentValue == c.value);
        if (solved) {
          ref.read(audioServiceProvider).play(SfxType.fanfare);
          _confettiController.play();
        }
      }
    });

    // Request keyboard focus when in game
    if (gameState.grid.isNotEmpty && !_showLeaderboard && !_showStats) {
      _keyboardFocusNode.requestFocus();
    }

    return Theme(
      data: ThemeData(
        brightness: colors.brightness,
        scaffoldBackgroundColor: colors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: colors.primary,
          brightness: colors.brightness,
          surface: colors.surface,
        ),
      ),
      child: KeyboardListener(
        focusNode: _keyboardFocusNode,
        onKeyEvent: _handleKeyboardInput,
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.get('game_sudoku').toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/games'),
            ),
            actions: [
              // Music toggle
              IconButton(
                icon: Icon(_isMusicPlaying ? Icons.music_note : Icons.music_off),
                color: _isMusicPlaying ? colors.primary : null,
                onPressed: _toggleBackgroundMusic,
                tooltip: 'Ambient Focus Music',
              ),
              // Leaderboard toggle
              if (gameState.grid.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.emoji_events),
                  onPressed: () => _loadLeaderboardData(gameState),
                  tooltip: l10n.get('sudoku_leaderboard'),
                ),
              // Reset game
              if (gameState.grid.isNotEmpty && !gameState.isFinished)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    _showConfirmResetDialog(gameState, l10n);
                  },
                  tooltip: l10n.get('sudoku_restart'),
                ),
              // Theme selection menu
              PopupMenuButton<SudokuTheme>(
                icon: const Icon(Icons.palette_outlined),
                onSelected: (t) => ref.read(sudokuStateProvider.notifier).selectTheme(t),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: SudokuTheme.aether, child: Text('Aether (Dark Neon)')),
                  const PopupMenuItem(value: SudokuTheme.zen, child: Text('Zen (Warm Wood)')),
                  const PopupMenuItem(value: SudokuTheme.midnight, child: Text('Midnight Blue')),
                  const PopupMenuItem(value: SudokuTheme.cyberpunk, child: Text('Cyberpunk (Slime)')),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                gameState.grid.isEmpty
                    ? _buildSetupView(l10n, colors)
                    : _buildGameView(gameState, l10n, colors),
      
                // Confetti Overlay
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    colors: const [Colors.amber, Colors.blue, Colors.pink, Colors.green],
                  ),
                ),
      
                // Leaderboard Overlay
                if (_showLeaderboard) _buildLeaderboardOverlay(colors, l10n),

                // Local Stats Overlay
                if (_showStats) _buildStatsOverlay(colors, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Theme Generator Helper ---

  _SudokuThemeColors _getThemeColors(SudokuTheme theme, ColorScheme systemCs) {
    return switch (theme) {
      SudokuTheme.aether => _SudokuThemeColors(
          brightness: Brightness.dark,
          background: const Color(0xFF0D0E15),
          surface: const Color(0xFF161926),
          primary: Colors.indigoAccent.shade200,
          accent: Colors.pinkAccent,
          cellBorder: Colors.indigo.shade900,
          cellOriginal: Colors.white,
          cellUser: Colors.indigoAccent.shade100,
          cellError: Colors.redAccent,
          cellHighlight: Colors.indigoAccent.withAlpha(40),
          cellSelection: Colors.indigoAccent.withAlpha(90),
        ),
      SudokuTheme.zen => _SudokuThemeColors(
          brightness: Brightness.light,
          background: const Color(0xFFF7F4EA),
          surface: const Color(0xFFEFEAD8),
          primary: const Color(0xFF8B5A2B), // Earthy wood brown
          accent: const Color(0xFF4A752C), // Forest green
          cellBorder: const Color(0xFFD3C5A3),
          cellOriginal: const Color(0xFF3E2723),
          cellUser: const Color(0xFF8B5A2B),
          cellError: Colors.red.shade800,
          cellHighlight: const Color(0xFFE2D9BC),
          cellSelection: const Color(0xFFC7B78E),
        ),
      SudokuTheme.midnight => _SudokuThemeColors(
          brightness: Brightness.dark,
          background: const Color(0xFF050B14),
          surface: const Color(0xFF0B1528),
          primary: Colors.blueAccent.shade400,
          accent: Colors.cyanAccent,
          cellBorder: Colors.blue.shade900.withAlpha(150),
          cellOriginal: Colors.white,
          cellUser: Colors.blueAccent.shade100,
          cellError: Colors.redAccent,
          cellHighlight: Colors.blueAccent.withAlpha(30),
          cellSelection: Colors.blueAccent.withAlpha(80),
        ),
      SudokuTheme.cyberpunk => _SudokuThemeColors(
          brightness: Brightness.dark,
          background: const Color(0xFF111111),
          surface: const Color(0xFF1E1E1E),
          primary: const Color(0xFFEEFF00), // Toxic yellow
          accent: const Color(0xFF00FF66), // Toxic green
          cellBorder: const Color(0xFF333333),
          cellOriginal: Colors.white,
          cellUser: const Color(0xFFEEFF00),
          cellError: const Color(0xFFFF0055),
          cellHighlight: const Color(0xFFEEFF00).withAlpha(30),
          cellSelection: const Color(0xFFEEFF00).withAlpha(85),
        ),
    };
  }

  // --- Setup / Config View ---

  Widget _buildSetupView(AppLocalizations l10n, _SudokuThemeColors colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner/Intro Image
          GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: 24,
            child: Column(
              children: [
                Icon(Icons.grid_3x3, size: 64, color: colors.primary),
                const SizedBox(height: 12),
                Text(
                  l10n.get('game_sudoku'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.get('desc_sudoku'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily Challenge & Stats Buttons Row
          Row(
            children: [
              Expanded(
                child: AnimatedScaleButton(
                  onPressed: () {
                    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                    ref.read(sudokuStateProvider.notifier).setupDaily(
                      todayStr,
                      variant: _selectedVariant,
                      difficulty: _selectedDifficulty,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.accent, colors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.today, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.get('sudoku_daily_challenge'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedScaleButton(
                onPressed: _loadStatsData,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.primary.withAlpha(100)),
                  ),
                  child: Icon(Icons.analytics_outlined, color: colors.primary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Config Form
          Text(l10n.get('sudoku_variant'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SegmentedButton<SudokuVariant>(
            segments: [
              ButtonSegment(value: SudokuVariant.standard, label: Text(l10n.get('sudoku_variant_standard'))),
              ButtonSegment(value: SudokuVariant.diagonal, label: Text(l10n.get('sudoku_variant_diagonal'))),
              ButtonSegment(value: SudokuVariant.hyper, label: Text(l10n.get('sudoku_variant_hyper'))),
              ButtonSegment(value: SudokuVariant.mini6x6, label: Text(l10n.get('sudoku_variant_mini'))),
            ],
            selected: {_selectedVariant},
            onSelectionChanged: (set) => setState(() => _selectedVariant = set.first),
          ),
          const SizedBox(height: 20),

          Text(l10n.get('sudoku_difficulty'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SegmentedButton<SudokuDifficulty>(
            segments: [
              ButtonSegment(value: SudokuDifficulty.easy, label: Text(l10n.get('sudoku_difficulty_easy'))),
              ButtonSegment(value: SudokuDifficulty.medium, label: Text(l10n.get('sudoku_difficulty_medium'))),
              ButtonSegment(value: SudokuDifficulty.hard, label: Text(l10n.get('sudoku_difficulty_hard'))),
              ButtonSegment(value: SudokuDifficulty.expert, label: Text(l10n.get('sudoku_difficulty_expert'))),
            ],
            selected: {_selectedDifficulty},
            onSelectionChanged: (set) => setState(() => _selectedDifficulty = set.first),
          ),
          const SizedBox(height: 20),

          Text(l10n.get('sudoku_mode'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SegmentedButton<SudokuMode>(
            segments: [
              ButtonSegment(value: SudokuMode.classic, label: Text(l10n.get('sudoku_mode_classic'))),
              ButtonSegment(value: SudokuMode.zen, label: Text(l10n.get('sudoku_mode_zen'))),
              ButtonSegment(value: SudokuMode.timeAttack, label: Text(l10n.get('sudoku_mode_timeattack'))),
            ],
            selected: {_selectedMode},
            onSelectionChanged: (set) => setState(() => _selectedMode = set.first),
          ),
          const SizedBox(height: 32),

          // Start Button
          FilledButton(
            onPressed: () {
              ref.read(sudokuStateProvider.notifier).setupMatch(
                variant: _selectedVariant,
                difficulty: _selectedDifficulty,
                mode: _selectedMode,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.brightness == Brightness.dark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('START GAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  // --- Active Game Board & Interface ---

  Widget _buildGameView(SudokuGameState state, AppLocalizations l10n, _SudokuThemeColors colors) {
    if (state.isFinished) {
      return _buildFinishedView(state, l10n, colors);
    }

    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Metadata Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.variant.name.toUpperCase()} · ${state.difficulty.name.toUpperCase()}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.get('sudoku_mode')}: ${state.mode.name.toUpperCase()}',
                    style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Timer
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(state.timeSeconds),
                    style: const TextStyle(fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              // Mistakes Indicator
              if (state.mode != SudokuMode.zen)
                Text(
                  '${l10n.get('sudoku_mistakes')}: ${state.mistakes}/${state.maxMistakes}',
                  style: TextStyle(
                    fontSize: 14,
                    color: state.mistakes > 0 ? colors.cellError : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Sudoku Grid
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: colors.primary, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: size,
                        ),
                        itemCount: size * size,
                        itemBuilder: (context, index) {
                          final r = index ~/ size;
                          final c = index % size;
                          final cell = state.grid[index];
                          return _buildCell(cell, r, c, size, state, colors);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Controls (Undo, Notes, Erase, Hint)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.undo,
                label: l10n.get('sudoku_undo'),
                color: colors.primary,
                onPressed: ref.read(sudokuStateProvider.notifier).canUndo
                    ? () => ref.read(sudokuStateProvider.notifier).undo()
                    : null,
              ),
              _buildControlButton(
                icon: state.notesMode ? Icons.edit : Icons.edit_outlined,
                label: l10n.get('sudoku_notes'),
                color: state.notesMode ? colors.accent : colors.primary,
                onPressed: () => ref.read(sudokuStateProvider.notifier).toggleNotesMode(),
              ),
              _buildControlButton(
                icon: Icons.delete_outline,
                label: l10n.get('sudoku_erase'),
                color: colors.primary,
                onPressed: () => ref.read(sudokuStateProvider.notifier).eraseCell(),
              ),
              _buildControlButton(
                icon: Icons.lightbulb_outline,
                label: l10n.get('sudoku_hint'),
                color: colors.primary,
                onPressed: () {
                  ref.read(sudokuStateProvider.notifier).useHint();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Numerical Numpad
          _buildNumpad(size, state, colors),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- Cell Rendering ---

  Widget _buildCell(
    SudokuCell cell,
    int r,
    int c,
    int size,
    SudokuGameState state,
    _SudokuThemeColors colors,
  ) {
    final isSelected = state.selectedRow == r && state.selectedCol == c;

    // Check if cell is in the same row or column or block as selected to highlight
    bool isHighlighted = false;
    if (state.selectedRow != null && state.selectedCol != null) {
      if (state.selectedRow == r || state.selectedCol == c) {
        isHighlighted = true;
      } else {
        // Block check
        if (size == 6) {
          if ((state.selectedRow! ~/ 2 == r ~/ 2) && (state.selectedCol! ~/ 3 == c ~/ 3)) {
            isHighlighted = true;
          }
        } else {
          if ((state.selectedRow! ~/ 3 == r ~/ 3) && (state.selectedCol! ~/ 3 == c ~/ 3)) {
            isHighlighted = true;
          }
        }
      }
    }

    // Highlight all matching values currently on the board
    final selectedCellIndex = (state.selectedRow != null && state.selectedCol != null)
        ? state.selectedRow! * size + state.selectedCol!
        : null;
    final selectedVal = selectedCellIndex != null ? state.grid[selectedCellIndex].currentValue : 0;
    final isMatchingValue = selectedVal > 0 && cell.currentValue == selectedVal;

    // Base Borders
    final borderRight = (c == 2 || c == 5) && size == 9 || (c == 2 && size == 6);
    final borderBottom = (r == 2 || r == 5) && size == 9 || (r == 1 || r == 3) && size == 6;

    // Sudoku X Diagonal Highlight
    bool isDiagonal = false;
    if (state.variant == SudokuVariant.diagonal) {
      if (r == c || r == size - 1 - c) {
        isDiagonal = true;
      }
    }

    // Windoku (Hyper Sudoku) Shading
    bool isWindoku = false;
    if (state.variant == SudokuVariant.hyper) {
      if ((r >= 1 && r <= 3 || r >= 5 && r <= 7) && (c >= 1 && c <= 3 || c >= 5 && c <= 7)) {
        isWindoku = true;
      }
    }

    Color cellBg = Colors.transparent;
    if (isSelected) {
      cellBg = colors.cellSelection;
    } else if (isMatchingValue) {
      cellBg = colors.cellHighlight.withAlpha(90);
    } else if (isHighlighted) {
      cellBg = colors.cellHighlight;
    } else if (isWindoku) {
      cellBg = colors.primary.withAlpha(20);
    }

    return GestureDetector(
      onTap: () => ref.read(sudokuStateProvider.notifier).selectCell(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          border: Border(
            top: BorderSide(color: colors.cellBorder, width: 0.5),
            left: BorderSide(color: colors.cellBorder, width: 0.5),
            right: BorderSide(
              color: borderRight ? colors.primary : colors.cellBorder,
              width: borderRight ? 2.5 : 0.5,
            ),
            bottom: BorderSide(
              color: borderBottom ? colors.primary : colors.cellBorder,
              width: borderBottom ? 2.5 : 0.5,
            ),
          ),
        ),
        child: Stack(
          children: [
            // Sudoku X decorative diagonal indicators
            if (isDiagonal && !isSelected && !isHighlighted && !isMatchingValue)
              Positioned.fill(
                child: CustomPaint(
                  painter: _DiagonalPainter(color: colors.primary.withAlpha(40)),
                ),
              ),
            
            // Value display
            Center(
              child: cell.currentValue > 0
                  ? Text(
                      '${cell.currentValue}',
                      style: TextStyle(
                        fontSize: size == 6 ? 26 : 22,
                        fontWeight: FontWeight.bold,
                        color: cell.isOriginal
                            ? colors.cellOriginal
                            : (cell.isError ? colors.cellError : colors.cellUser),
                      ),
                    )
                  : cell.notes.isNotEmpty
                      ? _buildNotesGrid(cell.notes, size, colors)
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesGrid(Set<int> notes, int size, _SudokuThemeColors colors) {
    final list = List.generate(size == 6 ? 6 : 9, (i) => i + 1);
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size == 6 ? 3 : 3,
        ),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final n = list[index];
          final hasNote = notes.contains(n);
          return Center(
            child: Text(
              hasNote ? '$n' : '',
              style: TextStyle(
                fontSize: size == 6 ? 8 : 7,
                color: colors.primary.withAlpha(180),
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Numpad Bar ---

  Widget _buildNumpad(int size, SudokuGameState state, _SudokuThemeColors colors) {
    // Count placed values to show completion indicator
    final counts = Map<int, int>.fromIterable(
      List.generate(size, (i) => i + 1),
      key: (i) => i as int,
      value: (_) => 0,
    );

    for (final cell in state.grid) {
      if (cell.currentValue > 0 && !cell.isError) {
        counts[cell.currentValue] = (counts[cell.currentValue] ?? 0) + 1;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(size, (index) {
        final val = index + 1;
        final completed = counts[val] == size;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: AnimatedScaleButton(
              onPressed: completed
                  ? null
                  : () {
                      ref.read(audioServiceProvider).play(SfxType.swipe);
                      ref.read(sudokuStateProvider.notifier).enterNumber(val, '');
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: completed ? Colors.transparent : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: completed ? Colors.transparent : colors.primary.withAlpha(100),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$val',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: completed ? Colors.grey.withAlpha(80) : colors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return AnimatedScaleButton(
      onPressed: onPressed,
      child: Column(
        children: [
          Icon(icon, color: onPressed == null ? Colors.grey : color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: onPressed == null ? Colors.grey : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- End of Game Finished Screen ---

  Widget _buildFinishedView(SudokuGameState state, AppLocalizations l10n, _SudokuThemeColors colors) {
    final solved = state.grid.every((c) => c.currentValue == c.value);

    return Center(
      child: GlassContainer(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              solved ? Icons.emoji_events : Icons.heart_broken_outlined,
              size: 72,
              color: solved ? colors.primary : colors.cellError,
            ),
            const SizedBox(height: 16),
            Text(
              solved ? l10n.get('sudoku_congrats') : l10n.get('sudoku_game_over'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              solved
                  ? l10n.getWith('sudoku_solved_in', [_formatTime(state.timeSeconds)])
                  : l10n.get('sudoku_game_over_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Reset grid to setup/empty state
                    ref.read(sudokuStateProvider.notifier).loadState(
                          const SudokuGameState(grid: [], difficulty: SudokuDifficulty.medium, variant: SudokuVariant.standard, mode: SudokuMode.classic, theme: SudokuTheme.aether),
                        );
                  },
                  child: Text(l10n.get('back')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (state.isDailyChallenge && state.dailyDate != null) {
                      ref.read(sudokuStateProvider.notifier).setupDaily(
                            state.dailyDate!,
                            variant: state.variant,
                            difficulty: state.difficulty,
                          );
                    } else {
                      ref.read(sudokuStateProvider.notifier).setupMatch(
                            variant: state.variant,
                            difficulty: state.difficulty,
                            mode: state.mode,
                          );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.brightness == Brightness.dark ? Colors.black : Colors.white,
                  ),
                  child: Text(l10n.get('sudoku_restart')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Leaderboards Screen Overlay ---

  Widget _buildLeaderboardOverlay(_SudokuThemeColors colors, AppLocalizations l10n) {
    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: GlassContainer(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.get('sudoku_leaderboard'),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showLeaderboard = false),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              if (_loadingLeaderboard)
                const Center(child: CircularProgressIndicator())
              else if (_leaderboardScores.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text(
                    'No scores recorded yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _leaderboardScores.length,
                    itemBuilder: (context, index) {
                      final item = _leaderboardScores[index];
                      final name = item['playerName'] ?? 'Anonymous';
                      final seconds = item['timeSeconds'] as int;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colors.primary.withAlpha(50),
                          child: Text('${index + 1}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(
                          _formatTime(seconds),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Local Stats Overlay ---

  Widget _buildStatsOverlay(_SudokuThemeColors colors, AppLocalizations l10n) {
    final stats = _cachedStats ?? SudokuStats();
    final winRate = stats.gamesPlayed > 0 ? (stats.gamesWon / stats.gamesPlayed * 100).toStringAsFixed(0) : '0';

    return Container(
      color: Colors.black.withAlpha(200),
      child: Center(
        child: GlassContainer(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${l10n.get('sudoku_stats')} (${_selectedVariant.name.toUpperCase()})',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _showStats = false),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              
              // Stats Grid Layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(l10n.get('sudoku_stats_played'), '${stats.gamesPlayed}', colors),
                  _buildStatCard(l10n.get('sudoku_stats_won'), '${stats.gamesWon}', colors),
                  _buildStatCard(l10n.get('sudoku_stats_win_rate'), '$winRate%', colors),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(l10n.get('sudoku_stats_best_time'), _formatTime(stats.bestTimeSeconds), colors),
                  _buildStatCard(l10n.get('sudoku_stats_avg_time'), _formatTime(stats.averageTimeSeconds), colors),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(l10n.get('sudoku_stats_streak'), '${stats.currentStreak}', colors),
                  _buildStatCard(l10n.get('sudoku_stats_longest_streak'), '${stats.longestStreak}', colors),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, _SudokuThemeColors colors) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: colors.accent,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // --- Util / Formatting Functions ---

  String _formatTime(int totalSeconds) {
    if (totalSeconds == 0) return '--:--';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showConfirmResetDialog(SudokuGameState state, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('game_reset')),
        content: Text(l10n.get('game_reset_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (state.isDailyChallenge && state.dailyDate != null) {
                ref.read(sudokuStateProvider.notifier).setupDaily(
                      state.dailyDate!,
                      variant: state.variant,
                      difficulty: state.difficulty,
                    );
              } else {
                ref.read(sudokuStateProvider.notifier).setupMatch(
                      variant: state.variant,
                      difficulty: state.difficulty,
                      mode: state.mode,
                    );
              }
            },
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
  }
}

class _SudokuThemeColors {
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color cellBorder;
  final Color cellOriginal;
  final Color cellUser;
  final Color cellError;
  final Color cellHighlight;
  final Color cellSelection;

  _SudokuThemeColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.cellBorder,
    required this.cellOriginal,
    required this.cellUser,
    required this.cellError,
    required this.cellHighlight,
    required this.cellSelection,
  });
}

class _DiagonalPainter extends CustomPainter {
  final Color color;

  _DiagonalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
