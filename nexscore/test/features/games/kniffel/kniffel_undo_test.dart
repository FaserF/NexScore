import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/kniffel/models/kniffel_models.dart';
import 'package:nexscore/features/games/kniffel/providers/kniffel_provider.dart';

void main() {
  group('KniffelStateNotifier Undo Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state canUndo is false', () {
      final notifier = container.read(kniffelStateProvider.notifier);
      expect(notifier.canUndo, isFalse);
    });

    test('Undo after initPlayers', () {
      final notifier = container.read(kniffelStateProvider.notifier);

      notifier.initPlayers(['p1', 'p2']);
      expect(notifier.canUndo, isTrue);
      expect(container.read(kniffelStateProvider).playerSheets.length, 2);

      notifier.undo();
      expect(notifier.canUndo, isFalse);
      expect(container.read(kniffelStateProvider).playerSheets, isEmpty);
    });

    test('Undo after updateScore', () {
      final notifier = container.read(kniffelStateProvider.notifier);
      notifier.initPlayers(['p1']);

      notifier.updateScore('p1', YahtzeeCategory.ones, 5);
      expect(
        container
            .read(kniffelStateProvider)
            .playerSheets['p1']
            ?.scores[YahtzeeCategory.ones],
        5,
      );

      notifier.undo();
      expect(
        container
            .read(kniffelStateProvider)
            .playerSheets['p1']
            ?.scores[YahtzeeCategory.ones],
        isNull,
      );
    });

    test('Undo after multiple changes', () {
      final notifier = container.read(kniffelStateProvider.notifier);
      notifier.initPlayers(['p1']);

      notifier.updateScore('p1', YahtzeeCategory.ones, 5);
      notifier.updateScore('p1', YahtzeeCategory.twos, 10);

      expect(
        container
            .read(kniffelStateProvider)
            .playerSheets['p1']
            ?.scores[YahtzeeCategory.twos],
        10,
      );

      notifier.undo();
      expect(
        container
            .read(kniffelStateProvider)
            .playerSheets['p1']
            ?.scores[YahtzeeCategory.twos],
        isNull,
      );
      expect(
        container
            .read(kniffelStateProvider)
            .playerSheets['p1']
            ?.scores[YahtzeeCategory.ones],
        5,
      );

      notifier.undo();
      expect(
        container
            .read(kniffelStateProvider)
            .playerSheets['p1']
            ?.scores[YahtzeeCategory.ones],
        isNull,
      );
    });
  });
}
