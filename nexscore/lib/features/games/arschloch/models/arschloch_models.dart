// Arschloch card game – rank tracking module.
// Also known as "President" (EN) / "Asshole" (EN colloquial).
//
// Rank after each round:
//   1st to shed all cards = President (Präsident)
//   2nd = Vice President (Vizepräsident)
//   ...
//   2nd-to-last = Vice Arschloch (Vize-Arschloch)
//   Last = Arschloch
//
// Card passing between rounds (new to old hierarchy):
//   Arschloch gives 2 best cards to President.
//   President gives 2 lowest cards to Arschloch.
//   Vize-Arschloch gives 1 best card to Vize-President.
//   (For 5+ players)

enum ArschlochRank {
  president, // 1st – Präsident
  vicePresident, // 2nd – Vizepräsident
  neutral, // Middle ranks
  viceArschloch, // 2nd-to-last – Vize-Arschloch
  arschloch, // Last – Arschloch
}

extension ArschlochRankExt on ArschlochRank {
  String labelDe() {
    switch (this) {
      case ArschlochRank.president:
        return 'Präsident';
      case ArschlochRank.vicePresident:
        return 'Vizepräsident';
      case ArschlochRank.neutral:
        return 'Bürger';
      case ArschlochRank.viceArschloch:
        return 'Vize-Arschloch';
      case ArschlochRank.arschloch:
        return 'Arschloch';
    }
  }

  String labelEn() {
    switch (this) {
      case ArschlochRank.president:
        return 'President';
      case ArschlochRank.vicePresident:
        return 'Vice President';
      case ArschlochRank.neutral:
        return 'Citizen';
      case ArschlochRank.viceArschloch:
        return 'Vice Asshole';
      case ArschlochRank.arschloch:
        return 'Asshole';
    }
  }
}

class ArschlochPlayerState {
  final int roundsAsPresident;
  final int roundsAsArschloch;
  final ArschlochRank? lastRank;
  final int
  points; // President = +2, VicePresident = +1, ViceArschloch = -1, Arschloch = -2

  const ArschlochPlayerState({
    this.roundsAsPresident = 0,
    this.roundsAsArschloch = 0,
    this.lastRank,
    this.points = 0,
  });

  ArschlochPlayerState copyWith({
    int? roundsAsPresident,
    int? roundsAsArschloch,
    ArschlochRank? lastRank,
    int? points,
  }) {
    return ArschlochPlayerState(
      roundsAsPresident: roundsAsPresident ?? this.roundsAsPresident,
      roundsAsArschloch: roundsAsArschloch ?? this.roundsAsArschloch,
      lastRank: lastRank ?? this.lastRank,
      points: points ?? this.points,
    );
  }

  Map<String, dynamic> toJson() => {
    'roundsAsPresident': roundsAsPresident,
    'roundsAsArschloch': roundsAsArschloch,
    'lastRank': lastRank?.name,
    'points': points,
  };

  factory ArschlochPlayerState.fromJson(Map<String, dynamic> json) {
    return ArschlochPlayerState(
      roundsAsPresident: json['roundsAsPresident'] as int? ?? 0,
      roundsAsArschloch: json['roundsAsArschloch'] as int? ?? 0,
      lastRank: json['lastRank'] != null
          ? ArschlochRank.values.firstWhere(
              (r) => r.name == json['lastRank'],
              orElse: () => ArschlochRank.neutral,
            )
          : null,
      points: json['points'] as int? ?? 0,
    );
  }
}

class ArschlochRound {
  final int roundIndex;
  // playerId → rank (1 = first to shed, last = Arschloch)
  final Map<String, int> finishOrder;

  const ArschlochRound({required this.roundIndex, required this.finishOrder});

  Map<String, dynamic> toJson() => {
    'roundIndex': roundIndex,
    'finishOrder': finishOrder,
  };

  factory ArschlochRound.fromJson(Map<String, dynamic> json) {
    return ArschlochRound(
      roundIndex: json['roundIndex'] as int,
      finishOrder: Map<String, int>.from(json['finishOrder'] as Map),
    );
  }
}

class ArschlochGameState {
  final Map<String, ArschlochPlayerState> playerStates;
  final List<ArschlochRound> rounds;
  final bool usePoints;
  final int cardSwappingCount; // 1 or 2 (default 2)
  final Map<ArschlochRank, String>? customRankNames;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool setupDone;

  const ArschlochGameState({
    this.playerStates = const {},
    this.rounds = const [],
    this.usePoints = true,
    this.cardSwappingCount = 2,
    this.customRankNames,
    this.startedAt,
    this.endedAt,
    this.setupDone = false,
  });

  bool get canUndo => rounds.isNotEmpty;

  ArschlochGameState copyWith({
    Map<String, ArschlochPlayerState>? playerStates,
    List<ArschlochRound>? rounds,
    bool? usePoints,
    int? cardSwappingCount,
    Map<ArschlochRank, String>? customRankNames,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? setupDone,
  }) {
    return ArschlochGameState(
      playerStates: playerStates ?? this.playerStates,
      rounds: rounds ?? this.rounds,
      usePoints: usePoints ?? this.usePoints,
      cardSwappingCount: cardSwappingCount ?? this.cardSwappingCount,
      customRankNames: customRankNames ?? this.customRankNames,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      setupDone: setupDone ?? this.setupDone,
    );
  }

  /// Derive rank from finish position given total player count.
  static ArschlochRank rankFromPosition(int position, int totalPlayers) {
    if (position == 1) return ArschlochRank.president;
    if (position == 2 && totalPlayers == 2) return ArschlochRank.arschloch;
    if (position == 2 && totalPlayers >= 4) return ArschlochRank.vicePresident;
    if (position == totalPlayers) return ArschlochRank.arschloch;
    if (position == totalPlayers - 1 && totalPlayers >= 3) {
      return ArschlochRank.viceArschloch;
    }
    return ArschlochRank.neutral;
  }

  /// Point value for a rank.
  static int pointsForRank(ArschlochRank rank) {
    switch (rank) {
      case ArschlochRank.president:
        return 2;
      case ArschlochRank.vicePresident:
        return 1;
      case ArschlochRank.neutral:
        return 0;
      case ArschlochRank.viceArschloch:
        return -1;
      case ArschlochRank.arschloch:
        return -2;
    }
  }

  /// Card exchange instructions for the next round.
  static List<String> cardExchangeInstructions(
    Map<String, int> lastFinishOrder,
    Map<String, String> playerNames,
    int totalPlayers,
    int cardSwappingCount,
  ) {
    if (totalPlayers < 2 || cardSwappingCount == 0) return [];
    final sorted = lastFinishOrder.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    if (sorted.isEmpty) return [];

    final instructions = <String>[];
    final president = sorted.first.key;
    final arschloch = sorted.last.key;

    instructions.add(
      '${playerNames[arschloch] ?? arschloch} gibt $cardSwappingCount beste Karten an ${playerNames[president] ?? president} (Arschloch → Präsident)',
    );
    instructions.add(
      '${playerNames[president] ?? president} gibt $cardSwappingCount niedrigste Karten zurück',
    );

    if (totalPlayers >= 5 && cardSwappingCount > 0) {
      final vicePres = sorted[1].key;
      final viceArsch = sorted[sorted.length - 2].key;
      final viceCount = cardSwappingCount > 1 ? 1 : 0; // Usually 1 if pres is 2
      if (viceCount > 0) {
        instructions.add(
          '${playerNames[viceArsch] ?? viceArsch} gibt $viceCount beste Karte an ${playerNames[vicePres] ?? vicePres}',
        );
      }
    }

    return instructions;
  }

  /// Sorted player IDs by total points (highest first), then fewest arschloch rounds.
  List<String> getLeaders() {
    if (playerStates.isEmpty) return [];
    final entries = playerStates.entries.toList();
    entries.sort((a, b) {
      if (b.value.points != a.value.points) {
        return b.value.points.compareTo(a.value.points);
      }
      return a.value.roundsAsArschloch.compareTo(b.value.roundsAsArschloch);
    });
    return entries.map((e) => e.key).toList();
  }

  Map<String, dynamic> toJson() => {
    'playerStates': playerStates.map((k, v) => MapEntry(k, v.toJson())),
    'rounds': rounds.map((r) => r.toJson()).toList(),
    'usePoints': usePoints,
    'cardSwappingCount': cardSwappingCount,
    'customRankNames': customRankNames?.map((k, v) => MapEntry(k.name, v)),
  };

  factory ArschlochGameState.fromJson(Map<String, dynamic> json) {
    return ArschlochGameState(
      playerStates: (json['playerStates'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          k,
          ArschlochPlayerState.fromJson(v as Map<String, dynamic>),
        ),
      ),
      rounds: (json['rounds'] as List)
          .map((r) => ArschlochRound.fromJson(r as Map<String, dynamic>))
          .toList(),
      usePoints: json['usePoints'] as bool? ?? true,
      cardSwappingCount: json['cardSwappingCount'] as int? ?? 2,
      customRankNames: json['customRankNames'] != null
          ? (json['customRankNames'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(
                ArschlochRank.values.firstWhere((r) => r.name == k),
                v as String,
              ),
            )
          : null,
    );
  }
}
