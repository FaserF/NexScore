import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/qwixx/models/qwixx_models.dart';
import 'package:nexscore/features/games/qwixx/providers/qwixx_provider.dart';

void main() {
  group('QwixxStateNotifier Undo Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Undo after updateSheet', () {
      final notifier = container.read(qwixxStateProvider.notifier);
      notifier.initPlayers(['p1']);

      final sheet = const QwixxPlayerSheet(red: [2, 3]);
      notifier.updateSheet('p1', sheet);
      expect(container.read(qwixxStateProvider).sheets['p1']?.red.length, 2);

      notifier.undo();
      expect(container.read(qwixxStateProvider).sheets['p1']?.red, isEmpty);
    });
  });
}
