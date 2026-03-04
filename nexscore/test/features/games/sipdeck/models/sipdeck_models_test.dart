import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/features/games/sipdeck/models/sipdeck_models.dart';

void main() {
  group('SipDeck Models', () {
    test('SipDeckCard serializes and deserializes correctly', () {
      const card = SipDeckCard(
        id: 'test-1',
        text: '{0} challenges {1}.',
        sips: 3,
        category: SipDeckCategory.barNight,
        isVirus: false,
      );

      final json = card.toJson();
      expect(json['id'], 'test-1');
      expect(json['sips'], 3);
      expect(json['category'], 'barNight');
      expect(json['isVirus'], false);

      final restored = SipDeckCard.fromJson(json);
      expect(restored.id, 'test-1');
      expect(restored.text, '{0} challenges {1}.');
      expect(restored.sips, 3);
      expect(restored.category, SipDeckCategory.barNight);
      expect(restored.isVirus, false);
    });

    test('SipDeckCard virus flag is preserved', () {
      const card = SipDeckCard(
        id: 'v-1',
        text: 'VIRUS: {0} must talk in rhymes.',
        sips: 0,
        category: SipDeckCategory.laughs,
        isVirus: true,
      );
      final restored = SipDeckCard.fromJson(card.toJson());
      expect(restored.isVirus, true);
    });

    test('SipDeckCard fromJson falls back to warmUp for unknown category', () {
      final json = {
        'id': 'x',
        'text': 'Test',
        'sips': 1,
        'category': 'invalidCategory',
        'isVirus': false,
      };
      final card = SipDeckCard.fromJson(json);
      expect(card.category, SipDeckCategory.warmUp);
    });

    test('SipDeckGameState copyWith updates only specified fields', () {
      const original = SipDeckGameState(
        selectedCategories: [SipDeckCategory.warmUp],
        playedCards: [],
      );

      final updated = original.copyWith(
        selectedCategories: [SipDeckCategory.warmUp, SipDeckCategory.laughs],
      );

      expect(updated.selectedCategories.length, 2);
      expect(updated.playedCards, isEmpty);
    });

    test('sipDeckDatabase is non-empty and covers all categories', () {
      expect(sipDeckDatabase.isNotEmpty, true);
      expect(sipDeckDatabase.length, greaterThanOrEqualTo(40));

      final categories = sipDeckDatabase.map((c) => c.category).toSet();
      for (final cat in SipDeckCategory.values) {
        expect(
          categories.contains(cat),
          true,
          reason: 'Category $cat has no cards in database',
        );
      }
    });

    test('all database cards have non-empty text', () {
      for (final card in sipDeckDatabase) {
        expect(
          card.text.isNotEmpty,
          true,
          reason: 'Card ${card.id} has empty text',
        );
      }
    });

    test('all database card IDs are unique', () {
      final ids = sipDeckDatabase.map((c) => c.id).toList();
      final uniqueIds = ids.toSet();
      expect(
        ids.length,
        uniqueIds.length,
        reason: 'Duplicate card IDs found in sipDeckDatabase',
      );
    });
  });
}
