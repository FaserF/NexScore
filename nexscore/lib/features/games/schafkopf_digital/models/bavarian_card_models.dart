// Copyright-safe Bavarian card models for Digital Schafkopf.
// Uses traditional Bavarian suit names (Eichel, Gras, Herz, Schellen)
// with original styling to avoid copyright issues.

/// The four Bavarian card suits.
enum BavarianSuit {
  eichel, // Acorns
  gras, // Leaves
  herz, // Hearts
  schellen, // Bells
}

/// The eight card ranks in a Bavarian deck (32 cards total).
enum BavarianRank {
  sieben, // 7
  acht, // 8
  neun, // 9
  zehn, // 10 (worth 10 points)
  unter, // Under / Jack equivalent (worth 2 points)
  ober, // Over / Queen equivalent (worth 3 points)
  koenig, // King (worth 4 points)
  ass, // Ace (worth 11 points)
}

/// The game type variants in Schafkopf.
enum SchafkopfDigitalGameType {
  sauspiel, // Call game (with Ace partner)
  soloHerz, // Solo with Hearts as trump
  soloEichel, // Solo with Acorns as trump
  soloGras, // Solo with Leaves as trump
  soloSchellen, // Solo with Bells as trump
  wenz, // Only Unters are trump
}

/// A single Bavarian playing card.
class BavarianCard {
  final String id;
  final BavarianSuit suit;
  final BavarianRank rank;

  const BavarianCard({
    required this.id,
    required this.suit,
    required this.rank,
  });

  /// Card point value for Schafkopf scoring.
  int get points {
    switch (rank) {
      case BavarianRank.ass:
        return 11;
      case BavarianRank.zehn:
        return 10;
      case BavarianRank.koenig:
        return 4;
      case BavarianRank.ober:
        return 3;
      case BavarianRank.unter:
        return 2;
      case BavarianRank.neun:
      case BavarianRank.acht:
      case BavarianRank.sieben:
        return 0;
    }
  }

  /// Short display label for the card.
  String get shortLabel {
    final suitChar = switch (suit) {
      BavarianSuit.eichel => '🌰',
      BavarianSuit.gras => '🍃',
      BavarianSuit.herz => '❤️',
      BavarianSuit.schellen => '🔔',
    };
    final rankChar = switch (rank) {
      BavarianRank.sieben => '7',
      BavarianRank.acht => '8',
      BavarianRank.neun => '9',
      BavarianRank.zehn => '10',
      BavarianRank.unter => 'U',
      BavarianRank.ober => 'O',
      BavarianRank.koenig => 'K',
      BavarianRank.ass => 'A',
    };
    return '$suitChar$rankChar';
  }

  /// Full display name for the card.
  String get displayName {
    final suitName = switch (suit) {
      BavarianSuit.eichel => 'Eichel',
      BavarianSuit.gras => 'Gras',
      BavarianSuit.herz => 'Herz',
      BavarianSuit.schellen => 'Schellen',
    };
    final rankName = switch (rank) {
      BavarianRank.sieben => '7',
      BavarianRank.acht => '8',
      BavarianRank.neun => '9',
      BavarianRank.zehn => '10',
      BavarianRank.unter => 'Unter',
      BavarianRank.ober => 'Ober',
      BavarianRank.koenig => 'König',
      BavarianRank.ass => 'Ass',
    };
    return '$suitName $rankName';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'suit': suit.name,
    'rank': rank.name,
  };

  factory BavarianCard.fromMap(Map<String, dynamic> map) => BavarianCard(
    id: map['id'] as String,
    suit: BavarianSuit.values.firstWhere((s) => s.name == map['suit']),
    rank: BavarianRank.values.firstWhere((r) => r.name == map['rank']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BavarianCard && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Generates a standard 32-card Bavarian deck.
class BavarianDeckGenerator {
  static List<BavarianCard> generateFullDeck() {
    final cards = <BavarianCard>[];
    for (final suit in BavarianSuit.values) {
      for (final rank in BavarianRank.values) {
        cards.add(
          BavarianCard(id: '${suit.name}_${rank.name}', suit: suit, rank: rank),
        );
      }
    }
    return cards;
  }
}

/// A trick in Schafkopf (4 cards, one per player).
class SchafkopfTrick {
  final Map<String, BavarianCard> playedCards;
  final List<String> playOrder;

  const SchafkopfTrick({
    this.playedCards = const {},
    this.playOrder = const [],
  });

  SchafkopfTrick addCard(String playerId, BavarianCard card) {
    return SchafkopfTrick(
      playedCards: {...playedCards, playerId: card},
      playOrder: playOrder,
    );
  }

  bool get isComplete => playedCards.length == 4;

  Map<String, dynamic> toMap() => {
    'playedCards': playedCards.map((k, v) => MapEntry(k, v.toMap())),
    'playOrder': playOrder,
  };

  factory SchafkopfTrick.fromMap(Map<String, dynamic> map) {
    final cardsMap = (map['playedCards'] as Map<String, dynamic>?) ?? {};
    return SchafkopfTrick(
      playedCards: cardsMap.map(
        (k, v) => MapEntry(k, BavarianCard.fromMap(v as Map<String, dynamic>)),
      ),
      playOrder: List<String>.from(map['playOrder'] ?? []),
    );
  }
}
