import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/multiplayer/providers/multiplayer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sudoku_campaign_data.dart';
import '../models/sudoku_models.dart';
import '../services/sudoku_generator.dart';
import '../services/sudoku_sync_service.dart';
import '../services/sudoku_stats_service.dart';
import '../services/sudoku_analyzer.dart';

class SudokuStateNotifier extends Notifier<SudokuGameState> {
  final List<List<SudokuCell>> _history = [];
  Timer? _timer;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _gameStateSubscription;

  @override
  SudokuGameState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _eventsSubscription?.cancel();
      _gameStateSubscription?.cancel();
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
      
      // Sync state if multiplayer host
      _syncMultiplayerState();
    }
  }

  void setupMatch({
    required SudokuVariant variant,
    required SudokuDifficulty difficulty,
    required SudokuMode mode,
    bool isMultiplayer = false,
  }) {
    _history.clear();
    _timer?.cancel();
    _eventsSubscription?.cancel();
    _gameStateSubscription?.cancel();

    final grid = SudokuGenerator.generate(variant: variant, difficulty: difficulty);

    state = SudokuGameState(
      grid: grid,
      difficulty: difficulty,
      variant: variant,
      mode: mode,
      theme: state.theme,
      mistakes: 0,
      maxMistakes: mode == SudokuMode.zen ? 9999 : 3,
      timeSeconds: 0,
      isFinished: false,
      isMultiplayer: isMultiplayer,
      playerScores: {},
      playerMistakes: {},
    );

    if (isMultiplayer) {
      final isHost = ref.read(isHostProvider);
      if (isHost) {
        _syncMultiplayerState();
        _startListeningToClientEvents();
      } else {
        _startListeningToHostState();
      }
    } else {
      startTimer();
    }
  }

  void setupDaily(
    String dateStr, {
    required SudokuVariant variant,
    required SudokuDifficulty difficulty,
  }) {
    _history.clear();
    _timer?.cancel();
    _eventsSubscription?.cancel();
    _gameStateSubscription?.cancel();

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

  void setupCampaignLevel(int levelId) {
    _history.clear();
    _timer?.cancel();
    _eventsSubscription?.cancel();
    _gameStateSubscription?.cancel();

    final level = sudokuCampaignLevels.firstWhere(
      (l) => l.levelId == levelId,
      orElse: () => sudokuCampaignLevels.first,
    );

    final grid = SudokuGenerator.generateSeeded(
      seed: level.seed,
      variant: level.variant,
      difficulty: level.difficulty,
    );

    state = SudokuGameState(
      grid: grid,
      difficulty: level.difficulty,
      variant: level.variant,
      mode: SudokuMode.classic,
      theme: state.theme,
      mistakes: 0,
      maxMistakes: 3,
      timeSeconds: 0,
      isFinished: false,
      campaignLevelId: levelId,
    );

    startTimer();
  }

  void loadState(SudokuGameState savedState) {
    _history.clear();
    _timer?.cancel();
    _eventsSubscription?.cancel();
    _gameStateSubscription?.cancel();
    state = savedState;
    if (!state.isFinished && !state.isMultiplayer) {
      startTimer();
    }
  }

  void selectCell(int row, int col) {
    if (state.isFinished) return;
    state = state.clearHint().copyWith(selectedRow: row, selectedCol: col);
  }

  void selectTheme(SudokuTheme theme) {
    state = state.copyWith(theme: theme);
  }

  void toggleNotesMode() {
    state = state.copyWith(notesMode: !state.notesMode);
  }

  List<SudokuCell> _autoEraseNotes(List<SudokuCell> grid, int row, int col, int value, int size) {
    final updatedGrid = List<SudokuCell>.from(grid);
    for (int i = 0; i < grid.length; i++) {
      final cell = grid[i];
      if (cell.currentValue > 0) continue;
      
      final r = i ~/ size;
      final c = i % size;
      
      bool inSameRow = (r == row);
      bool inSameCol = (c == col);
      bool inSameBlock = false;
      
      if (size == 6) {
        inSameBlock = (r ~/ 2 == row ~/ 2) && (c ~/ 3 == col ~/ 3);
      } else {
        inSameBlock = (r ~/ 3 == row ~/ 3) && (c ~/ 3 == col ~/ 3);
      }
      
      if (inSameRow || inSameCol || inSameBlock) {
        if (cell.notes.contains(value)) {
          final updatedNotes = Set<int>.from(cell.notes)..remove(value);
          updatedGrid[i] = cell.copyWith(notes: updatedNotes);
        }
      }
    }
    return updatedGrid;
  }

  void enterNumber(int num, String currentUsername) {
    state = state.clearHint();
    final r = state.selectedRow;
    final c = state.selectedCol;
    if (r == null || c == null || state.isFinished) return;

    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;
    final cellIdx = r * size + c;
    final cell = state.grid[cellIdx];

    if (cell.isOriginal || cell.currentValue == cell.value) return;

    if (state.isMultiplayer && !state.notesMode) {
      // Multiplayer Mode: Client sends event to Host (or host directly processes if they input)
      final myUid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
      final myName = currentUsername.isEmpty ? 'Player' : currentUsername;
      
      final isHost = ref.read(isHostProvider);
      if (isHost) {
        _processCellInput(r, c, num, myUid, myName, '0xFF00E5FF'); // Neon Cyan for host
      } else {
        // Send event to host via SyncEngine
        ref.read(syncEngineProvider).sendClientEvent('cell_input', {
          'row': r,
          'col': c,
          'value': num,
          'uid': myUid,
          'name': myName,
          'color': '0xFFFF0055', // Neon Pink for client
        });
      }
    } else {
      // Standard Local Flow
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
        final isCorrect = cell.value == num;
        
        var newGrid = List<SudokuCell>.from(state.grid);
        newGrid[cellIdx] = cell.copyWith(
          currentValue: num,
          notes: {},
          isError: !isCorrect,
        );

        if (isCorrect) {
          newGrid = _autoEraseNotes(newGrid, r, c, num, size);
        }

        final validatedGrid = SudokuGenerator.validateBoard(newGrid, state.variant);

        int mistakes = state.mistakes;
        int penalty = 0;
        if (!isCorrect) {
          mistakes++;
          if (state.mode == SudokuMode.timeAttack) {
            penalty = 30;
          }
        }

        bool solved = validatedGrid.every((c) => c.currentValue == c.value);

        state = state.copyWith(
          grid: validatedGrid,
          mistakes: mistakes,
          timeSeconds: state.timeSeconds + penalty,
          isFinished: solved || mistakes >= state.maxMistakes,
        );

        if (state.isFinished) {
          _timer?.cancel();
          SudokuStatsService.recordGame(
            variant: state.variant.name,
            difficulty: state.difficulty.name,
            won: solved,
            timeSeconds: state.timeSeconds,
          );

          if (solved) {
            if (state.campaignLevelId != null) {
              _saveCampaignProgress(state.campaignLevelId!);
            } else {
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
    }
  }

  void eraseCell() {
    if (state.isMultiplayer) return; // Disallow erasing solved entries in competitive multiplayer

    state = state.clearHint();
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

    final validatedGrid = SudokuGenerator.validateBoard(newGrid, state.variant);
    state = state.copyWith(grid: validatedGrid);
  }

  void useHint() {
    if (state.isMultiplayer) return; // No hints in competitive match

    final analysis = SudokuAnalyzer.analyze(state.grid, state.variant);
    if (analysis == null) return;

    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;
    final r = analysis.cellIndex ~/ size;
    final c = analysis.cellIndex % size;

    state = state.copyWith(
      selectedRow: r,
      selectedCol: c,
      analyzerExplanation: analysis.explanation,
      highlightedHintCell: analysis.cellIndex,
      hasUsedHint: true,
    );
  }

  Future<void> _saveCampaignProgress(int levelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sudoku_academy_level_completed_$levelId', true);
    ref.invalidate(completedCampaignLevelsProvider);
  }

  // --- Multiplayer Engine Sync & Processors ---

  void _syncMultiplayerState() {
    ref.read(syncEngineProvider).pushState(state.toMap());
  }

  void _startListeningToHostState() {
    _gameStateSubscription?.cancel();
    _gameStateSubscription = ref.read(gameStateSyncProvider.stream).listen((updatedStateMap) {
      try {
        final hostState = SudokuGameState.fromMap(updatedStateMap);
        
        // Preserve local client notes
        final mergedGrid = List<SudokuCell>.from(hostState.grid);
        for (int i = 0; i < mergedGrid.length; i++) {
          if (i < state.grid.length) {
            final clientCell = state.grid[i];
            final hostCell = mergedGrid[i];
            // Only preserve notes if the cell is still empty (currentValue == 0)
            if (hostCell.currentValue == 0 && clientCell.currentValue == 0) {
              mergedGrid[i] = hostCell.copyWith(notes: clientCell.notes);
            }
          }
        }

        // Client updates state but preserves their current local theme & selection settings
        state = hostState.copyWith(
          grid: mergedGrid,
          theme: state.theme,
          selectedRow: state.selectedRow,
          selectedCol: state.selectedCol,
        );
      } catch (e) {
        debugPrint('Error parsing multiplayer host state: $e');
      }
    });
  }

  void _startListeningToClientEvents() {
    _eventsSubscription?.cancel();
    final lobby = ref.read(currentLobbyProvider);
    if (lobby == null) return;

    _eventsSubscription = FirebaseFirestore.instance
        .collection('lobbies')
        .doc(lobby.id)
        .collection('events')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
          for (final doc in snapshot.docChanges) {
            if (doc.type == DocumentChangeType.added) {
              final data = doc.doc.data();
              if (data != null) {
                final eventName = data['eventName'] as String;
                final payload = Map<String, dynamic>.from(data['payload'] ?? {});
                if (eventName == 'cell_input') {
                  final row = payload['row'] as int;
                  final col = payload['col'] as int;
                  final val = payload['value'] as int;
                  final uid = payload['uid'] as String;
                  final name = payload['name'] as String;
                  final color = payload['color'] as String;
                  _processCellInput(row, col, val, uid, name, color);
                }
              }
            }
          }
        });
  }

  void _processCellInput(int r, int c, int num, String uid, String name, String color) {
    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;
    final cellIdx = r * size + c;
    final cell = state.grid[cellIdx];

    if (cell.isOriginal || cell.currentValue == cell.value) return;

    final isCorrect = cell.value == num;
    var newGrid = List<SudokuCell>.from(state.grid);

    final scores = Map<String, int>.from(state.playerScores);
    final mistakes = Map<String, int>.from(state.playerMistakes);

    if (isCorrect) {
      newGrid[cellIdx] = cell.copyWith(
        currentValue: num,
        notes: {},
        isError: false,
        filledByUid: uid,
        filledByName: name,
        filledByColor: color,
      );
      // Auto erase pencil marks
      newGrid = _autoEraseNotes(newGrid, r, c, num, size);
      
      // Award points
      scores[uid] = (scores[uid] ?? 0) + 100;
    } else {
      // Deduct points, record mistake
      scores[uid] = (scores[uid] ?? 0) - 50;
      mistakes[uid] = (mistakes[uid] ?? 0) + 1;
    }

    // Check if grid is solved
    bool solved = newGrid.every((c) => c.currentValue == c.value);

    state = state.copyWith(
      grid: newGrid,
      playerScores: scores,
      playerMistakes: mistakes,
      isFinished: solved,
    );

    // Sync updated state to all clients
    _syncMultiplayerState();
  }
}

final sudokuStateProvider = NotifierProvider<SudokuStateNotifier, SudokuGameState>(
  SudokuStateNotifier.new,
);

final completedCampaignLevelsProvider = FutureProvider<Set<int>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final completed = <int>{};
  for (int i = 1; i <= 20; i++) {
    if (prefs.getBool('sudoku_academy_level_completed_$i') ?? false) {
      completed.add(i);
    }
  }
  return completed;
});
