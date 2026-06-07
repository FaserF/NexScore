import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/multiplayer/providers/multiplayer_provider.dart';
import '../../../../core/providers/persistence_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sudoku_campaign_data.dart';
import '../models/sudoku_models.dart';
import '../services/sudoku_generator.dart';
import '../services/sudoku_sync_service.dart';
import '../services/sudoku_stats_service.dart';
import '../services/sudoku_analyzer.dart';
import '../../../settings/provider/settings_provider.dart';


class SudokuStateNotifier extends Notifier<SudokuGameState> {
  final List<List<SudokuCell>> _history = [];
  Timer? _timer;
  StreamSubscription? _eventsSubscription;
  StreamSubscription? _gameStateSubscription;

  @override
  SudokuGameState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _botTimer?.cancel();
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

  Timer? _botTimer;
  final _random = math.Random();

  void setupMatch({
    required SudokuVariant variant,
    required SudokuDifficulty difficulty,
    required SudokuMode mode,
    bool isMultiplayer = false,
    bool isVsBots = false,
    String? botDifficulty,
  }) {
    _history.clear();
    _timer?.cancel();
    _botTimer?.cancel();
    _eventsSubscription?.cancel();
    _gameStateSubscription?.cancel();

    final grid = SudokuGenerator.generate(variant: variant, difficulty: difficulty);

    // Initial score board for bots if isVsBots is true
    final Map<String, int> initialScores = {};
    final Map<String, int> initialMistakes = {};

    if (isVsBots && botDifficulty != null) {
      final botName = _getBotName(botDifficulty);
      initialScores['player'] = 0;
      initialScores[botName] = 0;
      initialMistakes['player'] = 0;
      initialMistakes[botName] = 0;
    }

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
      isVsBots: isVsBots,
      botDifficulty: botDifficulty,
      playerScores: initialScores,
      playerMistakes: initialMistakes,
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
      if (isVsBots && botDifficulty != null) {
        _startBotSimulation();
      }
      _autoSave();
    }
  }

  String _getBotName(String difficulty) {
    return switch (difficulty.toLowerCase()) {
      'easy' => 'LogicBot',
      'medium' => 'GridMaster',
      'expert' => 'QuantumSolver',
      _ => 'Bot',
    };
  }

  void _startBotSimulation() {
    _botTimer?.cancel();
    final difficulty = state.botDifficulty ?? 'medium';

    // Easy Bot: 22-30s
    // Medium Bot: 15-20s
    // Expert Bot: 9-14s
    int getNextIntervalSeconds() {
      return switch (difficulty.toLowerCase()) {
        'easy' => 22 + _random.nextInt(9),
        'medium' => 15 + _random.nextInt(6),
        'expert' => 9 + _random.nextInt(6),
        _ => 15,
      };
    }

    void scheduleNextMove() {
      if (state.isFinished) return;
      final seconds = getNextIntervalSeconds();
      _botTimer = Timer(Duration(seconds: seconds), () {
        if (!state.isFinished) {
          _triggerBotMove();
          scheduleNextMove();
        }
      });
    }

    scheduleNextMove();
  }

  void _triggerBotMove() {
    if (state.isFinished) return;

    // Get list of empty cells
    final emptyIndices = <int>[];
    for (int i = 0; i < state.grid.length; i++) {
      if (state.grid[i].currentValue == 0) {
        emptyIndices.add(i);
      }
    }

    if (emptyIndices.isEmpty) return;

    // Pick a random empty cell
    final cellIdx = emptyIndices[_random.nextInt(emptyIndices.length)];
    final cell = state.grid[cellIdx];
    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;

    // Determine correctness probability based on difficulty
    // Easy: 10% error
    // Medium: 5% error
    // Expert: 2% error
    final errorProbability = switch (state.botDifficulty?.toLowerCase()) {
      'easy' => 10,
      'medium' => 5,
      'expert' => 2,
      _ => 5,
    };

    final isCorrect = _random.nextInt(100) >= errorProbability;
    final botName = _getBotName(state.botDifficulty ?? 'medium');
    final botColor = '0xFFFF0055'; // Pink/Accent color for Bot moves

    final enterValue = isCorrect ? cell.value : (cell.value == size ? 1 : cell.value + 1);

    var newGrid = List<SudokuCell>.from(state.grid);
    final scores = Map<String, int>.from(state.playerScores);
    final mistakes = Map<String, int>.from(state.playerMistakes);

    if (isCorrect) {
      newGrid[cellIdx] = cell.copyWith(
        currentValue: enterValue,
        notes: {},
        isError: false,
        filledByUid: botName,
        filledByName: botName,
        filledByColor: botColor,
      );
      // Auto erase pencil marks
      newGrid = _autoEraseNotes(newGrid, cell.row, cell.col, enterValue, size);
      scores[botName] = (scores[botName] ?? 0) + 100;
    } else {
      scores[botName] = (scores[botName] ?? 0) - 50;
      mistakes[botName] = (mistakes[botName] ?? 0) + 1;
    }

    bool solved = newGrid.every((c) => c.currentValue == c.value);

    state = state.copyWith(
      grid: newGrid,
      playerScores: scores,
      playerMistakes: mistakes,
      isFinished: solved,
    );

    if (state.isFinished) {
      _timer?.cancel();
      _botTimer?.cancel();
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
      maxMistakes: level.maxMistakes,
      timeSeconds: 0,
      isFinished: false,
      campaignLevelId: levelId,
    );

    startTimer();
  }

  void loadState(SudokuGameState savedState) {
    _history.clear();
    _timer?.cancel();
    _botTimer?.cancel();
    _eventsSubscription?.cancel();
    _gameStateSubscription?.cancel();
    state = savedState;
    if (!state.isFinished && !state.isMultiplayer) {
      startTimer();
      if (state.isVsBots && state.botDifficulty != null) {
        _startBotSimulation();
      }
    }
  }

  Future<void> _autoSave() async {
    if (state.isMultiplayer) return;
    try {
      final service = ref.read(persistenceServiceProvider);
      if (state.isFinished || state.grid.isEmpty) {
        await service.clearGameState('sudoku');
      } else {
        await service.saveGameState('sudoku', state.toMap());
      }
    } catch (e) {
      debugPrint('Failed to auto-save Sudoku state: $e');
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

  void toggleMaxMistakesLimit() {
    // If currently unlimited (e.g. 9999), reset to 3, otherwise set to 9999
    final newLimit = state.maxMistakes >= 9999 ? 3 : 9999;
    state = state.copyWith(maxMistakes: newLimit);
    _autoSave();
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

        Map<String, int> scores = Map<String, int>.from(state.playerScores);
        Map<String, int> playerMistakesMap = Map<String, int>.from(state.playerMistakes);

        if (state.isVsBots) {
          if (isCorrect) {
            scores['player'] = (scores['player'] ?? 0) + 100;
          } else {
            scores['player'] = (scores['player'] ?? 0) - 50;
            playerMistakesMap['player'] = (playerMistakesMap['player'] ?? 0) + 1;
          }
        }

        state = state.copyWith(
          grid: validatedGrid,
          mistakes: mistakes,
          timeSeconds: state.timeSeconds + penalty,
          isFinished: solved || (mistakes >= state.maxMistakes),
          playerScores: state.isVsBots ? scores : state.playerScores,
          playerMistakes: state.isVsBots ? playerMistakesMap : state.playerMistakes,
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
        _autoSave();
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
    _autoSave();
  }

  void useHint() {
    if (state.isMultiplayer) return; // No hints in competitive match

    final size = state.variant == SudokuVariant.mini6x6 ? 6 : 9;
    int? selectedCellIdx;
    if (state.selectedRow != null && state.selectedCol != null) {
      selectedCellIdx = state.selectedRow! * size + state.selectedCol!;
    }

    final analysis = SudokuAnalyzer.analyze(state.grid, state.variant, selectedCellIndex: selectedCellIdx);
    if (analysis == null) return;

    final r = analysis.cellIndex ~/ size;
    final c = analysis.cellIndex % size;

    final settings = ref.read(settingsProvider);
    final languageCode = settings.locale?.languageCode ?? WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final isDe = languageCode == 'de';

    String explanation = '';
    final args = analysis.explanationArgs;
    if (isDe) {
      explanation = switch (analysis.explanationKey) {
        'sudoku_hint_naked_single' => 'Nacktes Einerfeld: In Zeile ${args[0]}, Spalte ${args[1]} kann legal nur die Zahl ${args[2]} eingetragen werden. Alle anderen Zahlen [1-${args[3]}] stehen im Konflikt mit bereits vorhandenen Zahlen in der Zeile, Spalte oder dem Block.',
        'sudoku_hint_hidden_row' => 'Verstecktes Einerfeld (Zeile): In Zeile ${args[0]} kann die Zahl ${args[1]} legal nur in Spalte ${args[2]} platziert werden. Alle anderen leeren Zellen in dieser Zeile sind durch ${args[1]} in den entsprechenden Spalten oder Blöcken blockiert.',
        'sudoku_hint_hidden_col' => 'Verstecktes Einerfeld (Spalte): In Spalte ${args[0]} kann die Zahl ${args[1]} legal nur in Zeile ${args[2]} platziert werden. Keine andere leere Zelle in dieser Spalte kann ${args[1]} aufgrund von Zeilen- oder Blockeinschränkungen aufnehmen.',
        'sudoku_hint_hidden_block' => 'Verstecktes Einerfeld (Block): In Block ${args[0]} hat die Zahl ${args[1]} nur eine gültige Zelle, in die sie passt (Zeile ${args[2]}, Spalte ${args[3]}). Alle anderen leeren Plätze in diesem Block sind durch ${args[1]} in benachbarten Zeilen oder Spalten blockiert.',
        'sudoku_hint_reveal' => 'Hinweis aufdecken: In Zeile ${args[0]}, Spalte ${args[1]} ist der korrekte Wert ${args[2]}. Nutze logische Elimination, um herauszufinden, warum andere Ziffern blockiert sind!',
        _ => '',
      };
    } else {
      explanation = switch (analysis.explanationKey) {
        'sudoku_hint_naked_single' => 'Naked Single: At Row ${args[0]}, Column ${args[1]}, the only number that can legally fit is ${args[2]}. All other numbers [1-${args[3]}] clash with numbers already present in its row, column, or block.',
        'sudoku_hint_hidden_row' => 'Hidden Single (Row): In Row ${args[0]}, the number ${args[1]} can only be legally placed in Column ${args[2]}. All other empty cells in this row are blocked by ${args[1]} in corresponding columns or blocks.',
        'sudoku_hint_hidden_col' => 'Hidden Single (Column): In Column ${args[0]}, the number ${args[1]} can only be legally placed in Row ${args[2]}. No other empty cells in this column can accept ${args[1]} due to row or block constraints.',
        'sudoku_hint_hidden_block' => 'Hidden Single (Block): In Block ${args[0]}, the number ${args[1]} has only one valid cell where it can fit (Row ${args[2]}, Column ${args[3]}). All other empty spaces in this block are blocked by ${args[1]} in neighboring rows or columns.',
        'sudoku_hint_reveal' => 'Reveal Hint: At Row ${args[0]}, Column ${args[1]}, the correct value is ${args[2]}. Use logical elimination to figure out why other digits are blocked!',
        _ => '',
      };
    }

    state = state.copyWith(
      selectedRow: r,
      selectedCol: c,
      analyzerExplanation: explanation,
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
    _gameStateSubscription = ref.read(syncEngineProvider).gameStateStream.listen((updatedStateMap) {
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
