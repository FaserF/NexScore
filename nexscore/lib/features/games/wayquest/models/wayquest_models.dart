/// Categories for WayQuest – the road trip entertainment game.
enum WayQuestCategory {
  deepTalks, // Thought-provoking personal questions
  wouldYouRather, // Tough and funny choices
  roadChallenges, // Interactive tasks based on the environment
  hypotheticals, // "What would you do if..." scenarios
  storyStarters, // Prompts for building a story together
}

/// A single WayQuest card.
class WayQuestCard {
  final String id;
  final String
  text; // Question or challenge text (use {0}, {1} for player names if needed)
  final String? emoji;
  final WayQuestCategory category;
  final int minPlayers;

  const WayQuestCard({
    required this.id,
    required this.text,
    this.emoji,
    required this.category,
    this.minPlayers = 2,
  });

  String get key => 'wq_card_$id';

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'emoji': emoji,
    'category': category.name,
    'minPlayers': minPlayers,
  };

  factory WayQuestCard.fromJson(Map<String, dynamic> json) {
    return WayQuestCard(
      id: json['id'] as String,
      text: json['text'] as String,
      emoji: json['emoji'] as String?,
      category: WayQuestCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => WayQuestCategory.deepTalks,
      ),
      minPlayers: json['minPlayers'] as int? ?? 2,
    );
  }
}

class WayQuestGameState {
  final List<String> activePlayerIds;
  final List<WayQuestCategory> selectedCategories;
  final List<WayQuestCard> playedCards;
  final bool canUndo;
  final Map<String, int> scores; // Points per player (playerId -> score)
  final String? lastWinnerId; // ID of the player who won the most recent card
  final DateTime? startedAt;
  final DateTime? endedAt;

  const WayQuestGameState({
    this.activePlayerIds = const [],
    this.selectedCategories = const [
      WayQuestCategory.deepTalks,
      WayQuestCategory.wouldYouRather,
    ],
    this.playedCards = const [],
    this.canUndo = false,
    this.scores = const {},
    this.lastWinnerId,
    this.startedAt,
    this.endedAt,
  });

  WayQuestGameState copyWith({
    List<String>? activePlayerIds,
    List<WayQuestCategory>? selectedCategories,
    List<WayQuestCard>? playedCards,
    bool? canUndo,
    Map<String, int>? scores,
    String? lastWinnerId,
    DateTime? startedAt,
    DateTime? endedAt,
  }) {
    return WayQuestGameState(
      activePlayerIds: activePlayerIds ?? this.activePlayerIds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      playedCards: playedCards ?? this.playedCards,
      canUndo: canUndo ?? this.canUndo,
      scores: scores ?? this.scores,
      lastWinnerId: lastWinnerId ?? this.lastWinnerId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'activePlayerIds': activePlayerIds,
    'selectedCategories': selectedCategories.map((e) => e.name).toList(),
    'playedCards': playedCards.map((e) => e.toJson()).toList(),
    'canUndo': canUndo,
    'scores': scores,
    'lastWinnerId': lastWinnerId,
    'startedAt': startedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
  };

  factory WayQuestGameState.fromMap(Map<String, dynamic> map) =>
      WayQuestGameState(
        activePlayerIds: List<String>.from(map['activePlayerIds'] ?? []),
        selectedCategories: (map['selectedCategories'] as List? ?? [])
            .map((e) => WayQuestCategory.values.firstWhere((c) => c.name == e))
            .toList(),
        playedCards: (map['playedCards'] as List? ?? [])
            .map((e) => WayQuestCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        canUndo: map['canUndo'] as bool? ?? false,
        scores: Map<String, int>.from(map['scores'] ?? {}),
        lastWinnerId: map['lastWinnerId'] as String?,
        startedAt: map['startedAt'] != null
            ? DateTime.parse(map['startedAt'])
            : null,
        endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null,
      );

  WayQuestCard? get currentCard =>
      playedCards.isNotEmpty ? playedCards.last : null;
}
