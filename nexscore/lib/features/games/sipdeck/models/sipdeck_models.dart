import 'sipdeck_expansion.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/models/drink_intensity.dart';

/// Card categories for SipDeck – the party drinking game module.
enum SipDeckCategory {
  warmUp, // Easy icebreaker challenges, fun for everyone
  wildCards, // Advanced dares and creative rules
  flirty, // Playful, flirty challenges (18+)
  barNight, // Suitable for any public bar setting
  laughs, // Silly and absurd things to do or say
}

enum SipTargetType {
  single, // Card targets {0}
  dual, // Card targets {0} and {1}
  everyone, // Card targets everyone
  manual, // Targets determined by external logic or group
}

enum SipDeckTaskTag {
  dare, // Pflichtaufgabe / Dare
  social, // Social interaction
  messaging, // Contacting people/messaging
  physical, // Physical activity
}

/// A single SipDeck challenge card.
class SipDeckCard {
  final String id;
  final String text; // Challenge text. Use {0}, {1} for player names.
  final String? emoji; // Visual icon for the card
  final String? explanation; // Foolproof explanation for the task
  final int sips; // 0 = rule-based, >0 = number of sips to take
  final SipDeckCategory category;
  final Set<SipDeckTaskTag> tags;
  final bool isVirus; // Ongoing rule that persists until "cured"
  final int minPlayers; // Minimum players required for this card to make sense
  final List<String> targetIds; // Resolved player IDs for this card instance
  final SipTargetType targetType; // Type of target for automatic scoring

  const SipDeckCard({
    required this.id,
    required this.text,
    this.emoji,
    this.explanation,
    this.sips = 1,
    required this.category,
    this.tags = const {},
    this.isVirus = false,
    this.minPlayers = 2,
    this.targetIds = const [],
    this.targetType = SipTargetType.manual,
  });

  String get key => 'sd_card_$id';
  String get explanationKey => 'sd_card_${id}_expl';

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'emoji': emoji,
    'explanation': explanation,
    'sips': sips,
    'category': category.name,
    'tags': tags.map((t) => t.name).toList(),
    'isVirus': isVirus,
    'minPlayers': minPlayers,
  };

  factory SipDeckCard.fromJson(Map<String, dynamic> json) {
    return SipDeckCard(
      id: json['id'] as String,
      text: json['text'] as String,
      emoji: json['emoji'] as String?,
      explanation: json['explanation'] as String?,
      sips: json['sips'] as int? ?? 1,
      category: SipDeckCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => SipDeckCategory.warmUp,
      ),
      tags: (json['tags'] as List? ?? [])
          .map((t) => SipDeckTaskTag.values.firstWhere((e) => e.name == t))
          .toSet(),
      isVirus: json['isVirus'] as bool? ?? false,
      minPlayers: json['minPlayers'] as int? ?? 2,
    );
  }
}

class SipDeckGameState {
  final List<String> activePlayerIds;
  final List<SipDeckCategory> selectedCategories;
  final Set<SipDeckTaskTag> disabledTags;
  final List<SipDeckCard> playedCards;
  final List<SipDeckCard> activeViruses;
  final bool
  filterMultiplayerOnly; // If true, cards with minPlayers > 2 are hidden when only 2 play
  final Map<String, int> playerSips;
  final DrinkIntensity intensity;
  final double customIntensityMultiplier;
  final bool enableHydrationCards;

  const SipDeckGameState({
    this.activePlayerIds = const [],
    this.selectedCategories = const [SipDeckCategory.warmUp],
    this.disabledTags = const {},
    this.playedCards = const [],
    this.activeViruses = const [],
    this.filterMultiplayerOnly = true,
    this.playerSips = const {},
    this.intensity = DrinkIntensity.normal,
    this.customIntensityMultiplier = 1.0,
    this.enableHydrationCards = true,
  });

  SipDeckGameState copyWith({
    List<String>? activePlayerIds,
    List<SipDeckCategory>? selectedCategories,
    Set<SipDeckTaskTag>? disabledTags,
    List<SipDeckCard>? playedCards,
    List<SipDeckCard>? activeViruses,
    bool? filterMultiplayerOnly,
    Map<String, int>? playerSips,
    DrinkIntensity? intensity,
    double? customIntensityMultiplier,
    bool? enableHydrationCards,
  }) {
    return SipDeckGameState(
      activePlayerIds: activePlayerIds ?? this.activePlayerIds,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      disabledTags: disabledTags ?? this.disabledTags,
      playedCards: playedCards ?? this.playedCards,
      activeViruses: activeViruses ?? this.activeViruses,
      filterMultiplayerOnly:
          filterMultiplayerOnly ?? this.filterMultiplayerOnly,
      playerSips: playerSips ?? this.playerSips,
      intensity: intensity ?? this.intensity,
      customIntensityMultiplier:
          customIntensityMultiplier ?? this.customIntensityMultiplier,
      enableHydrationCards: enableHydrationCards ?? this.enableHydrationCards,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activePlayerIds': activePlayerIds,
      'selectedCategories': selectedCategories.map((e) => e.name).toList(),
      'disabledTags': disabledTags.map((e) => e.name).toList(),
      'playedCards': playedCards.map((e) => e.toJson()).toList(),
      'activeViruses': activeViruses.map((e) => e.toJson()).toList(),
      'filterMultiplayerOnly': filterMultiplayerOnly,
      'playerSips': playerSips,
      'intensity': intensity.name,
      'customIntensityMultiplier': customIntensityMultiplier,
      'enableHydrationCards': enableHydrationCards,
    };
  }

  factory SipDeckGameState.fromMap(Map<String, dynamic> map) {
    return SipDeckGameState(
      activePlayerIds: List<String>.from(map['activePlayerIds'] ?? []),
      selectedCategories: (map['selectedCategories'] as List? ?? [])
          .map((e) => SipDeckCategory.values.firstWhere((c) => c.name == e))
          .toList(),
      disabledTags: (map['disabledTags'] as List? ?? [])
          .map((e) => SipDeckTaskTag.values.firstWhere((c) => c.name == e))
          .toSet(),
      playedCards: (map['playedCards'] as List? ?? [])
          .map((e) => SipDeckCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeViruses: (map['activeViruses'] as List? ?? [])
          .map((e) => SipDeckCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      filterMultiplayerOnly: map['filterMultiplayerOnly'] ?? true,
      playerSips: Map<String, int>.from(map['playerSips'] ?? {}),
      intensity: DrinkIntensity.values.firstWhere(
        (e) => e.name == map['intensity'],
        orElse: () => DrinkIntensity.normal,
      ),
      customIntensityMultiplier:
          (map['customIntensityMultiplier'] as num? ?? 1.0).toDouble(),
      enableHydrationCards: map['enableHydrationCards'] ?? true,
    );
  }

  SipDeckCard? get currentCard =>
      playedCards.isNotEmpty ? playedCards.last : null;
}

/// The full SipDeck card database – 50+ core cards across all categories plus expansions.
List<SipDeckCard> getSipDeckDatabase(AppLocalizations l10n) {
  return [
    // ─────── Warm Up ───────
    SipDeckCard(
      id: 'w001',
      emoji: '🔵',
      text:
          '{0}, name three things you can see that are blue. Fail? Take 2 sips.',
      sips: 2,
      category: SipDeckCategory.warmUp,
      tags: {SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'w002',
      emoji: '🌊',
      text:
          'Waterfall! {0} starts. Everyone follows. Stop only when the person to your left stops.',
      sips: 0,
      category: SipDeckCategory.warmUp,
      tags: {SipDeckTaskTag.social, SipDeckTaskTag.physical},
    ),
    SipDeckCard(
      id: 'w003',
      emoji: '🗣️',
      text:
          '{0} gives {1} a compliment. {1} must respond in a made-up language. Fail? Take 3 sips.',
      sips: 3,
      category: SipDeckCategory.warmUp,
      tags: {SipDeckTaskTag.social, SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'w004',
      emoji: '🧟',
      text:
          'Group votes: who would survive a zombie apocalypse? Fewest votes = 2 sips.',
      sips: 2,
      category: SipDeckCategory.warmUp,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'w005',
      emoji: '🐘',
      text:
          '{0}, 10 seconds to name 5 animals. Miss any? Drink 1 sip per miss.',
      sips: 1,
      category: SipDeckCategory.warmUp,
      tags: {SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'w006',
      emoji: '👍',
      text: 'Thumb war! {0} vs {1}. Loser takes 2 sips.',
      sips: 2,
      category: SipDeckCategory.warmUp,
      tags: {SipDeckTaskTag.social, SipDeckTaskTag.physical},
    ),
    SipDeckCard(
      id: 'w007',
      emoji: '🧦',
      text: 'Everyone wearing socks takes 1 sip.',
      sips: 1,
      category: SipDeckCategory.warmUp,
    ),
    SipDeckCard(
      id: 'w008',
      emoji: '🎭',
      text:
          '{0}, do your best celebrity impression. Bad impression? Take 3 sips.',
      sips: 3,
      category: SipDeckCategory.warmUp,
      tags: {SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'w009',
      emoji: '🤫',
      text: 'Never Have I Ever: {0} starts. Go around the circle once.',
      sips: 0,
      category: SipDeckCategory.warmUp,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'w010',
      emoji: '👁️',
      text: '{0} and {1} have a staring contest. First to blink takes 2 sips.',
      sips: 2,
      category: SipDeckCategory.warmUp,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'w011',
      emoji: '✂️',
      text: 'Rock Paper Scissors tournament. Last place takes 3 sips.',
      sips: 3,
      category: SipDeckCategory.warmUp,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'w012',
      emoji: '👥',
      text:
          '{0}, mimic the person to your left for the next 2 minutes. Forget? Take 2 sips.',
      sips: 2,
      category: SipDeckCategory.warmUp,
      isVirus: true,
      tags: {SipDeckTaskTag.social, SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'w013',
      emoji: '🗣️',
      text: 'Group vote: who talks the most? That person takes 2 sips.',
      sips: 2,
      category: SipDeckCategory.warmUp,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social},
    ),

    // ─────── Wild Cards ───────
    SipDeckCard(
      id: 'wc001',
      emoji: '🏴‍☠️',
      text:
          '{0} must speak like a pirate for the next 3 rounds, or take 4 sips.',
      sips: 4,
      category: SipDeckCategory.wildCards,
      isVirus: true,
      tags: {SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'wc002',
      emoji: '⚖️',
      text:
          'Make a rule. {0} creates a rule everyone must follow this round. Break it? 2 sips.',
      sips: 2,
      category: SipDeckCategory.wildCards,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'wc003',
      emoji: '🏷️',
      text:
          '{0}, you have a new name: "{1}". Anyone using your real name drinks 1 sip.',
      sips: 1,
      category: SipDeckCategory.wildCards,
      isVirus: true,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'wc004',
      emoji: '🎯',
      text:
          '{0} assigns one sip each to three different people. No questions asked.',
      sips: 0,
      category: SipDeckCategory.wildCards,
      minPlayers: 4,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'wc005',
      emoji: '💪',
      text: 'CHALLENGE: {0} does 10 jumping jacks, or takes 5 sips.',
      sips: 5,
      category: SipDeckCategory.wildCards,
      tags: {SipDeckTaskTag.dare, SipDeckTaskTag.physical},
    ),
    SipDeckCard(
      id: 'wc006',
      emoji: '📞',
      text:
          'Telephone! {0} whispers a phrase, it goes around. Wrong at the end? Take 3 sips.',
      sips: 3,
      category: SipDeckCategory.wildCards,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'wc007',
      emoji: '📱',
      text:
          'Everyone on their phones: screenshot your last search. Most embarrassing? Take 3 sips.',
      sips: 3,
      category: SipDeckCategory.wildCards,
      tags: {SipDeckTaskTag.messaging},
    ),
    SipDeckCard(
      id: 'wc008',
      emoji: '😂',
      text: '{0}, every time you laugh for the next 5 minutes, take 1 sip.',
      sips: 1,
      category: SipDeckCategory.wildCards,
      isVirus: true,
    ),
    SipDeckCard(
      id: 'wc009',
      emoji: '✨',
      text:
          'VIRUS CURED: The ongoing rule ends. Everyone else takes 1 sip in celebration.',
      sips: 1,
      category: SipDeckCategory.wildCards,
    ),
    SipDeckCard(
      id: 'wc010',
      emoji: '🎨',
      text:
          '{0} draws a portrait of {1} without looking at the paper. Worst drawing? Drink 3.',
      sips: 3,
      category: SipDeckCategory.wildCards,
      tags: {SipDeckTaskTag.social, SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'wc011',
      emoji: '🤸',
      text:
          'Group challenge: plank position. Last one standing gives out 5 sips.',
      sips: 5,
      category: SipDeckCategory.wildCards,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social, SipDeckTaskTag.physical},
    ),

    // ─────── Flirty (18+) ───────
    SipDeckCard(
      id: 'f001',
      emoji: '💖',
      text:
          '{0}, give {1} a genuine compliment about their style. If you blush, take 2 sips.',
      sips: 2,
      category: SipDeckCategory.flirty,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'f002',
      emoji: '🤝',
      text:
          '{0} and {1} have 30 seconds to find one thing in common. Fail? Both take 3 sips.',
      sips: 3,
      category: SipDeckCategory.flirty,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'f003',
      emoji: '💌',
      text:
          '{0}, text your most recent contact a heart emoji. Refuse? Take 2 sips.',
      sips: 2,
      category: SipDeckCategory.flirty,
      tags: {SipDeckTaskTag.messaging, SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'f004',
      emoji: '😁',
      text:
          'Everyone votes: cutest smile in the room. That person gives out 3 sips.',
      sips: 3,
      category: SipDeckCategory.flirty,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'f005',
      emoji: '🤐',
      text:
          '{0}, describe your crush without naming them. Group tries to guess.',
      sips: 0,
      category: SipDeckCategory.flirty,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'f006',
      emoji: '📊',
      text: 'Truth: {0}, rate each person 1–10. Refuse? Take 4 sips.',
      sips: 4,
      category: SipDeckCategory.flirty,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'f007',
      emoji: '📝',
      text:
          'Everyone writes a one-word compliment for {0}. {0} guesses who wrote each. Wrong? 1 sip each.',
      sips: 1,
      category: SipDeckCategory.flirty,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social},
    ),

    // ─────── Bar Night ───────
    SipDeckCard(
      id: 'b001',
      emoji: '🥂',
      text:
          '{0} starts a toast. Everyone adds a sentence. Break the flow? Take 2 sips.',
      sips: 2,
      category: SipDeckCategory.barNight,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'b002',
      emoji: '💰',
      text:
          'Guess the price of the most expensive drink here. Furthest off takes 2 sips.',
      sips: 2,
      category: SipDeckCategory.barNight,
    ),
    SipDeckCard(
      id: 'b003',
      emoji: '🍹',
      text:
          'Everyone orders something they have never tried before, or takes 2 sips.',
      sips: 2,
      category: SipDeckCategory.barNight,
    ),
    SipDeckCard(
      id: 'b004',
      emoji: '🍻',
      text:
          '{0} must say "cheers" in 3 languages this round, or 1 sip per missing language.',
      sips: 1,
      category: SipDeckCategory.barNight,
    ),
    SipDeckCard(
      id: 'b005',
      emoji: '🪑',
      text:
          'Group: everyone stands and switches seats. Last to sit takes 2 sips.',
      sips: 2,
      category: SipDeckCategory.barNight,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social, SipDeckTaskTag.physical},
    ),
    SipDeckCard(
      id: 'b006',
      emoji: '🤝',
      text: '{0}, talk to a stranger for at least 1 minute. Fail? Take 4 sips.',
      sips: 4,
      category: SipDeckCategory.barNight,
      tags: {SipDeckTaskTag.social, SipDeckTaskTag.dare},
    ),

    // ─────── Laughs ───────
    SipDeckCard(
      id: 'l001',
      emoji: '🐧',
      text: '{0}, walk like a penguin to the other end of the room and back.',
      sips: 2,
      category: SipDeckCategory.laughs,
      tags: {SipDeckTaskTag.dare, SipDeckTaskTag.physical},
    ),
    SipDeckCard(
      id: 'l002',
      emoji: '☕',
      text:
          'VIRUS: {0} must end every sentence with "and that\'s the tea" for the next 5 cards, or take 2 sips.',
      sips: 2,
      category: SipDeckCategory.laughs,
      isVirus: true,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'l003',
      emoji: '🦒',
      text:
          '{0}, narrate what is happening right now as a nature documentary. 60 seconds.',
      sips: 3,
      category: SipDeckCategory.laughs,
      tags: {SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'l004',
      emoji: '🤣',
      text:
          'Everyone says the funniest word they know at the same time. Best word gives out 2 sips.',
      sips: 2,
      category: SipDeckCategory.laughs,
      minPlayers: 3,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'l005',
      emoji: '❓',
      text:
          '{0} can only ask questions for the next 2 minutes. Statements? 1 sip each.',
      sips: 1,
      category: SipDeckCategory.laughs,
      isVirus: true,
      tags: {SipDeckTaskTag.social},
    ),
    SipDeckCard(
      id: 'l006',
      emoji: '🖐️',
      text:
          '{0}, explain your job using only hand gestures. Nobody guesses in 30s? Take 3 sips.',
      sips: 3,
      category: SipDeckCategory.laughs,
      tags: {SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'l007',
      emoji: '🆕',
      text:
          '{0}, invent a new word and use it convincingly. Group votes if it sounds real.',
      sips: 0,
      category: SipDeckCategory.laughs,
      tags: {SipDeckTaskTag.dare},
    ),
    SipDeckCard(
      id: 'l008',
      emoji: '🏙️',
      text:
          'Speed round: name a film, a song, and a city starting with the letter the person to your left picks.',
      sips: 2,
      category: SipDeckCategory.laughs,
    ),
    SipDeckCard(
      id: 'l009',
      emoji: '🐢',
      text: '{0}, speak in slow motion for the next 3 turns or take 3 sips.',
      sips: 3,
      category: SipDeckCategory.laughs,
      isVirus: true,
      tags: {SipDeckTaskTag.dare},
    ),
    ...generateSipDeckExpansion(l10n),
  ];
}
