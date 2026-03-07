enum WizardExtremeSealColor {
  red,
  yellow,
  green,
  blue,
  white,
  black;

  String get name => toString().split('.').last;
}

class WizardExtremeSeal {
  final WizardExtremeSealColor color;
  final int count;

  const WizardExtremeSeal({required this.color, required this.count});

  Map<String, dynamic> toJson() => {'color': color.name, 'count': count};

  factory WizardExtremeSeal.fromJson(Map<String, dynamic> json) {
    return WizardExtremeSeal(
      color: WizardExtremeSealColor.values.firstWhere(
        (v) => v.name == json['color'],
      ),
      count: json['count'] as int,
    );
  }
}

class WizardExtremePlayerRound {
  final List<WizardExtremeSeal> predictedSeals;
  final List<WizardExtremeSeal> actualSeals; // Seals returned from tricks won
  final int blackSeals; // Penalty seals
  final bool isBlackMagician;

  const WizardExtremePlayerRound({
    this.predictedSeals = const [],
    this.actualSeals = const [],
    this.blackSeals = 0,
    this.isBlackMagician = false,
  });

  int calculatePoints() {
    if (isBlackMagician) {
      // Black Magician starts with -4 penalty points (or -4 * count of players depending on rules)
      // Usually: -4 points for each black seal they manage to give away.
      // But standard Amigo rules: Black Magician starts with 0 and gets -3 for each black seal.
      // Actually, many variations exist. Let's stick to the common one:
      // Penalty points:
      // Leftover colored seals: -2 each
      // Leftover white seals: -4 each
      // Black seals: -3 each
      // Black Magician: Special scoring - gets - points for giving away black seals.
      // We will implement a standard customizable penalty logic.
      return -(blackSeals * 3);
    }

    int penalty = 0;

    // Compare predicted vs actual
    for (final predicted in predictedSeals) {
      final actual = actualSeals.firstWhere(
        (s) => s.color == predicted.color,
        orElse: () => WizardExtremeSeal(color: predicted.color, count: 0),
      );

      final diff = (predicted.count - actual.count).abs();
      if (diff > 0) {
        if (predicted.color == WizardExtremeSealColor.white) {
          penalty -= diff * 4;
        } else {
          penalty -= diff * 2;
        }
      }
    }

    // Any actual seals NOT predicted are also a mismatch?
    // In Wizard Extreme, you ONLY take seals you predict.
    // If you win a trick of a color you don't have a seal for, you get a BLACK seal.
    penalty -= blackSeals * 3;

    return penalty;
  }

  Map<String, dynamic> toJson() => {
    'predictedSeals': predictedSeals.map((s) => s.toJson()).toList(),
    'actualSeals': actualSeals.map((s) => s.toJson()).toList(),
    'blackSeals': blackSeals,
    'isBlackMagician': isBlackMagician,
  };

  factory WizardExtremePlayerRound.fromJson(Map<String, dynamic> json) {
    return WizardExtremePlayerRound(
      predictedSeals: (json['predictedSeals'] as List)
          .map((s) => WizardExtremeSeal.fromJson(s))
          .toList(),
      actualSeals: (json['actualSeals'] as List)
          .map((s) => WizardExtremeSeal.fromJson(s))
          .toList(),
      blackSeals: json['blackSeals'] as int? ?? 0,
      isBlackMagician: json['isBlackMagician'] as bool? ?? false,
    );
  }
}

class WizardExtremeGameState {
  final List<Map<String, WizardExtremePlayerRound>> rounds;

  const WizardExtremeGameState({this.rounds = const []});

  int getPlayerTotalScore(String playerId) {
    int total = 0;
    for (final round in rounds) {
      if (round.containsKey(playerId)) {
        total += round[playerId]!.calculatePoints();
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
    'rounds': rounds
        .map((r) => r.map((k, v) => MapEntry(k, v.toJson())))
        .toList(),
  };

  factory WizardExtremeGameState.fromJson(Map<String, dynamic> json) {
    return WizardExtremeGameState(
      rounds: (json['rounds'] as List).map((r) {
        return (r as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, WizardExtremePlayerRound.fromJson(v)),
        );
      }).toList(),
    );
  }
}
