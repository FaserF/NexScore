/// Categories for FactQuest – the road-trip trivia game.
enum FactQuestCategory {
  randomFacts, // Fascinating true facts from around the world
  dumbWaysToDie, // Bizarre but true stories of unusual deaths
}

/// A single FactQuest card with a fact, explanation, and a verifiable source URL.
class FactQuestCard {
  final String id;
  final String text; // Short fact headline (use l10n key)
  final String explanation; // Detailed explanation (use l10n key)
  final String sourceUrl; // Clickable URL for verification / further reading
  final String? emoji;
  final FactQuestCategory category;

  const FactQuestCard({
    required this.id,
    required this.text,
    required this.explanation,
    required this.sourceUrl,
    this.emoji,
    required this.category,
  });

  /// Localization key for the fact text.
  String get textKey => 'fq_card_${id}_text';

  /// Localization key for the detailed explanation.
  String get explanationKey => 'fq_card_${id}_expl';

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'explanation': explanation,
    'sourceUrl': sourceUrl,
    'emoji': emoji,
    'category': category.name,
  };

  factory FactQuestCard.fromJson(Map<String, dynamic> json) {
    return FactQuestCard(
      id: json['id'] as String,
      text: json['text'] as String,
      explanation: json['explanation'] as String,
      sourceUrl: json['sourceUrl'] as String,
      emoji: json['emoji'] as String?,
      category: FactQuestCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => FactQuestCategory.randomFacts,
      ),
    );
  }
}

/// Immutable game state for FactQuest.
class FactQuestGameState {
  final List<String> activePlayerIds;
  final List<FactQuestCategory> selectedCategories;
  final List<FactQuestCard> playedCards;

  const FactQuestGameState({
    this.activePlayerIds = const [],
    this.selectedCategories = const [
      FactQuestCategory.randomFacts,
      FactQuestCategory.dumbWaysToDie,
    ],
    this.playedCards = const [],
  });

  FactQuestGameState copyWith({
    List<String>? activePlayerIds,
    List<FactQuestCategory>? selectedCategories,
    List<FactQuestCard>? playedCards,
  }) {
    return FactQuestGameState(
      activePlayerIds: activePlayerIds ?? this.activePlayerIds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      playedCards: playedCards ?? this.playedCards,
    );
  }

  Map<String, dynamic> toMap() => {
    'activePlayerIds': activePlayerIds,
    'selectedCategories': selectedCategories.map((e) => e.name).toList(),
    'playedCards': playedCards.map((e) => e.toJson()).toList(),
  };

  factory FactQuestGameState.fromMap(Map<String, dynamic> map) =>
      FactQuestGameState(
        activePlayerIds: List<String>.from(map['activePlayerIds'] ?? []),
        selectedCategories: (map['selectedCategories'] as List? ?? [])
            .map((e) => FactQuestCategory.values.firstWhere((c) => c.name == e))
            .toList(),
        playedCards: (map['playedCards'] as List? ?? [])
            .map((e) => FactQuestCard.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  FactQuestCard? get currentCard =>
      playedCards.isNotEmpty ? playedCards.last : null;
}
