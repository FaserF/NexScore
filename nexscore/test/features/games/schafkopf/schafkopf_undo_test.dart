import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/schafkopf/models/schafkopf_models.dart';
import 'package:nexscore/features/games/schafkopf/providers/schafkopf_provider.dart';

void main() {
  group('SchafkopfStateNotifier Undo Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Undo after addRound', () {
      final notifier = container.read(schafkopfStateProvider.notifier);

      final round = SchafkopfRound(
        roundIndex: 1,
        gameType: SchafkopfGameType.sauspiel,
        activePlayerId: 'p1',
        partnerPlayerId: 'p2',
        points: {'p1': 61},
      );

      notifier.addRound(round);
      expect(container.read(schafkopfStateProvider).rounds, isNotEmpty);
      expect(container.read(schafkopfStateProvider).canUndo, isTrue);

      notifier.undo();
      expect(container.read(schafkopfStateProvider).rounds, isEmpty);
    });

    test('Undo after updateStock', () {
      final notifier = container.read(schafkopfStateProvider.notifier);

      notifier.updateStock(1.50);
      expect(container.read(schafkopfStateProvider).stock, 1.50);

      notifier.undo();
      expect(container.read(schafkopfStateProvider).stock, 0.0);
    });
  });
}
