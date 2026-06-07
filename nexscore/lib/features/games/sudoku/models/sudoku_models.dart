import 'package:flutter/material.dart';

enum SudokuDifficulty { easy, medium, hard, expert }

enum SudokuVariant { standard, diagonal, hyper, mini6x6 }

enum SudokuMode { classic, zen, timeAttack }

enum SudokuTheme { aether, zen, midnight, cyberpunk }

class SudokuCell {
  final int row;
  final int col;
  final int value;
  final int currentValue;
  final bool isOriginal;
  final Set<int> notes;
  final bool isError;
  final String? filledByUid;
  final String? filledByName;
  final String? filledByColor;

  const SudokuCell({
    required this.row,
    required this.col,
    required this.value,
    this.currentValue = 0,
    required this.isOriginal,
    required this.notes,
    this.isError = false,
    this.filledByUid,
    this.filledByName,
    this.filledByColor,
  });

  SudokuCell copyWith({
    int? currentValue,
    Set<int>? notes,
    bool? isError,
    String? filledByUid,
    String? filledByName,
    String? filledByColor,
  }) {
    return SudokuCell(
      row: row,
      col: col,
      value: value,
      currentValue: currentValue ?? this.currentValue,
      isOriginal: isOriginal,
      notes: notes ?? this.notes,
      isError: isError ?? this.isError,
      filledByUid: filledByUid ?? this.filledByUid,
      filledByName: filledByName ?? this.filledByName,
      filledByColor: filledByColor ?? this.filledByColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'row': row,
      'col': col,
      'value': value,
      'currentValue': currentValue,
      'isOriginal': isOriginal ? 1 : 0,
      'notes': notes.toList(),
      'isError': isError ? 1 : 0,
      'filledByUid': filledByUid,
      'filledByName': filledByName,
      'filledByColor': filledByColor,
    };
  }

  factory SudokuCell.fromMap(Map<String, dynamic> map) {
    return SudokuCell(
      row: map['row'] as int,
      col: map['col'] as int,
      value: map['value'] as int,
      currentValue: map['currentValue'] as int,
      isOriginal: (map['isOriginal'] as int) == 1,
      notes: List<int>.from(map['notes'] as List).toSet(),
      isError: (map['isError'] as int) == 1,
      filledByUid: map['filledByUid'] as String?,
      filledByName: map['filledByName'] as String?,
      filledByColor: map['filledByColor'] as String?,
    );
  }
}

class SudokuGameState {
  final List<SudokuCell> grid;
  final SudokuDifficulty difficulty;
  final SudokuVariant variant;
  final SudokuMode mode;
  final SudokuTheme theme;
  final int mistakes;
  final int maxMistakes;
  final int timeSeconds;
  final bool isFinished;
  final int? selectedRow;
  final int? selectedCol;
  final bool notesMode;
  final bool isDailyChallenge;
  final String? dailyDate;
  final bool hasUsedHint;
  final bool isMultiplayer;
  final Map<String, int> playerScores;
  final Map<String, int> playerMistakes;

  const SudokuGameState({
    required this.grid,
    required this.difficulty,
    required this.variant,
    required this.mode,
    required this.theme,
    this.mistakes = 0,
    this.maxMistakes = 3,
    this.timeSeconds = 0,
    this.isFinished = false,
    this.selectedRow,
    this.selectedCol,
    this.notesMode = false,
    this.isDailyChallenge = false,
    this.dailyDate,
    this.hasUsedHint = false,
    this.isMultiplayer = false,
    this.playerScores = const {},
    this.playerMistakes = const {},
  });

  SudokuGameState copyWith({
    List<SudokuCell>? grid,
    SudokuDifficulty? difficulty,
    SudokuVariant? variant,
    SudokuMode? mode,
    SudokuTheme? theme,
    int? mistakes,
    int? maxMistakes,
    int? timeSeconds,
    bool? isFinished,
    int? selectedRow,
    int? selectedCol,
    bool? notesMode,
    bool? isDailyChallenge,
    String? dailyDate,
    bool? hasUsedHint,
    bool? isMultiplayer,
    Map<String, int>? playerScores,
    Map<String, int>? playerMistakes,
  }) {
    return SudokuGameState(
      grid: grid ?? this.grid,
      difficulty: difficulty ?? this.difficulty,
      variant: variant ?? this.variant,
      mode: mode ?? this.mode,
      theme: theme ?? this.theme,
      mistakes: mistakes ?? this.mistakes,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      timeSeconds: timeSeconds ?? this.timeSeconds,
      isFinished: isFinished ?? this.isFinished,
      selectedRow: selectedRow,
      selectedCol: selectedCol,
      notesMode: notesMode ?? this.notesMode,
      isDailyChallenge: isDailyChallenge ?? this.isDailyChallenge,
      dailyDate: dailyDate ?? this.dailyDate,
      hasUsedHint: hasUsedHint ?? this.hasUsedHint,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      playerScores: playerScores ?? this.playerScores,
      playerMistakes: playerMistakes ?? this.playerMistakes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'grid': grid.map((c) => c.toMap()).toList(),
      'difficulty': difficulty.name,
      'variant': variant.name,
      'mode': mode.name,
      'theme': theme.name,
      'mistakes': mistakes,
      'maxMistakes': maxMistakes,
      'timeSeconds': timeSeconds,
      'isFinished': isFinished ? 1 : 0,
      'selectedRow': selectedRow,
      'selectedCol': selectedCol,
      'notesMode': notesMode ? 1 : 0,
      'isDailyChallenge': isDailyChallenge ? 1 : 0,
      'dailyDate': dailyDate,
      'hasUsedHint': hasUsedHint ? 1 : 0,
      'isMultiplayer': isMultiplayer ? 1 : 0,
      'playerScores': playerScores,
      'playerMistakes': playerMistakes,
    };
  }

  factory SudokuGameState.fromMap(Map<String, dynamic> map) {
    return SudokuGameState(
      grid: (map['grid'] as List)
          .map((c) => SudokuCell.fromMap(c as Map<String, dynamic>))
          .toList(),
      difficulty: SudokuDifficulty.values.firstWhere(
        (e) => e.name == map['difficulty'],
        orElse: () => SudokuDifficulty.medium,
      ),
      variant: SudokuVariant.values.firstWhere(
        (e) => e.name == map['variant'],
        orElse: () => SudokuVariant.standard,
      ),
      mode: SudokuMode.values.firstWhere(
        (e) => e.name == map['mode'],
        orElse: () => SudokuMode.classic,
      ),
      theme: SudokuTheme.values.firstWhere(
        (e) => e.name == map['theme'],
        orElse: () => SudokuTheme.aether,
      ),
      mistakes: map['mistakes'] as int,
      maxMistakes: map['maxMistakes'] as int? ?? 3,
      timeSeconds: map['timeSeconds'] as int,
      isFinished: (map['isFinished'] as int) == 1,
      selectedRow: map['selectedRow'] as int?,
      selectedCol: map['selectedCol'] as int?,
      notesMode: (map['notesMode'] as int) == 1,
      isDailyChallenge: (map['isDailyChallenge'] as int? ?? 0) == 1,
      dailyDate: map['dailyDate'] as String?,
      hasUsedHint: (map['hasUsedHint'] as int? ?? 0) == 1,
      isMultiplayer: (map['isMultiplayer'] as int? ?? 0) == 1,
      playerScores: Map<String, int>.from(map['playerScores'] ?? {}),
      playerMistakes: Map<String, int>.from(map['playerMistakes'] ?? {}),
    );
  }
}
