/// Card categories for SipDeck – the party drinking card game module.
enum SipDeckCategory {
  warmUp, // Easy icebreaker challenges, fun for everyone
  wildCards, // Advanced dares and creative rules
  flirty, // Playful, flirty challenges (18+)
  barNight, // Suitable for any public bar setting
  laughs, // Silly and absurd things to do or say
}

/// A single SipDeck challenge card.
class SipDeckCard {
  final String id;
  final String text; // Challenge text. Use {0}, {1} for player names.
  final int sips; // 0 = rule-based, >0 = number of sips to take
  final SipDeckCategory category;
  final bool isVirus; // Ongoing rule that persists until "cured"

  const SipDeckCard({
    required this.id,
    required this.text,
    this.sips = 1,
    required this.category,
    this.isVirus = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'sips': sips,
    'category': category.name,
    'isVirus': isVirus,
  };

  factory SipDeckCard.fromJson(Map<String, dynamic> json) {
    return SipDeckCard(
      id: json['id'] as String,
      text: json['text'] as String,
      sips: json['sips'] as int? ?? 1,
      category: SipDeckCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SipDeckCategory.warmUp,
      ),
      isVirus: json['isVirus'] as bool? ?? false,
    );
  }
}

class SipDeckGameState {
  final List<String> activePlayerIds;
  final List<SipDeckCategory> selectedCategories;
  final List<SipDeckCard> playedCards;
  final List<SipDeckCard> activeViruses;

  const SipDeckGameState({
    this.activePlayerIds = const [],
    this.selectedCategories = const [SipDeckCategory.warmUp],
    this.playedCards = const [],
    this.activeViruses = const [],
  });

  SipDeckGameState copyWith({
    List<String>? activePlayerIds,
    List<SipDeckCategory>? selectedCategories,
    List<SipDeckCard>? playedCards,
    List<SipDeckCard>? activeViruses,
  }) {
    return SipDeckGameState(
      activePlayerIds: activePlayerIds ?? this.activePlayerIds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      playedCards: playedCards ?? this.playedCards,
      activeViruses: activeViruses ?? this.activeViruses,
    );
  }
}

/// The full SipDeck card database – 50+ cards across all categories.
const List<SipDeckCard> sipDeckDatabase = [
  // ─────── Warm Up ───────
  SipDeckCard(
    id: 'w001',
    text:
        '{0}, name three things you can see that are blue. Fail? Take 2 sips.',
    sips: 2,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w002',
    text:
        'Waterfall! {0} starts. Everyone follows. Stop only when the person to your left stops.',
    sips: 0,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w003',
    text:
        '{0} gives {1} a compliment. {1} must respond in a made-up language. Fail? Take 3 sips.',
    sips: 3,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w004',
    text:
        'Group votes: who would survive a zombie apocalypse? Fewest votes = 2 sips.',
    sips: 2,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w005',
    text: '{0}, 10 seconds to name 5 animals. Miss any? Drink 1 sip per miss.',
    sips: 1,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w006',
    text: 'Thumb war! {0} vs {1}. Loser takes 2 sips.',
    sips: 2,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w007',
    text: 'Everyone wearing socks takes 1 sip.',
    sips: 1,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w008',
    text:
        '{0}, do your best celebrity impression. Bad impression? Take 3 sips.',
    sips: 3,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w009',
    text: 'Never Have I Ever: {0} starts. Go around the circle once.',
    sips: 0,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w010',
    text: '{0} and {1} have a staring contest. First to blink takes 2 sips.',
    sips: 2,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w011',
    text: 'Rock Paper Scissors tournament. Last place takes 3 sips.',
    sips: 3,
    category: SipDeckCategory.warmUp,
  ),
  SipDeckCard(
    id: 'w012',
    text:
        '{0}, mimic the person to your left for the next 2 minutes. Forget? Take 2 sips.',
    sips: 2,
    category: SipDeckCategory.warmUp,
    isVirus: true,
  ),
  SipDeckCard(
    id: 'w013',
    text: 'Group vote: who talks the most? That person takes 2 sips.',
    sips: 2,
    category: SipDeckCategory.warmUp,
  ),

  // ─────── Wild Cards ───────
  SipDeckCard(
    id: 'wc001',
    text: '{0} must speak like a pirate for the next 3 rounds, or take 4 sips.',
    sips: 4,
    category: SipDeckCategory.wildCards,
    isVirus: true,
  ),
  SipDeckCard(
    id: 'wc002',
    text:
        'Make a rule. {0} creates a rule everyone must follow this round. Break it? 2 sips.',
    sips: 2,
    category: SipDeckCategory.wildCards,
  ),
  SipDeckCard(
    id: 'wc003',
    text:
        '{0}, you have a new name: "{1}". Anyone using your real name drinks 1 sip.',
    sips: 1,
    category: SipDeckCategory.wildCards,
    isVirus: true,
  ),
  SipDeckCard(
    id: 'wc004',
    text:
        '{0} assigns one sip each to three different people. No questions asked.',
    sips: 0,
    category: SipDeckCategory.wildCards,
  ),
  SipDeckCard(
    id: 'wc005',
    text: 'CHALLENGE: {0} does 10 jumping jacks, or takes 5 sips.',
    sips: 5,
    category: SipDeckCategory.wildCards,
  ),
  SipDeckCard(
    id: 'wc006',
    text:
        'Telephone! {0} whispers a phrase, it goes around. Wrong at the end? Take 3 sips.',
    sips: 3,
    category: SipDeckCategory.wildCards,
  ),
  SipDeckCard(
    id: 'wc007',
    text:
        'Everyone on their phones: screenshot your last search. Most embarrassing? Take 3 sips.',
    sips: 3,
    category: SipDeckCategory.wildCards,
  ),
  SipDeckCard(
    id: 'wc008',
    text: '{0}, every time you laugh for the next 5 minutes, take 1 sip.',
    sips: 1,
    category: SipDeckCategory.wildCards,
    isVirus: true,
  ),
  SipDeckCard(
    id: 'wc009',
    text:
        'VIRUS CURED: The ongoing rule ends. Everyone else takes 1 sip in celebration.',
    sips: 1,
    category: SipDeckCategory.wildCards,
  ),
  SipDeckCard(
    id: 'wc010',
    text:
        '{0} draws a portrait of {1} without looking at the paper. Worst drawing? Drink 3.',
    sips: 3,
    category: SipDeckCategory.wildCards,
  ),
  SipDeckCard(
    id: 'wc011',
    text:
        'Group challenge: plank position. Last one standing gives out 5 sips.',
    sips: 5,
    category: SipDeckCategory.wildCards,
  ),

  // ─────── Flirty (18+) ───────
  SipDeckCard(
    id: 'f001',
    text:
        '{0}, give {1} a genuine compliment about their style. If you blush, take 2 sips.',
    sips: 2,
    category: SipDeckCategory.flirty,
  ),
  SipDeckCard(
    id: 'f002',
    text:
        '{0} and {1} have 30 seconds to find one thing in common. Fail? Both take 3 sips.',
    sips: 3,
    category: SipDeckCategory.flirty,
  ),
  SipDeckCard(
    id: 'f003',
    text:
        '{0}, text your most recent contact a heart emoji. Refuse? Take 2 sips.',
    sips: 2,
    category: SipDeckCategory.flirty,
  ),
  SipDeckCard(
    id: 'f004',
    text:
        'Everyone votes: cutest smile in the room. That person gives out 3 sips.',
    sips: 3,
    category: SipDeckCategory.flirty,
  ),
  SipDeckCard(
    id: 'f005',
    text: '{0}, describe your crush without naming them. Group tries to guess.',
    sips: 0,
    category: SipDeckCategory.flirty,
  ),
  SipDeckCard(
    id: 'f006',
    text: 'Truth: {0}, rate each person 1–10. Refuse? Take 4 sips.',
    sips: 4,
    category: SipDeckCategory.flirty,
  ),
  SipDeckCard(
    id: 'f007',
    text:
        'Everyone writes a one-word compliment for {0}. {0} guesses who wrote each. Wrong? 1 sip each.',
    sips: 1,
    category: SipDeckCategory.flirty,
  ),

  // ─────── Bar Night ───────
  SipDeckCard(
    id: 'b001',
    text:
        '{0} starts a toast. Everyone adds a sentence. Break the flow? Take 2 sips.',
    sips: 2,
    category: SipDeckCategory.barNight,
  ),
  SipDeckCard(
    id: 'b002',
    text:
        'Guess the price of the most expensive drink here. Furthest off takes 2 sips.',
    sips: 2,
    category: SipDeckCategory.barNight,
  ),
  SipDeckCard(
    id: 'b003',
    text:
        'Everyone orders something they have never tried before, or takes 2 sips.',
    sips: 2,
    category: SipDeckCategory.barNight,
  ),
  SipDeckCard(
    id: 'b004',
    text:
        '{0} must say "cheers" in 3 languages this round, or 1 sip per missing language.',
    sips: 1,
    category: SipDeckCategory.barNight,
  ),
  SipDeckCard(
    id: 'b005',
    text:
        'Group: everyone stands and switches seats. Last to sit takes 2 sips.',
    sips: 2,
    category: SipDeckCategory.barNight,
  ),
  SipDeckCard(
    id: 'b006',
    text: '{0}, talk to a stranger for at least 1 minute. Fail? Take 4 sips.',
    sips: 4,
    category: SipDeckCategory.barNight,
  ),

  // ─────── Laughs ───────
  SipDeckCard(
    id: 'l001',
    text: '{0}, walk like a penguin to the other end of the room and back.',
    sips: 2,
    category: SipDeckCategory.laughs,
  ),
  SipDeckCard(
    id: 'l002',
    text:
        'VIRUS: {0} must end every sentence with "and that\'s the tea" for the next 5 cards, or take 2 sips.',
    sips: 2,
    category: SipDeckCategory.laughs,
    isVirus: true,
  ),
  SipDeckCard(
    id: 'l003',
    text:
        '{0}, narrate what is happening right now as a nature documentary. 60 seconds.',
    sips: 3,
    category: SipDeckCategory.laughs,
  ),
  SipDeckCard(
    id: 'l004',
    text:
        'Everyone says the funniest word they know at the same time. Best word gives out 2 sips.',
    sips: 2,
    category: SipDeckCategory.laughs,
  ),
  SipDeckCard(
    id: 'l005',
    text:
        '{0} can only ask questions for the next 2 minutes. Statements? 1 sip each.',
    sips: 1,
    category: SipDeckCategory.laughs,
    isVirus: true,
  ),
  SipDeckCard(
    id: 'l006',
    text:
        '{0}, explain your job using only hand gestures. Nobody guesses in 30s? Take 3 sips.',
    sips: 3,
    category: SipDeckCategory.laughs,
  ),
  SipDeckCard(
    id: 'l007',
    text:
        '{0}, invent a new word and use it convincingly. Group votes if it sounds real.',
    sips: 0,
    category: SipDeckCategory.laughs,
  ),
  SipDeckCard(
    id: 'l008',
    text:
        'Speed round: name a film, a song, and a city starting with the letter the person to your left picks.',
    sips: 2,
    category: SipDeckCategory.laughs,
  ),
  SipDeckCard(
    id: 'l009',
    text: '{0}, speak in slow motion for the next 3 turns or take 3 sips.',
    sips: 3,
    category: SipDeckCategory.laughs,
    isVirus: true,
  ),
];
