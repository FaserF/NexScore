class QwixxGameState {
  final Map<String, QwixxPlayerSheet> sheets; // PlayerId -> Sheet

  const QwixxGameState({this.sheets = const {}});

  Map<String, dynamic> toJson() => {
    'sheets': sheets.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory QwixxGameState.fromJson(Map<String, dynamic> json) {
    return QwixxGameState(
      sheets: (json['sheets'] as Map<String, dynamic>).map(
        (k, v) =>
            MapEntry(k, QwixxPlayerSheet.fromJson(v as Map<String, dynamic>)),
      ),
    );
  }
}

class QwixxPlayerSheet {
  final List<int> red; // Crossed out numbers, e.g., [2, 3, 5]
  final List<int> yellow;
  final List<int> green;
  final List<int> blue;
  final int penalties; // 0 to 4 (each -5 pts)

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
    // 1 cross = 1, 2 crosses = 3, 3 = 6, 4 = 10, ... sum of 1..N
    if (crosses <= 0) return 0;
    return (crosses * (crosses + 1)) ~/ 2;
  }
}
