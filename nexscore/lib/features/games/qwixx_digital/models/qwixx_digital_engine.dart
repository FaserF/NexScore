import 'dart:math';

/// Phase of the digital Qwixx game.
enum QwixxDigitalPhase {
  setup, // Waiting to start
  rolling, // Active player rolls dice
  whiteChoice, // Active player chooses to cross off white sum (optional)
  colorChoice, // Active player crosses off white+color sum (optional)
  otherPlayers, // Other players may cross off white sum
  roundEnd, // All done this round
  finished, // Game over
}

/// The four Qwixx row colors.
enum QwixxColor { red, yellow, green, blue }

/// State of a single Qwixx row.
class QwixxRowState {
  final QwixxColor color;
  final List<int> crossedNumbers;
  final bool isLocked;

  const QwixxRowState({
    required this.color,
    this.crossedNumbers = const [],
    this.isLocked = false,
  });

  QwixxRowState copyWith({List<int>? crossedNumbers, bool? isLocked}) {
    return QwixxRowState(
      color: color,
      crossedNumbers: crossedNumbers ?? this.crossedNumbers,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toMap() => {
    'color': color.name,
    'crossedNumbers': crossedNumbers,
    'isLocked': isLocked,
  };

  factory QwixxRowState.fromMap(Map<String, dynamic> map) => QwixxRowState(
    color: QwixxColor.values.firstWhere((e) => e.name == map['color']),
    crossedNumbers: List<int>.from(map['crossedNumbers'] ?? []),
    isLocked: map['isLocked'] ?? false,
  );

  /// Numbers in the row (left to right).
  List<int> get numbers {
    if (color == QwixxColor.red || color == QwixxColor.yellow) {
      return List.generate(11, (i) => i + 2); // 2-12 ascending
    } else {
      return List.generate(11, (i) => 12 - i); // 12-2 descending
    }
  }

  /// Score for this row based on Qwixx scoring table.
  int get score {
    final count = crossedNumbers.length + (isLocked ? 1 : 0); // +1 for the lock
    // Qwixx scoring: 1=1, 2=3, 3=6, 4=10, 5=15, 6=21, 7=28, 8=36, 9=45, 10=55, 11=66, 12=78
    return count * (count + 1) ~/ 2;
  }

  /// Can this number be crossed off? Must be to the RIGHT of the last crossed number.
  bool canCross(int number) {
    if (isLocked) return false;
    if (crossedNumbers.contains(number)) return false;

    if (crossedNumbers.isEmpty) return true;

    final nums = numbers;
    final lastCrossedIdx = nums.indexOf(crossedNumbers.last);
    final targetIdx = nums.indexOf(number);

    return targetIdx > lastCrossedIdx;
  }

  /// Can the row be locked? Need at least 5 crosses AND the last number must be crossed.
  bool get canLock {
    if (crossedNumbers.length < 5) return false;
    return crossedNumbers.contains(numbers.last);
  }
}

/// State for a single player.
class QwixxDigitalPlayerState {
  final Map<QwixxColor, QwixxRowState> rows;
  final int penalties;

  const QwixxDigitalPlayerState({this.rows = const {}, this.penalties = 0});

  QwixxDigitalPlayerState copyWith({
    Map<QwixxColor, QwixxRowState>? rows,
    int? penalties,
  }) {
    return QwixxDigitalPlayerState(
      rows: rows ?? this.rows,
      penalties: penalties ?? this.penalties,
    );
  }

  Map<String, dynamic> toMap() => {
    'rows': rows.map((k, v) => MapEntry(k.name, v.toMap())),
    'penalties': penalties,
  };

  factory QwixxDigitalPlayerState.fromMap(Map<String, dynamic> map) =>
      QwixxDigitalPlayerState(
        rows: (map['rows'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            QwixxColor.values.firstWhere((e) => e.name == k),
            QwixxRowState.fromMap(v as Map<String, dynamic>),
          ),
        ),
        penalties: map['penalties'] ?? 0,
      );

  /// Initialize fresh rows.
  static QwixxDigitalPlayerState initial() {
    return QwixxDigitalPlayerState(
      rows: {
        for (final color in QwixxColor.values)
          color: QwixxRowState(color: color),
      },
    );
  }

  /// Total score = sum of row scores - (penalties × 5).
  int get totalScore {
    int total = 0;
    for (final row in rows.values) {
      total += row.score;
    }
    return total - (penalties * 5);
  }
}

/// Full game state.
class QwixxDigitalState {
  final QwixxDigitalPhase phase;
  final List<String> playerOrder;
  final Map<String, QwixxDigitalPlayerState> playerStates;
  final String? activePlayerId;
  final int currentPlayerIndex;
  final List<int> whiteDice; // 2 white dice values
  final List<int> colorDice; // 4 color dice values (red, yellow, green, blue)
  final int roundNumber;
  final Set<QwixxColor> globalLockedRows; // Rows locked by any player

  const QwixxDigitalState({
    this.phase = QwixxDigitalPhase.setup,
    this.playerOrder = const [],
    this.playerStates = const {},
    this.activePlayerId,
    this.currentPlayerIndex = 0,
    this.whiteDice = const [1, 1],
    this.colorDice = const [1, 1, 1, 1],
    this.roundNumber = 1,
    this.globalLockedRows = const {},
  });

  QwixxDigitalState copyWith({
    QwixxDigitalPhase? phase,
    List<String>? playerOrder,
    Map<String, QwixxDigitalPlayerState>? playerStates,
    String? activePlayerId,
    int? currentPlayerIndex,
    List<int>? whiteDice,
    List<int>? colorDice,
    int? roundNumber,
    Set<QwixxColor>? globalLockedRows,
  }) {
    return QwixxDigitalState(
      phase: phase ?? this.phase,
      playerOrder: playerOrder ?? this.playerOrder,
      playerStates: playerStates ?? this.playerStates,
      activePlayerId: activePlayerId ?? this.activePlayerId,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      whiteDice: whiteDice ?? this.whiteDice,
      colorDice: colorDice ?? this.colorDice,
      roundNumber: roundNumber ?? this.roundNumber,
      globalLockedRows: globalLockedRows ?? this.globalLockedRows,
    );
  }

  Map<String, dynamic> toMap() => {
    'phase': phase.name,
    'playerOrder': playerOrder,
    'playerStates': playerStates.map((k, v) => MapEntry(k, v.toMap())),
    'activePlayerId': activePlayerId,
    'currentPlayerIndex': currentPlayerIndex,
    'whiteDice': whiteDice,
    'colorDice': colorDice,
    'roundNumber': roundNumber,
    'globalLockedRows': globalLockedRows.map((e) => e.name).toList(),
  };

  factory QwixxDigitalState.fromMap(Map<String, dynamic> map) =>
      QwixxDigitalState(
        phase: QwixxDigitalPhase.values.firstWhere(
          (e) => e.name == map['phase'],
          orElse: () => QwixxDigitalPhase.setup,
        ),
        playerOrder: List<String>.from(map['playerOrder'] ?? []),
        playerStates: (map['playerStates'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(
            k,
            QwixxDigitalPlayerState.fromMap(v as Map<String, dynamic>),
          ),
        ),
        activePlayerId: map['activePlayerId'],
        currentPlayerIndex: map['currentPlayerIndex'] ?? 0,
        whiteDice: List<int>.from(map['whiteDice'] ?? [1, 1]),
        colorDice: List<int>.from(map['colorDice'] ?? [1, 1, 1, 1]),
        roundNumber: map['roundNumber'] ?? 1,
        globalLockedRows: (map['globalLockedRows'] as List? ?? [])
            .map((e) => QwixxColor.values.firstWhere((c) => c.name == e))
            .toSet(),
      );

  /// White dice sum.
  int get whiteSum => whiteDice[0] + whiteDice[1];

  /// Color dice sums (white + color die for each color).
  Map<QwixxColor, int> get colorSums => {
    QwixxColor.red: whiteDice[0] + colorDice[0],
    QwixxColor.yellow: whiteDice[1] + colorDice[1],
    QwixxColor.green: whiteDice[0] + colorDice[2],
    QwixxColor.blue: whiteDice[1] + colorDice[3],
  };
}

/// Core engine for digital Qwixx.
class QwixxDigitalEngine {
  final Random _random = Random();

  QwixxDigitalState initializeGame(List<String> playerIds) {
    return QwixxDigitalState(
      playerOrder: playerIds,
      playerStates: {
        for (final pid in playerIds) pid: QwixxDigitalPlayerState.initial(),
      },
      activePlayerId: playerIds.first,
      phase: QwixxDigitalPhase.rolling,
    );
  }

  /// Roll all 6 dice.
  QwixxDigitalState rollDice(QwixxDigitalState state) {
    return state.copyWith(
      whiteDice: [_random.nextInt(6) + 1, _random.nextInt(6) + 1],
      colorDice: [
        _random.nextInt(6) + 1, // red
        _random.nextInt(6) + 1, // yellow
        _random.nextInt(6) + 1, // green
        _random.nextInt(6) + 1, // blue
      ],
      phase: QwixxDigitalPhase.whiteChoice,
    );
  }

  /// Active player crosses off a number using white dice sum.
  QwixxDigitalState crossWhiteSum(
    QwixxDigitalState state,
    String playerId,
    QwixxColor color,
  ) {
    final sum = state.whiteSum;
    return _crossNumber(state, playerId, color, sum);
  }

  /// Active player crosses off using white + color die combination.
  QwixxDigitalState crossColorSum(
    QwixxDigitalState state,
    String playerId,
    QwixxColor color,
  ) {
    final sum = state.colorSums[color]!;
    return _crossNumber(state, playerId, color, sum);
  }

  /// Cross off a number for a player.
  QwixxDigitalState _crossNumber(
    QwixxDigitalState state,
    String playerId,
    QwixxColor color,
    int number,
  ) {
    if (state.globalLockedRows.contains(color)) return state;

    final pState = state.playerStates[playerId]!;
    final row = pState.rows[color]!;
    if (!row.canCross(number)) return state;

    final newCrossed = [...row.crossedNumbers, number];
    var newRow = row.copyWith(crossedNumbers: newCrossed);

    // Auto-lock if 5+ crosses and last number crossed
    var newLockedRows = Set<QwixxColor>.from(state.globalLockedRows);
    if (newRow.canLock) {
      newRow = newRow.copyWith(isLocked: true);
      newLockedRows.add(color);
    }

    final newRows = Map<QwixxColor, QwixxRowState>.from(pState.rows);
    newRows[color] = newRow;

    final newStates = Map<String, QwixxDigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(rows: newRows);

    return state.copyWith(
      playerStates: newStates,
      globalLockedRows: newLockedRows,
    );
  }

  /// Skip white/color phase (player doesn't want to cross anything).
  QwixxDigitalState skipPhase(QwixxDigitalState state) {
    if (state.phase == QwixxDigitalPhase.whiteChoice) {
      return state.copyWith(phase: QwixxDigitalPhase.colorChoice);
    }
    if (state.phase == QwixxDigitalPhase.colorChoice) {
      // Active player must cross at least one OR take a penalty
      return state.copyWith(phase: QwixxDigitalPhase.otherPlayers);
    }
    return state;
  }

  /// Add a penalty to the active player.
  QwixxDigitalState addPenalty(QwixxDigitalState state, String playerId) {
    final pState = state.playerStates[playerId]!;
    final newStates = Map<String, QwixxDigitalPlayerState>.from(
      state.playerStates,
    );
    newStates[playerId] = pState.copyWith(penalties: pState.penalties + 1);
    return state.copyWith(playerStates: newStates);
  }

  /// End the current round, advance to next player.
  QwixxDigitalState endRound(QwixxDigitalState state) {
    // Check game end: 2 locked rows OR 4 penalties by any player
    if (_isGameOver(state)) {
      return state.copyWith(phase: QwixxDigitalPhase.finished);
    }

    final nextIdx = (state.currentPlayerIndex + 1) % state.playerOrder.length;
    return state.copyWith(
      currentPlayerIndex: nextIdx,
      activePlayerId: state.playerOrder[nextIdx],
      roundNumber: state.roundNumber + 1,
      phase: QwixxDigitalPhase.rolling,
    );
  }

  bool _isGameOver(QwixxDigitalState state) {
    if (state.globalLockedRows.length >= 2) return true;
    for (final pState in state.playerStates.values) {
      if (pState.penalties >= 4) return true;
    }
    return false;
  }
}
