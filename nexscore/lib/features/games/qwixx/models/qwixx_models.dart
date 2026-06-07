enum QwixxVariant { original, mixedColors, mixedNumbers }

class QwixxGameState {
  final Map<String, QwixxPlayerSheet> sheets; // PlayerId -> Sheet
  final QwixxVariant variant;
  final bool canUndo;

  static List<int> getRowNumbers(int rowIndex, QwixxVariant variant) {
    if (variant == QwixxVariant.original) {
      if (rowIndex < 2) return List.generate(11, (i) => i + 2);
      return List.generate(11, (i) => 12 - i);
    }
    if (variant == QwixxVariant.mixedNumbers) {
      const sequences = [
        [5, 7, 11, 9, 12, 3, 8, 10, 2, 6, 4], // Red
        [8, 2, 10, 5, 7, 3, 12, 11, 4, 9, 6], // Yellow
        [11, 5, 9, 12, 3, 4, 8, 7, 2, 10, 6], // Green (desc-ish)
        [6, 10, 3, 11, 4, 5, 8, 12, 9, 2, 7], // Blue (desc-ish)
      ];
      return sequences[rowIndex];
    }
    // mixedColors: numbers are same as original, but colors are mixed (handled in UI)
    if (rowIndex < 2) return List.generate(11, (i) => i + 2);
    return List.generate(11, (i) => 12 - i);
  }

  static int getCellColorIndex(int rowIndex, int number, QwixxVariant variant) {
    if (variant != QwixxVariant.mixedColors) {
      return rowIndex;
    }
    // Mixed colors (Variant A) cell color configuration
    // Symmetrical 2-by-2 sequence:
    // Row 0: 2,3: Red (0), 4,5: Yellow (1), 6,7: Green (2), 8,9: Blue (3), 10,11: Red (0), 12: Yellow (1)
    // Row 1: 2,3: Yellow (1), 4,5: Red (0), 6,7: Blue (3), 8,9: Green (2), 10,11: Yellow (1), 12: Red (0)
    // Row 2: 12,11: Green (2), 10,9: Blue (3), 8,7: Red (0), 6,5: Yellow (1), 4,3: Green (2), 2: Blue (3)
    // Row 3: 12,11: Blue (3), 10,9: Green (2), 8,7: Yellow (1), 6,5: Red (0), 4,3: Blue (3), 2: Green (2)
    if (rowIndex == 0) {
      if (number == 2 || number == 3 || number == 10 || number == 11) return 0;
      if (number == 4 || number == 5 || number == 12) return 1;
      if (number == 6 || number == 7) return 2;
      return 3;
    } else if (rowIndex == 1) {
      if (number == 2 || number == 3 || number == 10 || number == 11) return 1;
      if (number == 4 || number == 5 || number == 12) return 0;
      if (number == 6 || number == 7) return 3;
      return 2;
    } else if (rowIndex == 2) {
      if (number == 12 || number == 11 || number == 4 || number == 3) return 2;
      if (number == 10 || number == 9 || number == 2) return 3;
      if (number == 8 || number == 7) return 0;
      return 1;
    } else if (rowIndex == 3) {
      if (number == 12 || number == 11 || number == 4 || number == 3) return 3;
      if (number == 10 || number == 9 || number == 2) return 2;
      if (number == 8 || number == 7) return 1;
      return 0;
    }
    return rowIndex;
  }

  const QwixxGameState({
    this.sheets = const {},
    this.variant = QwixxVariant.original,
    this.canUndo = false,
  });

  Map<String, dynamic> toJson() => {
    'sheets': sheets.map((k, v) => MapEntry(k, v.toJson())),
    'variant': variant.name,
    'canUndo': canUndo,
  };

  factory QwixxGameState.fromJson(Map<String, dynamic> json) {
    return QwixxGameState(
      sheets: (json['sheets'] as Map<String, dynamic>).map(
        (k, v) =>
            MapEntry(k, QwixxPlayerSheet.fromJson(v as Map<String, dynamic>)),
      ),
      variant: QwixxVariant.values.firstWhere(
        (v) => v.name == (json['variant'] as String? ?? 'original'),
        orElse: () => QwixxVariant.original,
      ),
      canUndo: json['canUndo'] as bool? ?? false,
    );
  }

  QwixxGameState copyWith({
    Map<String, QwixxPlayerSheet>? sheets,
    QwixxVariant? variant,
    bool? canUndo,
  }) {
    return QwixxGameState(
      sheets: sheets ?? this.sheets,
      variant: variant ?? this.variant,
      canUndo: canUndo ?? this.canUndo,
    );
  }
}

class QwixxPlayerSheet {
  static const int lockValue = 99;

  final List<int> red;
  final List<int> yellow;
  final List<int> green;
  final List<int> blue;
  final int penalties;

  const QwixxPlayerSheet({
    this.red = const [],
    this.yellow = const [],
    this.green = const [],
    this.blue = const [],
    this.penalties = 0,
  });

  QwixxPlayerSheet copyWith({
    List<int>? red,
    List<int>? yellow,
    List<int>? green,
    List<int>? blue,
    int? penalties,
  }) {
    return QwixxPlayerSheet(
      red: red ?? this.red,
      yellow: yellow ?? this.yellow,
      green: green ?? this.green,
      blue: blue ?? this.blue,
      penalties: penalties ?? this.penalties,
    );
  }

  Map<String, dynamic> toJson() => {
    'red': red,
    'yellow': yellow,
    'green': green,
    'blue': blue,
    'penalties': penalties,
  };

  factory QwixxPlayerSheet.fromJson(Map<String, dynamic> json) {
    return QwixxPlayerSheet(
      red: List<int>.from(json['red'] as List),
      yellow: List<int>.from(json['yellow'] as List),
      green: List<int>.from(json['green'] as List),
      blue: List<int>.from(json['blue'] as List),
      penalties: json['penalties'] as int? ?? 0,
    );
  }

  int get totalScore {
    int score = 0;
    score += calculateRowScore(red.length);
    score += calculateRowScore(yellow.length);
    score += calculateRowScore(green.length);
    score += calculateRowScore(blue.length);
    score -= (penalties * 5);
    return score;
  }

  int calculateRowScore(int crosses) {
    if (crosses <= 0) return 0;
    return (crosses * (crosses + 1)) ~/ 2;
  }
}
