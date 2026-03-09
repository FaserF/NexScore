import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/wizard/models/wizard_models.dart';
import 'package:nexscore/features/games/wizard/providers/wizard_provider.dart';

void main() {
  group('WizardGameStateNotifier Undo Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Undo after addRound', () {
      final notifier = container.read(wizardStateProvider.notifier);

      final round = WizardRound(
        roundIndex: 1,
        bids: {'p1': 1},
        tricks: {'p1': 1},
      );

      notifier.addRound(round);
      expect(container.read(wizardStateProvider).rounds, isNotEmpty);
      expect(container.read(wizardStateProvider).canUndo, isTrue);

      notifier.undo();
      expect(container.read(wizardStateProvider).rounds, isEmpty);
    });
  });
}
