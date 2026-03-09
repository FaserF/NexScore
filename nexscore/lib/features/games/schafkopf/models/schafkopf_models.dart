/// All Schafkopf game types supported including doubles and solo variants.
enum SchafkopfGameType { sauspiel, wenz, farbwenz, geier, solo, tout, sie }

/// Represents a single round of Schafkopf with full Bavarian payout calculation.
/// Payouts are in Euro-cents (base = 0.10 €). Solo variants carry a 0.50 € premium.
class SchafkopfRound {
  final int roundIndex;
  final SchafkopfGameType gameType;
  final String activePlayerId;
  final String? partnerPlayerId;
  final Map<String, int> points;
  final bool schneider;
  final bool schwarz;
  final int runners;
  final double baseTariff;
  final bool isBockRound;
  final bool isMussSpiel;

  const SchafkopfRound({
    required this.roundIndex,
    required this.gameType,
    required this.activePlayerId,
    this.partnerPlayerId,
    required this.points,
    this.schneider = false,
    this.schwarz = false,
    this.runners = 0,
    this.baseTariff = 0.10,
    this.isBockRound = false,
    this.isMussSpiel = false,
  });

  Map<String, double> calculatePayouts(List<String> allPlayerIds) {
    double gameValue = baseTariff;

    if (gameType != SchafkopfGameType.sauspiel) {
      gameValue *= 2;
    }
    if (schneider) gameValue += baseTariff;
    if (schwarz) gameValue += baseTariff;
    if (runners >= 3) {
      gameValue += (runners * baseTariff);
    }

    if (isBockRound) gameValue *= 2;

    final int activeTeamPoints =
        (points[activePlayerId] ?? 0) + (points[partnerPlayerId] ?? 0);
    final bool activeWon = activeTeamPoints > 60;

    final Map<String, double> payouts = {for (var id in allPlayerIds) id: 0.0};

    if (gameType == SchafkopfGameType.sauspiel) {
      final double perPlayerValue = activeWon ? gameValue : -gameValue;
      payouts[activePlayerId] = perPlayerValue;
      if (partnerPlayerId != null) {
        payouts[partnerPlayerId!] = perPlayerValue;
      }
      final opponents = allPlayerIds
          .where((id) => id != activePlayerId && id != partnerPlayerId)
          .toList();
      for (final opId in opponents) {
        payouts[opId] = -perPlayerValue;
      }
    } else {
      final double soloTotal = gameValue * 3;
      final double winAmount = activeWon ? soloTotal : -soloTotal;
      payouts[activePlayerId] = winAmount;
      final opponents = allPlayerIds
          .where((id) => id != activePlayerId)
          .toList();
      for (final opId in opponents) {
        payouts[opId] = -(winAmount / 3);
      }
    }

    return payouts;
  }

  Map<String, dynamic> toJson() => {
    'roundIndex': roundIndex,
    'gameType': gameType.name,
    'activePlayerId': activePlayerId,
    'partnerPlayerId': partnerPlayerId,
    'points': points,
    'schneider': schneider,
    'schwarz': schwarz,
    'runners': runners,
    'baseTariff': baseTariff,
    'isBockRound': isBockRound,
    'isMussSpiel': isMussSpiel,
  };

  factory SchafkopfRound.fromJson(Map<String, dynamic> json) {
    return SchafkopfRound(
      roundIndex: json['roundIndex'] as int,
      gameType: SchafkopfGameType.values.firstWhere(
        (e) => e.name == json['gameType'],
      ),
      activePlayerId: json['activePlayerId'] as String,
      partnerPlayerId: json['partnerPlayerId'] as String?,
      points: Map<String, int>.from(json['points']),
      schneider: json['schneider'] as bool? ?? false,
      schwarz: json['schwarz'] as bool? ?? false,
      runners: json['runners'] as int? ?? 0,
      baseTariff: (json['baseTariff'] as num?)?.toDouble() ?? 0.10,
      isBockRound: json['isBockRound'] as bool? ?? false,
      isMussSpiel: json['isMussSpiel'] as bool? ?? false,
    );
  }
}

class SchafkopfGameState {
  final List<SchafkopfRound> rounds;
  final double stock; // Pot in Euro
  final int bockRoundsRemaining;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool setupDone;
  final bool canUndo;

  const SchafkopfGameState({
    this.rounds = const [],
    this.stock = 0.0,
    this.bockRoundsRemaining = 0,
    this.startedAt,
    this.endedAt,
    this.setupDone = false,
    this.canUndo = false,
  });

  SchafkopfGameState copyWith({
    List<SchafkopfRound>? rounds,
    double? stock,
    int? bockRoundsRemaining,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? setupDone,
    bool? canUndo,
  }) {
    return SchafkopfGameState(
      rounds: rounds ?? this.rounds,
      stock: stock ?? this.stock,
      bockRoundsRemaining: bockRoundsRemaining ?? this.bockRoundsRemaining,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      setupDone: setupDone ?? this.setupDone,
      canUndo: canUndo ?? this.canUndo,
    );
  }

  double getPlayerBalance(String playerId, List<String> allPlayerIds) {
    double total = 0.0;
    for (final round in rounds) {
      final payouts = round.calculatePayouts(allPlayerIds);
      total += (payouts[playerId] ?? 0.0);
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
    'rounds': rounds.map((e) => e.toJson()).toList(),
    'stock': stock,
    'bockRoundsRemaining': bockRoundsRemaining,
    'canUndo': canUndo,
  };

  factory SchafkopfGameState.fromJson(Map<String, dynamic> json) {
    return SchafkopfGameState(
      rounds: (json['rounds'] as List)
          .map((e) => SchafkopfRound.fromJson(e))
          .toList(),
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
      bockRoundsRemaining: json['bockRoundsRemaining'] as int? ?? 0,
      canUndo: json['canUndo'] as bool? ?? false,
    );
  }
}
