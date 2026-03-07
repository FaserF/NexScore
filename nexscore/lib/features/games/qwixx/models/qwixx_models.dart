enum QwixxVariant { original, mixedColors, mixedNumbers }

class QwixxGameState {
  final Map<String, QwixxPlayerSheet> sheets; // PlayerId -> Sheet
  final QwixxVariant variant;

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

  const QwixxGameState({
    this.sheets = const {},
    this.variant = QwixxVariant.original,
  });

  Map<String, dynamic> toJson() => {
    'sheets': sheets.map((k, v) => MapEntry(k, v.toJson())),
    'variant': variant.name,
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
    );
  }

  QwixxGameState copyWith({
    Map<String, QwixxPlayerSheet>? sheets,
    QwixxVariant? variant,
  }) {
    return QwixxGameState(
      sheets: sheets ?? this.sheets,
      variant: variant ?? this.variant,
    );
  }
}

class QwixxPlayerSheet {
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
