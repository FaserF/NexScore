import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../shared/widgets/custom_confetti.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../../core/theme/widgets/animated_scale_button.dart';
import '../../../../core/providers/audio_provider.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../core/providers/persistence_provider.dart';
import '../../../../core/multiplayer/providers/multiplayer_provider.dart';
import '../../../../core/multiplayer/models/lobby.dart';
import '../models/sudoku_models.dart';
import '../providers/sudoku_provider.dart';
import '../services/sudoku_sync_service.dart';
import '../services/sudoku_stats_service.dart';
import '../services/sudoku_share_service.dart';

class SudokuScreen extends ConsumerStatefulWidget {
  const SudokuScreen({super.key});

  @override
  ConsumerState<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends ConsumerState<SudokuScreen> {
  final _confettiController = ConfettiController(duration: const Duration(seconds: 4));
  final FocusNode _keyboardFocusNode = FocusNode();
  AudioPlayer? _bgMusicPlayer;
  AudioPlayer? _sfxPlayer;
  bool _isMusicPlaying = false;
  bool _showLeaderboard = false;
  bool _showStats = false;
  List<Map<String, dynamic>> _leaderboardScores = [];
  bool _loadingLeaderboard = false;

  // Visual Completions & Flashing Indicators
  final Set<int> _completedRows = {};
  final Set<int> _completedCols = {};
  final Set<int> _completedBoxes = {};
  Set<int> _flashingCells = {};

  // Selected setup properties
  SudokuVariant _selectedVariant = SudokuVariant.standard;
  SudokuDifficulty _selectedDifficulty = SudokuDifficulty.medium;
  SudokuMode _selectedMode = SudokuMode.classic;
  bool _isVsBotsEnabled = false;
  String _botDifficulty = 'medium';
  
  // Stats details
  SudokuStats? _cachedStats;

  @override
  void initState() {
    super.initState();
    _bgMusicPlayer = AudioPlayer();
    _sfxPlayer = AudioPlayer();

    // Check for auto-saved game
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final lobby = ref.read(currentLobbyProvider);
      if (lobby != null) {
        // If already inside multiplayer lobby, don't trigger local resumption
        return;
      }
      
      final service = ref.read(persistenceServiceProvider);
      final savedStateMap = await service.loadGameState('sudoku');
      if (savedStateMap != null && mounted) {
        _showResumeDialog(savedStateMap);
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _bgMusicPlayer?.dispose();
    _sfxPlayer?.dispose();
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
        await player.play(UrlSource('https://coderadio-relay-nyc.freecodecamp.org/radio/8010/radio.mp3'));
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

  Future<void> _playMelodicSfx(int num) async {
    final player = _sfxPlayer;
    if (player == null) return;

    final pitchShift = switch (num) {
      1 => 1.0,
      2 => 1.122,
      3 => 1.260,
      4 => 1.335,
      5 => 1.498,
      6 => 1.682,
      7 => 1.888,
      8 => 2.0,
      9 => 2.245,
      _ => 1.0,
    };

    try {
      await player.setPlaybackRate(pitchShift);
      await player.play(AssetSource('audio/beep1.mp3'));
    } catch (e) {
      // silent fail
    }
  }

  void _checkGridCompletions(List<SudokuCell> grid, int size) {
    List<int> newCompletedRows = [];
    List<int> newCompletedCols = [];
    List<int> newCompletedBoxes = [];

    // Check rows
    for (int r = 0; r < size; r++) {
      bool rowCompleted = true;
      for (int c = 0; c < size; c++) {
        if (grid[r * size + c].currentValue == 0) {
          rowCompleted = false;
          break;
        }
      }
      if (rowCompleted && !_completedRows.contains(r)) {
        newCompletedRows.add(r);
      }
    }

    // Check cols
    for (int c = 0; c < size; c++) {
      bool colCompleted = true;
      for (int r = 0; r < size; r++) {
        if (grid[r * size + c].currentValue == 0) {
          colCompleted = false;
          break;
        }
      }
      if (colCompleted && !_completedCols.contains(c)) {
        newCompletedCols.add(c);
      }
    }

    // Check boxes
    final boxRows = size == 6 ? 2 : 3;
    final boxCols = size == 6 ? 3 : 3;
    final numBoxes = size == 6 ? 6 : 9;
    
    for (int b = 0; b < numBoxes; b++) {
      final startRow = (b ~/ (size ~/ boxRows)) * boxRows;
      final startCol = (b % (size ~/ boxRows)) * boxCols;
      
      bool boxCompleted = true;
      for (int r = startRow; r < startRow + boxRows; r++) {
        for (int c = startCol; c < startCol + boxCols; c++) {
          if (grid[r * size + c].currentValue == 0) {
            boxCompleted = false;
            break;
          }
        }
      }
      if (boxCompleted && !_completedBoxes.contains(b)) {
        newCompletedBoxes.add(b);
      }
    }

    if (newCompletedRows.isNotEmpty || newCompletedCols.isNotEmpty || newCompletedBoxes.isNotEmpty) {
      final flashing = <int>{};
      for (final r in newCompletedRows) {
        _completedRows.add(r);
        for (int c = 0; c < size; c++) {
          flashing.add(r * size + c);
        }
      }
      for (final c in newCompletedCols) {
        _completedCols.add(c);
        for (int r = 0; r < size; r++) {
          flashing.add(r * size + c);
        }
      }
      for (final b in newCompletedBoxes) {
        _completedBoxes.add(b);
        final startRow = (b ~/ (size ~/ boxRows)) * boxRows;
        final startCol = (b % (size ~/ boxRows)) * boxCols;
        for (int r = startRow; r < startRow + boxRows; r++) {
          for (int c = startCol; c < startCol + boxCols; c++) {
            flashing.add(r * size + c);
          }
        }
      }

      setState(() {
        _flashingCells = flashing;
      });

      ref.read(audioServiceProvider).play(SfxType.swipe);

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _flashingCells.clear();
          });
        }
      });
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
    if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) enteredNum = 6;
    if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) enteredNum = 6;
    if (size == 9) {
      if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) enteredNum = 7;
      if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) enteredNum = 8;
      if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) enteredNum = 9;
    }

    if (enteredNum != null) {
      _playMelodicSfx(enteredNum);
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
    final completedLevelsAsync = ref.watch(completedCampaignLevelsProvider);

    // Get theme colors
    final colors = _getThemeColors(gameState.theme, Theme.of(context).colorScheme);

    // Listen for multiplayer lobby closure
    ref.listen<Lobby?>(currentLobbyProvider, (previous, next) {
      if (gameState.isMultiplayer && next == null && mounted) {
        final reason = ref.read(multiplayerServiceProvider).lastCloseReason;
        final isHostDisconnected = reason == 'host_disconnected';
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(isHostDisconnected
                ? l10n.get('multiplayer_host_disconnected_title')
                : l10n.get('multiplayer_lobby_closed_title')),
            content: Text(isHostDisconnected
                ? l10n.get('multiplayer_host_disconnected_body')
                : l10n.get('multiplayer_lobby_closed_body')),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    context.go('/games');
                  }
                },
                child: Text(l10n.get('ok')),
              ),
            ],
          ),
        );
      }
    });

    // Confetti, fanfare, and grid checks trigger when state updates
    ref.listen<SudokuGameState>(sudokuStateProvider, (prev, next) {
      if (next.grid.isNotEmpty && prev != null && next.grid.length == prev.grid.length) {
        final size = next.variant == SudokuVariant.mini6x6 ? 6 : 9;
        _checkGridCompletions(next.grid, size);
      }

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

    final canPop = !(gameState.grid.isNotEmpty && !gameState.isFinished);

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
        child: PopScope(
          canPop: canPop,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldLeave = await _showExitWarningDialog(context, l10n);
            if (shouldLeave && context.mounted) {
              ref.read(persistenceServiceProvider).clearGameState('sudoku');
              ref.read(sudokuStateProvider.notifier).loadState(
                    const SudokuGameState(
                      grid: [],
                      difficulty: SudokuDifficulty.medium,
                      variant: SudokuVariant.standard,
                      mode: SudokuMode.classic,
                      theme: SudokuTheme.aether,
                    ),
                  );
              ref.read(activeGameIdProvider.notifier).state = null;
              context.go('/games');
            }
          },
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
                onPressed: () async {
                  if (gameState.grid.isNotEmpty && !gameState.isFinished) {
                    final shouldLeave = await _showExitWarningDialog(context, l10n);
                    if (shouldLeave && context.mounted) {
                      ref.read(persistenceServiceProvider).clearGameState('sudoku');
                      ref.read(sudokuStateProvider.notifier).loadState(
                            const SudokuGameState(
                              grid: [],
                              difficulty: SudokuDifficulty.medium,
                              variant: SudokuVariant.standard,
                              mode: SudokuMode.classic,
                              theme: SudokuTheme.aether,
                            ),
                          );
                      ref.read(activeGameIdProvider.notifier).state = null;
                      context.go('/games');
                    }
                  } else {
                    context.go('/games');
                  }
                },
              ),
              actions: [
                // Share action (Parity: Icons.share)
                if (gameState.grid.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () {
                      final shareCode = SudokuShareService.exportToCode(gameState.grid, gameState.variant);
                      Clipboard.setData(ClipboardData(text: shareCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Puzzle share code copied to clipboard!')),
                      );
                    },
                    tooltip: 'Share Puzzle Code',
                  ),
                // Settings action (Parity: Icons.settings)
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    _showSettingsDialog();
                  },
                  tooltip: 'Settings',
                ),
                // Music toggle
                IconButton(
                  icon: Icon(_isMusicPlaying ? Icons.music_note : Icons.music_off),
                  color: _isMusicPlaying ? colors.primary : null,
                  onPressed: _toggleBackgroundMusic,
                  tooltip: 'Ambient Focus Music',
                ),
                // Leaderboard toggle
                if (gameState.grid.isNotEmpty && !gameState.isMultiplayer)
                  IconButton(
                    icon: const Icon(Icons.leaderboard),
                    onPressed: () => _loadLeaderboardData(gameState),
                    tooltip: l10n.get('sudoku_leaderboard'),
                  ),
                // Reset game
                if (gameState.grid.isNotEmpty && !gameState.isFinished && !gameState.isMultiplayer)
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
                      ? _buildSetupView(l10n, colors, completedLevelsAsync)
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
      ),
    );
  }

  Future<bool> _showExitWarningDialog(BuildContext context, AppLocalizations l10n) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('game_exit_warning_title')),
        content: Text(l10n.get('game_exit_warning_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.get('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // --- Resumption Flow Popup ---

  void _showResumeDialog(Map<String, dynamic> savedMap) {
    final l10n = AppLocalizations.of(context);
    final savedState = SudokuGameState.fromMap(savedMap);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.get('resume_game_title')),
        content: Text(
          '${l10n.getWith('resume_game_desc', [l10n.get('game_sudoku')])}\n(${savedState.variant.name.toUpperCase()} · ${savedState.difficulty.name.toUpperCase()})',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(persistenceServiceProvider).clearGameState('sudoku');
              ref.read(sudokuStateProvider.notifier).loadState(
                    const SudokuGameState(
                      grid: [],
                      difficulty: SudokuDifficulty.medium,
                      variant: SudokuVariant.standard,
                      mode: SudokuMode.classic,
                      theme: SudokuTheme.aether,
                    ),
                  );
              ref.read(activeGameIdProvider.notifier).state = null;
            },
            child: Text(l10n.get('discard')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(sudokuStateProvider.notifier).loadState(savedState);
              // Register current active game ID to enable auto-saving
              ref.read(activeGameIdProvider.notifier).state = 'sudoku';
            },
            child: Text(l10n.get('resume')),
          ),
        ],
      ),
    );
  }

  // --- Setup / Config View ---

  Widget _buildSetupView(AppLocalizations l10n, _SudokuThemeColors colors, AsyncValue<Set<int>> completedLevelsAsync) {
    final lobby = ref.watch(currentLobbyProvider);
    final isHost = ref.watch(isHostProvider);

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

          // Multiplayer Lobby Connection Bar
          if (lobby != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.accent.withAlpha(40),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.accent),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hub, color: colors.accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Connected: Room ${lobby.id} (${lobby.users.length} Players)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: colors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (lobby == null) ...[
            // Daily Challenge & Stats Buttons Row
            Row(
              children: [
                Expanded(
                  child: AnimatedScaleButton(
                    onPressed: () {
                      ref.read(activeGameIdProvider.notifier).state = 'sudoku';
                      
                      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
                      ref.read(sudokuStateProvider.notifier).setupDaily(
                        todayStr,
                        variant: _selectedVariant,
                        difficulty: _selectedDifficulty,
                      );
                      
                      _completedRows.clear();
                      _completedCols.clear();
                      _completedBoxes.clear();
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
            
            // Sudoku Academy Card
            completedLevelsAsync.when(
              data: (completedSet) {
                final completedCount = completedSet.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: AnimatedScaleButton(
                    onPressed: () => context.push('/games/sudoku/campaign'),
                    child: GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.school, color: colors.accent, size: 24),
                                  const SizedBox(width: 10),
                                  Text(
                                    'SUDOKU ACADEMY',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: colors.primary,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colors.accent.withAlpha(50),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$completedCount / 20',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Embark on a progressive 20-level logic mastery campaign. Solve custom rulesets and beat targeted time benchmarks.',
                            style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: completedCount / 20.0,
                            backgroundColor: Colors.grey.withAlpha(40),
                            color: colors.accent,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),

            // How to Play / Tutorial Card
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: AnimatedScaleButton(
                onPressed: () => context.push('/games/sudoku/tutorial'),
                child: GlassContainer(
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, color: colors.accent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOW TO PLAY / TUTORIAL',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'New to Sudoku or want to learn the variants? Play our quick interactive guide.',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.primary),
                    ],
                  ),
                ),
              ),
            ),

            // Create Custom Puzzle & Import Code Row
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedScaleButton(
                      onPressed: () => context.push('/games/sudoku/create'),
                      child: GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_box_outlined, color: colors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text('CREATE PUZZLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedScaleButton(
                      onPressed: () => _showImportDialog(context, colors, l10n),
                      child: GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.file_download_outlined, color: colors.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text('IMPORT CODE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

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
          if (lobby == null) ...[
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
            const SizedBox(height: 20),

            // Vs Bots Toggle and Difficulty
            SwitchListTile(
              title: const Text('VS BOTS PRACTICE MODE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: const Text('Compete against a simulated AI on the board'),
              value: _isVsBotsEnabled,
              activeThumbColor: colors.primary,
              onChanged: (val) => setState(() => _isVsBotsEnabled = val),
            ),
            if (_isVsBotsEnabled) ...[
              const SizedBox(height: 8),
              const Text('BOT DIFFICULTY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'easy', label: Text('Easy')),
                  ButtonSegment(value: 'medium', label: Text('Medium')),
                  ButtonSegment(value: 'expert', label: Text('Expert')),
                ],
                selected: {_botDifficulty},
                onSelectionChanged: (set) => setState(() => _botDifficulty = set.first),
              ),
            ],
            const SizedBox(height: 32),
          ],

          // Start Button
          if (lobby == null || isHost)
            FilledButton(
              onPressed: () {
                ref.read(activeGameIdProvider.notifier).state = 'sudoku';

                ref.read(sudokuStateProvider.notifier).setupMatch(
                  variant: _selectedVariant,
                  difficulty: _selectedDifficulty,
                  mode: lobby != null ? SudokuMode.classic : _selectedMode,
                  isMultiplayer: lobby != null,
                  isVsBots: lobby == null && _isVsBotsEnabled,
                  botDifficulty: lobby == null && _isVsBotsEnabled ? _botDifficulty : null,
                );

                _completedRows.clear();
                _completedCols.clear();
                _completedBoxes.clear();
              },
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.brightness == Brightness.dark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                lobby != null ? 'START MULTIPLAYER SUDOKU' : 'START GAME',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Waiting for host to generate board...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
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
          // Scoreboard (Multiplayer or Vs Bots)
          if (state.isMultiplayer || state.isVsBots) _buildMultiplayerScoreboard(state, colors),

          // Metadata Bar
          if (!state.isMultiplayer)
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
                    state.maxMistakes >= 9999
                        ? '${l10n.get('sudoku_mistakes')}: ${state.mistakes}/∞'
                        : '${l10n.get('sudoku_mistakes')}: ${state.mistakes}/${state.maxMistakes}',
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
                          return _buildCell(cell, r, c, size, state, colors, index);
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
                onPressed: (!state.isMultiplayer && ref.read(sudokuStateProvider.notifier).canUndo)
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
                onPressed: !state.isMultiplayer ? () => ref.read(sudokuStateProvider.notifier).eraseCell() : null,
              ),
              _buildControlButton(
                icon: Icons.lightbulb_outline,
                label: l10n.get('sudoku_hint'),
                color: colors.primary,
                onPressed: !state.isMultiplayer ? () => ref.read(sudokuStateProvider.notifier).useHint() : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logical Hint Explanation Card
          if (state.analyzerExplanation != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GlassContainer(
                borderRadius: 16,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.get('sudoku_analyzer_explanation'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.analyzerExplanation!,
                            style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Numerical Numpad
          _buildNumpad(size, state, colors),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- Multiplayer Header ---

  Widget _buildMultiplayerScoreboard(SudokuGameState state, _SudokuThemeColors colors) {
    if (state.isVsBots) {
      final botName = state.botDifficulty == 'easy'
          ? 'LogicBot'
          : (state.botDifficulty == 'medium' ? 'GridMaster' : 'QuantumSolver');
      
      final playerStats = {
        'uid': 'player',
        'name': 'You',
        'color': 0xFF00E5FF,
      };
      
      final botStats = {
        'uid': botName,
        'name': botName,
        'color': 0xFFFF0055,
      };

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [playerStats, botStats].map((u) {
            final score = state.playerScores[u['uid'] as String] ?? 0;
            final mistakes = state.playerMistakes[u['uid'] as String] ?? 0;
            final colorVal = u['color'] as int;

            return Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(colorVal),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      u['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pts: $score · Err: $mistakes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(colorVal),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    final lobby = ref.watch(currentLobbyProvider);
    if (lobby == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: lobby.users.values.map((u) {
          final score = state.playerScores[u.uid] ?? 0;
          final mistakes = state.playerMistakes[u.uid] ?? 0;
          final isHostPlayer = u.isHost;
          final avatarColorVal = isHostPlayer ? 0xFF00E5FF : 0xFFFF0055;

          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Color(avatarColorVal),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    u.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pts: $score · Err: $mistakes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(avatarColorVal),
                ),
              ),
            ],
          );
        }).toList(),
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
    int index,
  ) {
    final isSelected = state.selectedRow == r && state.selectedCol == c;

    bool isHighlighted = false;
    if (state.selectedRow != null && state.selectedCol != null) {
      if (state.selectedRow == r || state.selectedCol == c) {
        isHighlighted = true;
      } else {
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

    final selectedCellIndex = (state.selectedRow != null && state.selectedCol != null)
        ? state.selectedRow! * size + state.selectedCol!
        : null;
    final selectedCell = selectedCellIndex != null ? state.grid[selectedCellIndex] : null;
    final selectedVal = selectedCell?.currentValue ?? 0;
    final isMatchingValue = selectedVal > 0 && cell.currentValue == selectedVal;

    // Check if this cell has a conflict with the currently selected cell
    bool hasValueConflict = false;
    if (selectedVal > 0 && !cell.isOriginal && cell.currentValue == selectedVal && selectedCellIndex != index) {
      final isSameRow = (r == state.selectedRow);
      final isSameCol = (c == state.selectedCol);
      bool isSameBlock = false;
      if (size == 6) {
        isSameBlock = (r ~/ 2 == state.selectedRow! ~/ 2) && (c ~/ 3 == state.selectedCol! ~/ 3);
      } else {
        isSameBlock = (r ~/ 3 == state.selectedRow! ~/ 3) && (c ~/ 3 == state.selectedCol! ~/ 3);
      }
      if (isSameRow || isSameCol || isSameBlock) {
        hasValueConflict = true;
      }
    }

    final borderRight = (c == 2 || c == 5) && size == 9 || (c == 2 && size == 6);
    final borderBottom = (r == 2 || r == 5) && size == 9 || (r == 1 || r == 3) && size == 6;

    bool isDiagonal = false;
    if (state.variant == SudokuVariant.diagonal) {
      if (r == c || r == size - 1 - c) {
        isDiagonal = true;
      }
    }

    bool isWindoku = false;
    if (state.variant == SudokuVariant.hyper) {
      if ((r >= 1 && r <= 3 || r >= 5 && r <= 7) && (c >= 1 && c <= 3 || c >= 5 && c <= 7)) {
        isWindoku = true;
      }
    }

    final isFlashing = _flashingCells.contains(index);

    // Coloring multiplayer inputs
    Color? playerColor;
    if ((state.isMultiplayer || state.isVsBots) && cell.filledByColor != null) {
      final colorCode = int.tryParse(cell.filledByColor!) ?? 0xFFFF0055;
      playerColor = Color(colorCode).withAlpha(35);
    }

    Color cellBg = Colors.transparent;
    if (isFlashing) {
      cellBg = colors.accent.withAlpha(150);
    } else if (isSelected) {
      cellBg = colors.cellSelection;
    } else if (hasValueConflict) {
      cellBg = colors.cellError.withAlpha(50);
    } else if (playerColor != null) {
      cellBg = playerColor;
    } else if (isMatchingValue) {
      cellBg = colors.cellHighlight.withAlpha(90);
    } else if (isHighlighted) {
      cellBg = colors.cellHighlight;
    } else if (isWindoku) {
      cellBg = colors.primary.withAlpha(20);
    }

    // Color code representing who filled it in competitive mode
    Color textCol = cell.isOriginal
        ? colors.cellOriginal
        : (cell.isError ? colors.cellError : colors.cellUser);
    
    if ((state.isMultiplayer || state.isVsBots) && cell.filledByColor != null) {
      final colorCode = int.tryParse(cell.filledByColor!) ?? 0xFFFF0055;
      textCol = Color(colorCode);
    }

    return GestureDetector(
      onTap: () => ref.read(sudokuStateProvider.notifier).selectCell(r, c),
      child: Container(
        decoration: BoxDecoration(
          color: cellBg,
          border: state.highlightedHintCell == index
              ? Border.all(color: Colors.amberAccent, width: 3.0)
              : Border(
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
            if (isDiagonal && !isSelected && !isHighlighted && !isMatchingValue && playerColor == null)
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
                        color: textCol,
                      ),
                    )
                  : cell.notes.isNotEmpty
                      ? _buildNotesGrid(cell.notes, size, colors)
                      : null,
            ),

            // Mini player indicator label in top-left
            if ((state.isMultiplayer || state.isVsBots) && cell.filledByName != null)
              Positioned(
                top: 1,
                left: 2,
                child: Text(
                  cell.filledByName!.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: textCol.withAlpha(150),
                  ),
                ),
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
    final counts = <int, int>{
      for (int i = 1; i <= size; i++) i: 0,
    };

    for (final cell in state.grid) {
      if (cell.currentValue > 0 && !cell.isError) {
        counts[cell.currentValue] = (counts[cell.currentValue] ?? 0) + 1;
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(size, (index) {
        final val = index + 1;
        final count = counts[val] ?? 0;
        final remaining = size - count;
        final completed = remaining <= 0;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: AnimatedScaleButton(
              onPressed: completed
                  ? null
                  : () {
                      _playMelodicSfx(val);
                      ref.read(sudokuStateProvider.notifier).enterNumber(val, '');
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: completed ? Colors.transparent : colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: completed ? Colors.transparent : colors.primary.withAlpha(100),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$val',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: completed ? Colors.grey.withAlpha(80) : colors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      completed ? '✓' : '$remaining',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: completed ? Colors.green.withAlpha(150) : colors.primary.withAlpha(150),
                      ),
                    ),
                  ],
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

    // Find winner in multiplayer match
    String? multiWinner;
    if (state.isMultiplayer) {
      final lobby = ref.read(currentLobbyProvider);
      if (lobby != null) {
        String bestUid = lobby.users.keys.first;
        int bestScore = -9999;
        for (final entry in state.playerScores.entries) {
          if (entry.value > bestScore) {
            bestScore = entry.value;
            bestUid = entry.key;
          }
        }
        multiWinner = lobby.users[bestUid]?.name ?? 'Anonymous';
      }
    } else if (state.isVsBots) {
      final botName = state.botDifficulty == 'easy'
          ? 'LogicBot'
          : (state.botDifficulty == 'medium' ? 'GridMaster' : 'QuantumSolver');
      final playerScore = state.playerScores['player'] ?? 0;
      final botScore = state.playerScores[botName] ?? 0;
      if (playerScore > botScore) {
        multiWinner = '${l10n.get('winner_you')} ($playerScore ${l10n.get('winner_vs')} $botScore)';
      } else if (botScore > playerScore) {
        multiWinner = '$botName ($botScore ${l10n.get('winner_vs')} $playerScore)';
      } else {
        multiWinner = '${l10n.get('winner_tie')} ($playerScore ${l10n.get('winner_each')})';
      }
    }

    return Center(
      child: GlassContainer(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              (solved || state.isVsBots) ? Icons.emoji_events : Icons.heart_broken_outlined,
              size: 72,
              color: (solved || state.isVsBots) ? colors.primary : colors.cellError,
            ),
            const SizedBox(height: 16),
            Text(
              (state.isMultiplayer || state.isVsBots)
                  ? l10n.get('match_over')
                  : (solved ? l10n.get('sudoku_congrats') : l10n.get('sudoku_game_over')),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              (state.isMultiplayer || state.isVsBots)
                  ? l10n.getWith('winner_label', [multiWinner ?? ''])
                  : (solved
                      ? l10n.getWith('sudoku_solved_in', [_formatTime(state.timeSeconds)])
                      : l10n.get('sudoku_game_over_desc')),
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
                    ref.read(activeGameIdProvider.notifier).state = null;
                  },
                  child: Text(l10n.get('back')),
                ),
                if (!state.isMultiplayer)
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
                      
                      _completedRows.clear();
                      _completedCols.clear();
                      _completedBoxes.clear();
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final state = ref.watch(sudokuStateProvider);
        return AlertDialog(
          title: const Text('Sudoku Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Pencil Notes Mode'),
                subtitle: const Text('Enable pencil notation to draft possibilities'),
                value: state.notesMode,
                onChanged: (val) {
                  ref.read(sudokuStateProvider.notifier).toggleNotesMode();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Disable Mistakes Limit'),
                subtitle: const Text('Play with unlimited mistakes without losing'),
                value: state.maxMistakes >= 9999,
                onChanged: (val) {
                  ref.read(sudokuStateProvider.notifier).toggleMaxMistakesLimit();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE'),
            ),
          ],
        );
      },
    );
  }

  void finishGame() {
    final state = ref.read(sudokuStateProvider);
    if (!state.isFinished && state.grid.isNotEmpty) {
      // Auto-solve remaining to finish early (logical parity action)
      final solvedGrid = state.grid.map((c) => c.copyWith(currentValue: c.value)).toList();
      ref.read(sudokuStateProvider.notifier).loadState(state.copyWith(
        grid: solvedGrid,
        isFinished: true,
      ));
    }
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
              
              _completedRows.clear();
              _completedCols.clear();
              _completedBoxes.clear();
            },
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, _SudokuThemeColors colors, AppLocalizations l10n) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('IMPORT PUZZLE'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Paste a share code to load the puzzle directly:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'variant:00305...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              final code = controller.text.trim();
              final result = SudokuShareService.importFromCode(code);
              if (result != null) {
                Navigator.pop(ctx);
                final customState = SudokuGameState(
                  grid: result.grid,
                  difficulty: SudokuDifficulty.medium,
                  variant: result.variant,
                  mode: SudokuMode.classic,
                  theme: SudokuTheme.aether,
                );
                ref.read(sudokuStateProvider.notifier).loadState(customState);
                ref.read(activeGameIdProvider.notifier).state = 'sudoku';
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid puzzle code or has no unique solution!')),
                );
              }
            },
            child: const Text('IMPORT'),
          ),
        ],
      ),
    );
  }
}

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
