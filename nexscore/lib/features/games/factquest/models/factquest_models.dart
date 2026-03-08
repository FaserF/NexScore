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

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'explanation': explanation,
    'sourceUrl': sourceUrl,
    'emoji': emoji,
    'category': category.name,
  };

  factory FactQuestCard.fromMap(Map<String, dynamic> map) {
    return FactQuestCard(
      id: map['id'] as String,
      text: map['text'] as String,
      explanation: map['explanation'] as String,
      sourceUrl: map['sourceUrl'] as String,
      emoji: map['emoji'] as String?,
      category: FactQuestCategory.values.firstWhere(
        (e) => e.name == map['category'],
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
  final Map<String, int> playerSips; // Track drinks for multiplayer clients

  const FactQuestGameState({
    this.activePlayerIds = const [],
    this.selectedCategories = const [
      FactQuestCategory.randomFacts,
      FactQuestCategory.dumbWaysToDie,
    ],
    this.playedCards = const [],
    this.playerSips = const {},
  });

  FactQuestGameState copyWith({
    List<String>? activePlayerIds,
    List<FactQuestCategory>? selectedCategories,
    List<FactQuestCard>? playedCards,
    Map<String, int>? playerSips,
  }) {
    return FactQuestGameState(
      activePlayerIds: activePlayerIds ?? this.activePlayerIds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      playedCards: playedCards ?? this.playedCards,
      playerSips: playerSips ?? this.playerSips,
    );
  }

  Map<String, dynamic> toMap() => {
    'activePlayerIds': activePlayerIds,
    'selectedCategories': selectedCategories.map((e) => e.name).toList(),
    'playedCards': playedCards.map((e) => e.toMap()).toList(),
    'playerSips': playerSips,
  };

  factory FactQuestGameState.fromMap(Map<String, dynamic> map) =>
      FactQuestGameState(
        activePlayerIds: List<String>.from(map['activePlayerIds'] ?? []),
        selectedCategories: (map['selectedCategories'] as List? ?? [])
            .map((e) => FactQuestCategory.values.firstWhere((c) => c.name == e))
            .toList(),
        playedCards: (map['playedCards'] as List? ?? [])
            .map((e) => FactQuestCard.fromMap(e as Map<String, dynamic>))
            .toList(),
        playerSips: Map<String, int>.from(map['playerSips'] ?? {}),
      );

  FactQuestCard? get currentCard =>
      playedCards.isNotEmpty ? playedCards.last : null;
}
