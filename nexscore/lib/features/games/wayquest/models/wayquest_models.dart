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

  const WayQuestGameState({
    this.activePlayerIds = const [],
    this.selectedCategories = const [
      WayQuestCategory.deepTalks,
      WayQuestCategory.wouldYouRather,
    ],
    this.playedCards = const [],
  });

  WayQuestGameState copyWith({
    List<String>? activePlayerIds,
    List<WayQuestCategory>? selectedCategories,
    List<WayQuestCard>? playedCards,
  }) {
    return WayQuestGameState(
      activePlayerIds: activePlayerIds ?? this.activePlayerIds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      playedCards: playedCards ?? this.playedCards,
    );
  }

  WayQuestCard? get currentCard =>
      playedCards.isNotEmpty ? playedCards.last : null;
}
