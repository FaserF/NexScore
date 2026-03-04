/// Phase 10 game variants.
enum Phase10Variant {
  original, // Classic Phase 10 – phases 1 through 10 in order
  masters, // Phase 10 Masters – players choose from any of the 10 master phases each round
  duel, // Phase 10 Duel – 2-player head-to-head, phases chosen strategically
}

/// The 10 standard phases with their official descriptions.
enum Phase10Phase {
  phase1,
  phase2,
  phase3,
  phase4,
  phase5,
  phase6,
  phase7,
  phase8,
  phase9,
  phase10,
}

extension Phase10PhaseExt on Phase10Phase {
  int get number => index + 1;

  String get title {
    switch (this) {
      case Phase10Phase.phase1:
        return 'Phase 1';
      case Phase10Phase.phase2:
        return 'Phase 2';
      case Phase10Phase.phase3:
        return 'Phase 3';
      case Phase10Phase.phase4:
        return 'Phase 4';
      case Phase10Phase.phase5:
        return 'Phase 5';
      case Phase10Phase.phase6:
        return 'Phase 6';
      case Phase10Phase.phase7:
        return 'Phase 7';
      case Phase10Phase.phase8:
        return 'Phase 8';
      case Phase10Phase.phase9:
        return 'Phase 9';
      case Phase10Phase.phase10:
        return 'Phase 10';
    }
  }

  String get description {
    switch (this) {
      case Phase10Phase.phase1:
        return '2 sets of 3';
      case Phase10Phase.phase2:
        return '1 set of 3 + 1 run of 4';
      case Phase10Phase.phase3:
        return '1 set of 4 + 1 run of 4';
      case Phase10Phase.phase4:
        return '1 run of 7';
      case Phase10Phase.phase5:
        return '1 run of 8';
      case Phase10Phase.phase6:
        return '1 run of 9';
      case Phase10Phase.phase7:
        return '2 sets of 4';
      case Phase10Phase.phase8:
        return '7 cards of one colour';
      case Phase10Phase.phase9:
        return '1 set of 5 + 1 set of 2';
      case Phase10Phase.phase10:
        return '1 set of 5 + 1 set of 3';
    }
  }
}

class Phase10PlayerState {
  final int currentPhase; // 1-indexed, 1–10 (Original) or 1–10 masters
  final int totalScore;
  final Set<int>
  completedPhases; // For Masters: which phases have been finished

  const Phase10PlayerState({
    this.currentPhase = 1,
    this.totalScore = 0,
    this.completedPhases = const {},
  });

  Phase10PlayerState copyWith({
    int? currentPhase,
    int? totalScore,
    Set<int>? completedPhases,
    int? maxPhases,
  }) {
    return Phase10PlayerState(
      currentPhase: currentPhase ?? this.currentPhase,
      totalScore: totalScore ?? this.totalScore,
      completedPhases: completedPhases ?? this.completedPhases,
    );
  }

  bool get hasCompletedAllPhases => completedPhases.length >= 10;

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

  const Phase10GameState({
    this.playerStates = const {},
    this.variant = Phase10Variant.original,
  });

  Phase10GameState copyWith({
    Map<String, Phase10PlayerState>? playerStates,
    Phase10Variant? variant,
  }) {
    return Phase10GameState(
      playerStates: playerStates ?? this.playerStates,
      variant: variant ?? this.variant,
    );
  }

  Map<String, dynamic> toJson() => {
    'playerStates': playerStates.map((k, v) => MapEntry(k, v.toJson())),
    'variant': variant.name,
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
    );
  }

  /// Returns player IDs sorted by standing: most phases completed first,
  /// ties broken by lowest penalty score.
  List<String> getLeaders() {
    if (playerStates.isEmpty) return [];
    final entries = playerStates.entries.toList();
    entries.sort((a, b) {
      final aPhases = variant == Phase10Variant.original
          ? a.value.currentPhase
          : a.value.completedPhases.length;
      final bPhases = variant == Phase10Variant.original
          ? b.value.currentPhase
          : b.value.completedPhases.length;

      if (aPhases != bPhases) return bPhases.compareTo(aPhases);
      return a.value.totalScore.compareTo(b.value.totalScore);
    });
    return entries.map((e) => e.key).toList();
  }
}
