/// Phase 10 game variants.
enum Phase10Variant {
  original, // Classic Phase 10
  masters, // Phase 10 Masters
  levelUp, // Level Up variant
  duel, // Phase 10 Duel
  custom, // User defined
}

class Phase10Phase {
  final int number;
  final String description;

  const Phase10Phase({required this.number, required this.description});

  static List<Phase10Phase> get values => Phase10PhaseSet.original.phases;

  String get title => 'Phase $number';

  String get name => title;

  int get index => number - 1;

  Map<String, dynamic> toJson() => {
    'number': number,
    'description': description,
  };

  factory Phase10Phase.fromJson(Map<String, dynamic> json) {
    return Phase10Phase(
      number: json['number'] as int,
      description: json['description'] as String,
    );
  }
}

class Phase10PhaseSet {
  final String name;
  final List<Phase10Phase> phases;

  const Phase10PhaseSet({required this.name, required this.phases});

  static const original = Phase10PhaseSet(
    name: 'Original',
    phases: [
      Phase10Phase(number: 1, description: '2 sets of 3'),
      Phase10Phase(number: 2, description: '1 set of 3 + 1 run of 4'),
      Phase10Phase(number: 3, description: '1 set of 4 + 1 run of 4'),
      Phase10Phase(number: 4, description: '1 run of 7'),
      Phase10Phase(number: 5, description: '1 run of 8'),
      Phase10Phase(number: 6, description: '1 run of 9'),
      Phase10Phase(number: 7, description: '2 sets of 4'),
      Phase10Phase(number: 8, description: '7 cards of one colour'),
      Phase10Phase(number: 9, description: '1 set of 5 + 1 set of 2'),
      Phase10Phase(number: 10, description: '1 set of 5 + 1 set of 3'),
    ],
  );

  static const masters = Phase10PhaseSet(
    name: 'Masters',
    phases: [
      Phase10Phase(number: 1, description: '4 Pairs'),
      Phase10Phase(number: 2, description: '6 cards of one color'),
      Phase10Phase(number: 3, description: '1 set of 4 + 1 run of 4'),
      Phase10Phase(number: 4, description: '1 run of 8'),
      Phase10Phase(number: 5, description: '7 cards of one color'),
      Phase10Phase(number: 6, description: '1 run of 9'),
      Phase10Phase(number: 7, description: '2 sets of 4'),
      Phase10Phase(number: 8, description: '1 color run of 7'),
      Phase10Phase(number: 9, description: '1 set of 5 + 1 pair'),
      Phase10Phase(number: 10, description: '1 set of 5 + 1 set of 3'),
    ],
  );
}

class Phase10PlayerState {
  final int currentPhase; // 1-indexed
  final int totalScore;
  final Set<int> completedPhases; // For variants where you can skip or choose

  const Phase10PlayerState({
    this.currentPhase = 1,
    this.totalScore = 0,
    this.completedPhases = const {},
  });

  bool get hasCompletedAllPhases => completedPhases.length >= 10;

  Phase10PlayerState copyWith({
    int? currentPhase,
    int? totalScore,
    Set<int>? completedPhases,
  }) {
    return Phase10PlayerState(
      currentPhase: currentPhase ?? this.currentPhase,
      totalScore: totalScore ?? this.totalScore,
      completedPhases: completedPhases ?? this.completedPhases,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentPhase': currentPhase,
    'totalScore': totalScore,
    'completedPhases': completedPhases.toList(),
  };

  factory Phase10PlayerState.fromJson(Map<String, dynamic> json) {
    return Phase10PlayerState(
      currentPhase: json['currentPhase'] as int? ?? 1,
      totalScore: json['totalScore'] as int? ?? 0,
      completedPhases:
          ((json['completedPhases'] as List?)?.map((e) => e as int).toSet()) ??
          const {},
    );
  }
}

class Phase10GameState {
  final Map<String, Phase10PlayerState> playerStates;
  final Phase10Variant variant;
  final List<Phase10Phase> customPhases;

  const Phase10GameState({
    this.playerStates = const {},
    this.variant = Phase10Variant.original,
    this.customPhases = const [],
  });

  List<Phase10Phase> get activePhases {
    switch (variant) {
      case Phase10Variant.masters:
        return Phase10PhaseSet.masters.phases;
      case Phase10Variant.custom:
        return customPhases;
      case Phase10Variant.original:
      case Phase10Variant.levelUp:
      default:
        return Phase10PhaseSet.original.phases;
    }
  }

  Phase10GameState copyWith({
    Map<String, Phase10PlayerState>? playerStates,
    Phase10Variant? variant,
    List<Phase10Phase>? customPhases,
  }) {
    return Phase10GameState(
      playerStates: playerStates ?? this.playerStates,
      variant: variant ?? this.variant,
      customPhases: customPhases ?? this.customPhases,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerStates': playerStates.map((k, v) => MapEntry(k, v.toJson())),
    'variant': variant.name,
    'customPhases': customPhases.map((e) => e.toJson()).toList(),
  };

  factory Phase10GameState.fromJson(Map<String, dynamic> json) {
    return Phase10GameState(
      playerStates: (json['playerStates'] as Map<String, dynamic>).map(
        (k, v) =>
            MapEntry(k, Phase10PlayerState.fromJson(v as Map<String, dynamic>)),
      ),
      variant: Phase10Variant.values.firstWhere(
        (v) => v.name == (json['variant'] as String? ?? 'original'),
        orElse: () => Phase10Variant.original,
      ),
      customPhases:
          (json['customPhases'] as List?)
              ?.map((e) => Phase10Phase.fromJson(e))
              .toList() ??
          [],
    );
  }

  List<String> getLeaders() {
    if (playerStates.isEmpty) return [];
    final entries = playerStates.entries.toList();
    entries.sort((a, b) {
      // Logic for standing: most phases completed first, then lowest score.
      // In original/levelup, currentPhase is the indicator.
      // In masters, it might be different, but typically it's still about who finishes phase 10.
      final aPhases = a.value.completedPhases.length;
      final bPhases = b.value.completedPhases.length;

      if (variant == Phase10Variant.original ||
          variant == Phase10Variant.levelUp) {
        if (a.value.currentPhase != b.value.currentPhase) {
          return b.value.currentPhase.compareTo(a.value.currentPhase);
        }
      } else {
        if (aPhases != bPhases) return bPhases.compareTo(aPhases);
      }
      return a.value.totalScore.compareTo(b.value.totalScore);
    });
    return entries.map((e) => e.key).toList();
  }
}
