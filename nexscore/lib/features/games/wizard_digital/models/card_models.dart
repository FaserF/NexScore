/// Copyright-safe card models for the digital Wizard-like trick-taking game.
/// These are generic "Mystic Tricks" cards — 4 suits + 2 special roles.

enum CardSuit { flame, frost, earth, wind }

enum CardType { normal, wizard, jester }

class GameCard {
  final String id;
  final CardType type;
  final CardSuit? suit; // null for Wizard/Jester
  final int? value; // 1-13 for normal cards, null for specials

  const GameCard({required this.id, required this.type, this.suit, this.value});

  /// Display name for this card
  String get displayName {
    switch (type) {
      case CardType.wizard:
        return 'Wizard';
      case CardType.jester:
        return 'Jester';
      case CardType.normal:
        return '${_suitEmoji(suit!)} $value';
    }
  }

  /// Short label (e.g. "F7" for Flame-7)
  String get shortLabel {
    switch (type) {
      case CardType.wizard:
        return 'W';
      case CardType.jester:
        return 'J';
      case CardType.normal:
        return '${suit!.name[0].toUpperCase()}$value';
    }
  }

  static String _suitEmoji(CardSuit suit) {
    switch (suit) {
      case CardSuit.flame:
        return '🔥';
      case CardSuit.frost:
        return '❄️';
      case CardSuit.earth:
        return '🌿';
      case CardSuit.wind:
        return '💨';
    }
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'type': type.name, 'suit': suit?.name, 'value': value};
  }

  factory GameCard.fromMap(Map<String, dynamic> map) {
    return GameCard(
      id: map['id'] as String,
      type: CardType.values.firstWhere((e) => e.name == map['type']),
      suit: map['suit'] != null
          ? CardSuit.values.firstWhere((e) => e.name == map['suit'])
          : null,
      value: map['value'] as int?,
    );
  }
}

/// Generates a full Wizard-like deck: 4 suits x 13 values + 4 Wizards + 4 Jesters = 60 cards
class DeckGenerator {
  static List<GameCard> generateFullDeck() {
    final deck = <GameCard>[];
    int cardIndex = 0;

    // 4 suits, values 1-13
    for (final suit in CardSuit.values) {
      for (int value = 1; value <= 13; value++) {
        deck.add(
          GameCard(
            id: 'card_${cardIndex++}',
            type: CardType.normal,
            suit: suit,
            value: value,
          ),
        );
      }
    }

    // 4 Wizards
    for (int i = 0; i < 4; i++) {
      deck.add(GameCard(id: 'wizard_$i', type: CardType.wizard));
    }

    // 4 Jesters
    for (int i = 0; i < 4; i++) {
      deck.add(GameCard(id: 'jester_$i', type: CardType.jester));
    }

    return deck;
  }
}
