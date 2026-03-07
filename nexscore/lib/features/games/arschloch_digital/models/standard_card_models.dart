// Standard 52-card deck models for card games (Arschloch, etc.).
// Uses original styling to avoid copyright issues.

/// Standard card suits.
enum StandardSuit {
  clubs, // ♣ Kreuz
  spades, // ♠ Pik
  hearts, // ♥ Herz
  diamonds, // ♦ Karo
}

/// Standard card values (2-Ace).
enum StandardValue {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

/// A single standard playing card.
class StandardCard {
  final String id;
  final StandardSuit suit;
  final StandardValue value;

  const StandardCard({
    required this.id,
    required this.suit,
    required this.value,
  });

  /// Numeric rank for comparison (2=2 ... Ace=14).
  int get numericRank {
    return switch (value) {
      StandardValue.two => 2,
      StandardValue.three => 3,
      StandardValue.four => 4,
      StandardValue.five => 5,
      StandardValue.six => 6,
      StandardValue.seven => 7,
      StandardValue.eight => 8,
      StandardValue.nine => 9,
      StandardValue.ten => 10,
      StandardValue.jack => 11,
      StandardValue.queen => 12,
      StandardValue.king => 13,
      StandardValue.ace => 14,
    };
  }

  String get shortLabel {
    final suitChar = switch (suit) {
      StandardSuit.clubs => '♣',
      StandardSuit.spades => '♠',
      StandardSuit.hearts => '♥',
      StandardSuit.diamonds => '♦',
    };
    final valueChar = switch (value) {
      StandardValue.two => '2',
      StandardValue.three => '3',
      StandardValue.four => '4',
      StandardValue.five => '5',
      StandardValue.six => '6',
      StandardValue.seven => '7',
      StandardValue.eight => '8',
      StandardValue.nine => '9',
      StandardValue.ten => '10',
      StandardValue.jack => 'J',
      StandardValue.queen => 'Q',
      StandardValue.king => 'K',
      StandardValue.ace => 'A',
    };
    return '$suitChar$valueChar';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'suit': suit.name,
    'value': value.name,
  };

  factory StandardCard.fromMap(Map<String, dynamic> map) => StandardCard(
    id: map['id'] as String,
    suit: StandardSuit.values.firstWhere((s) => s.name == map['suit']),
    value: StandardValue.values.firstWhere((v) => v.name == map['value']),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StandardCard && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Generates a standard 52-card deck.
class StandardDeckGenerator {
  static List<StandardCard> generateFullDeck() {
    final cards = <StandardCard>[];
    for (final suit in StandardSuit.values) {
      for (final value in StandardValue.values) {
        cards.add(
          StandardCard(
            id: '${suit.name}_${value.name}',
            suit: suit,
            value: value,
          ),
        );
      }
    }
    return cards;
  }
}
