/// Card categories for BuzzTap – a high-energy party drinking game.
enum BuzzTapCategory {
  warmup, // Light icebreakers
  party, // General party challenges
  hot, // More daring/hot tasks
  extreme, // Extreme challenges
}

/// A single BuzzTap challenge card.
class BuzzTapCard {
  final String id;
  final String text; // Challenge text. Use {0}, {1} for player names.
  final String? emoji; // Visual icon
  final String? explanation; // Detailed explanation
  final int sips; // Number of sips
  final BuzzTapCategory category;
  final int minPlayers;

  const BuzzTapCard({
    required this.id,
    required this.text,
    this.emoji,
    this.explanation,
    this.sips = 1,
    required this.category,
    this.minPlayers = 2,
  });

  String get key => 'bt_card_$id';
  String get explanationKey => 'bt_card_${id}_expl';

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'emoji': emoji,
    'explanation': explanation,
    'sips': sips,
    'category': category.name,
    'minPlayers': minPlayers,
  };

  factory BuzzTapCard.fromJson(Map<String, dynamic> json) {
    return BuzzTapCard(
      id: json['id'] as String,
      text: json['text'] as String,
      emoji: json['emoji'] as String?,
      explanation: json['explanation'] as String?,
      sips: json['sips'] as int? ?? 1,
      category: BuzzTapCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => BuzzTapCategory.warmup,
      ),
      minPlayers: json['minPlayers'] as int? ?? 2,
    );
  }
}

class BuzzTapGameState {
  final List<BuzzTapCategory> selectedCategories;
  final List<BuzzTapCard> playedCards;
  final Map<String, int> playerSips;
  final bool optimizeForTwoPlayers;

  const BuzzTapGameState({
    this.selectedCategories = const [
      BuzzTapCategory.warmup,
      BuzzTapCategory.party,
    ],
    this.playedCards = const [],
    this.playerSips = const {},
    this.optimizeForTwoPlayers = false,
  });

  BuzzTapGameState copyWith({
    List<BuzzTapCategory>? selectedCategories,
    List<BuzzTapCard>? playedCards,
    Map<String, int>? playerSips,
    bool? optimizeForTwoPlayers,
  }) {
    return BuzzTapGameState(
      selectedCategories: selectedCategories ?? this.selectedCategories,
      playedCards: playedCards ?? this.playedCards,
      playerSips: playerSips ?? this.playerSips,
      optimizeForTwoPlayers:
          optimizeForTwoPlayers ?? this.optimizeForTwoPlayers,
    );
  }
}

/// The BuzzTap card database.
const List<BuzzTapCard> buzzTapDatabase = [
  // ─── Warmup ───
  BuzzTapCard(
    id: 'w001',
    emoji: '👋',
    text:
        '{0}, introduce yourself with a fake stage name. The group chooses if it fits.',
    sips: 2,
    category: BuzzTapCategory.warmup,
    minPlayers: 3,
  ),
  BuzzTapCard(
    id: 'w002',
    emoji: '🍹',
    text: 'Everyone who has a drink in their hand right now takes a sip.',
    sips: 1,
    category: BuzzTapCategory.warmup,
    minPlayers: 3,
  ),
  BuzzTapCard(
    id: 'w003',
    emoji: '📱',
    text: '{0}, show the group your last saved photo. Embarrassing? 2 sips.',
    sips: 2,
    category: BuzzTapCategory.warmup,
  ),
  BuzzTapCard(
    id: 'w004',
    emoji: '👂',
    text: '{0}, tell a secret about {1}. If {1} denies it, you drink 3.',
    sips: 3,
    category: BuzzTapCategory.warmup,
  ),
  BuzzTapCard(
    id: 'w005',
    emoji: '🕒',
    text: 'Last person to arrive at this party takes 2 sips.',
    sips: 2,
    category: BuzzTapCategory.warmup,
    minPlayers: 3,
  ),

  // ─── Party ───
  BuzzTapCard(
    id: 'p001',
    emoji: '🔥',
    text:
        'Hot Seat! {0} has 30 seconds to answer any questions from the group. One skip = 1 sip.',
    sips: 1,
    category: BuzzTapCategory.party,
    minPlayers: 3,
  ),
  BuzzTapCard(
    id: 'p002',
    emoji: '💃',
    text: '{0}, show us your best dance move. If nobody joins in, take 3 sips.',
    sips: 3,
    category: BuzzTapCategory.party,
  ),
  BuzzTapCard(
    id: 'p003',
    emoji: '🎤',
    text:
        'Karaoke Time! {0} must sing the chorus of a popular song. Group votes on the quality.',
    sips: 2,
    category: BuzzTapCategory.party,
    minPlayers: 3,
  ),
  BuzzTapCard(
    id: 'p004',
    emoji: '🤫',
    text: 'Quiet Game: The next person to speak takes 3 sips.',
    sips: 3,
    category: BuzzTapCategory.party,
  ),
  BuzzTapCard(
    id: 'p005',
    emoji: '🍻',
    text:
        'Cheers! Everyone chooses a partner and toasts to something they like about them.',
    sips: 1,
    category: BuzzTapCategory.party,
  ),

  // ─── Hot ───
  BuzzTapCard(
    id: 'h001',
    emoji: '👀',
    text: '{0}, who here is the most attractive? That person gives out 3 sips.',
    sips: 0,
    category: BuzzTapCategory.hot,
    minPlayers: 3,
  ),
  BuzzTapCard(
    id: 'h002',
    emoji: '💋',
    text:
        '{0} and {1}, 10 seconds of intense eye contact. First to look away drinks 3.',
    sips: 3,
    category: BuzzTapCategory.hot,
  ),
  BuzzTapCard(
    id: 'h003',
    emoji: '🔞',
    text: '{0}, what is your weirdest turn-on? Don\'t want to say? Drink 5.',
    sips: 5,
    category: BuzzTapCategory.hot,
  ),
  BuzzTapCard(
    id: 'h004',
    emoji: '💘',
    text: '{0}, text your ex "I miss you". Refuse? Finish your drink.',
    sips: 10,
    category: BuzzTapCategory.hot,
  ),
  BuzzTapCard(
    id: 'h005',
    emoji: '🖤',
    text:
        'Truth or Drink: {0} asks {1} a spicy question. Either {1} answers or drinks 4.',
    sips: 4,
    category: BuzzTapCategory.hot,
  ),

  // ─── Extreme ───
  BuzzTapCard(
    id: 'e001',
    emoji: '🧨',
    text: 'Shot Time! {0} chooses someone to take a shot with.',
    sips: 0,
    category: BuzzTapCategory.extreme,
  ),
  BuzzTapCard(
    id: 'e002',
    emoji: '💀',
    text: '{0}, let {1} post anything they want on your social media story.',
    sips: 0,
    category: BuzzTapCategory.extreme,
  ),
  BuzzTapCard(
    id: 'e003',
    emoji: '🌪️',
    text:
        'Swapped! {0} and {1} must swap an item of clothing for the next 3 rounds.',
    sips: 0,
    category: BuzzTapCategory.extreme,
  ),
  BuzzTapCard(
    id: 'e004',
    emoji: '🤡',
    text: '{0}, let the group draw a small mustache on you with a marker.',
    sips: 0,
    category: BuzzTapCategory.extreme,
    minPlayers: 3,
  ),
];
