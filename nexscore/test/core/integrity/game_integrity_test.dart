import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/providers/active_players_provider.dart';
import 'package:nexscore/features/games/sipdeck/presentation/sipdeck_screen.dart';
import 'package:nexscore/features/games/sipdeck/providers/sipdeck_provider.dart';
import 'package:nexscore/features/games/sipdeck/models/sipdeck_models.dart';
import 'package:nexscore/features/games/buzztap/presentation/buzztap_screen.dart';
import 'package:nexscore/features/games/buzztap/providers/buzztap_provider.dart';
import 'package:nexscore/features/games/buzztap/models/buzztap_models.dart';
import 'package:nexscore/features/games/wayquest/presentation/wayquest_screen.dart';
import 'package:nexscore/features/games/wayquest/providers/wayquest_provider.dart';
import 'package:nexscore/features/games/wayquest/models/wayquest_models.dart';
import 'package:nexscore/features/games/wizard/presentation/wizard_screen.dart';
import 'package:nexscore/features/games/wizard/providers/wizard_provider.dart';
import 'package:nexscore/features/games/wizard/models/wizard_models.dart';
import 'package:nexscore/features/games/arschloch/presentation/arschloch_screen.dart';
import 'package:nexscore/features/games/arschloch/providers/arschloch_provider.dart';
import 'package:nexscore/features/games/arschloch/models/arschloch_models.dart';

void main() {
  group('Game Integrity Tests', () {
    final players = [
      const Player(
        id: '1',
        name: 'Player One Who Has A Very Very Long Name Indeed',
        avatarColor: '#FF0000',
      ),
      const Player(
        id: '2',
        name: 'Player Two With Another Ridiculously Long Name For Testing',
        avatarColor: '#00FF00',
      ),
    ];

    testWidgets(
      'SipDeckScreen should not have layout overflows with long text',
      (WidgetTester tester) async {
        final longCard = SipDeckCard(
          id: 'long-test',
          text: 'SipDeck Test ' * 20,
          explanation: 'Explanation ' * 20,
          sips: 5,
          category: SipDeckCategory.wildCards,
          targetIds: ['1'],
          targetType: SipTargetType.single,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activePlayersProvider.overrideWith(
                () => _MockActivePlayersNotifier(players),
              ),
              sipDeckStateProvider.overrideWith(
                () => _MockSipDeckNotifier(longCard),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [AppLocalizationsDelegate()],
              home: SipDeckScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      },
    );

    testWidgets(
      'BuzzTapScreen should not have layout overflows with long text',
      (WidgetTester tester) async {
        final longCard = BuzzTapCard(
          id: 'long-test',
          text: 'BuzzTap Test ' * 20,
          sips: 5,
          category: BuzzTapCategory.warmup,
          targetIds: ['1'],
          targetType: BuzzTapTargetType.single,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activePlayersProvider.overrideWith(
                () => _MockActivePlayersNotifier(players),
              ),
              buzzTapStateProvider.overrideWith(
                () => _MockBuzzTapNotifier(longCard),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [AppLocalizationsDelegate()],
              home: BuzzTapScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsAtLeast(1));
      },
    );

    testWidgets(
      'WayQuestScreen should not have layout overflows with long text',
      (WidgetTester tester) async {
        final longCard = WayQuestCard(
          id: 'long-test',
          text: 'WayQuest Test ' * 20,
          category: WayQuestCategory.deepTalks,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activePlayersProvider.overrideWith(
                () => _MockActivePlayersNotifier(players),
              ),
              wayQuestStateProvider.overrideWith(
                () => _MockWayQuestNotifier(longCard),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [AppLocalizationsDelegate()],
              home: WayQuestScreen(),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsAtLeast(1));
      },
    );

    testWidgets(
      'WizardScreen should not overflow with many rounds and history',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activePlayersProvider.overrideWith(
                () => _MockActivePlayersNotifier(players),
              ),
              wizardStateProvider.overrideWith(() => _MockWizardNotifier()),
            ],
            child: const MaterialApp(
              localizationsDelegates: [AppLocalizationsDelegate()],
              home: WizardScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      },
    );

    testWidgets(
      'ArschlochScreen setup should be scrollable with many players',
      (WidgetTester tester) async {
        final manyPlayers = List.generate(
          15,
          (i) => Player(id: '$i', name: 'Player $i', avatarColor: '#000000'),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              activePlayersProvider.overrideWith(
                () => _MockActivePlayersNotifier(manyPlayers),
              ),
              arschlochStateProvider.overrideWith(
                () => _MockArschlochNotifier(),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [AppLocalizationsDelegate()],
              home: ArschlochScreen(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(ListView), findsOneWidget);
      },
    );
  });
}

class _MockSipDeckNotifier extends SipDeckStateNotifier {
  final SipDeckCard initialCard;
  _MockSipDeckNotifier(this.initialCard);
  @override
  SipDeckGameState build() =>
      SipDeckGameState(playedCards: [initialCard], activePlayerIds: ['1', '2']);
}

class _MockBuzzTapNotifier extends BuzzTapStateNotifier {
  final BuzzTapCard initialCard;
  _MockBuzzTapNotifier(this.initialCard);
  @override
  BuzzTapGameState build() => BuzzTapGameState(playedCards: [initialCard]);
}

class _MockWayQuestNotifier extends WayQuestStateNotifier {
  final WayQuestCard initialCard;
  _MockWayQuestNotifier(this.initialCard);
  @override
  WayQuestGameState build() => WayQuestGameState(
    playedCards: [initialCard],
    activePlayerIds: ['1', '2'],
  );
}

class _MockWizardNotifier extends WizardGameStateNotifier {
  @override
  WizardGameState build() {
    final rounds = List.generate(
      20,
      (i) => WizardRound(
        roundIndex: i + 1,
        bids: {'1': 1, '2': 1},
        tricks: {'1': 1, '2': 0},
      ),
    );
    return WizardGameState(rounds: rounds);
  }
}

class _MockArschlochNotifier extends ArschlochStateNotifier {
  @override
  ArschlochGameState build() => const ArschlochGameState();
}

class _MockActivePlayersNotifier extends ActivePlayersNotifier {
  final List<Player> mockPlayers;
  _MockActivePlayersNotifier(this.mockPlayers);
  @override
  List<Player> build() => mockPlayers;
}
