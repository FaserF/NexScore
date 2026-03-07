import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/buzztap/providers/buzztap_provider.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:flutter/widgets.dart';

// Mock AppLocalizations for testing
class MockAppLocalizations extends AppLocalizations {
  MockAppLocalizations() : super(const Locale('en'));
  @override
  String get(String key) => key;
  @override
  String getWith(String key, List<String> args) => key;
}

void main() {
  group('BuzzTapStateNotifier Undo Tests', () {
    late ProviderContainer container;
    final players = [
      Player(
        id: 'p1',
        name: 'Player 1',
        avatarColor: '#FF0000',
        ownerUid: null,
      ),
    ];

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Undo after drawNextCard', () {
      final notifier = container.read(buzzTapStateProvider.notifier);
      final l10n = MockAppLocalizations();

      notifier.drawNextCard(players, l10n);
      expect(container.read(buzzTapStateProvider).playedCards, isNotEmpty);
      expect(notifier.canUndo, isTrue);

      notifier.undo();
      expect(container.read(buzzTapStateProvider).playedCards, isEmpty);
    });

    test('Undo after manual sip increment', () {
      final notifier = container.read(buzzTapStateProvider.notifier);

      notifier.incrementSips('p1', 3);
      expect(container.read(buzzTapStateProvider).playerSips['p1'], 3);

      notifier.undo();
      expect(container.read(buzzTapStateProvider).playerSips['p1'], isNull);
    });
  });
}
