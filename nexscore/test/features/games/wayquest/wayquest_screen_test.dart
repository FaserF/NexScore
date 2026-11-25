import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/providers/active_players_provider.dart';
import 'package:nexscore/features/games/wayquest/presentation/wayquest_screen.dart';

void main() {
  Widget buildTestWidget({List<Player> players = const []}) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    if (players.isNotEmpty) {
      container.read(activePlayersProvider.notifier).setPlayers(players);
    }
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: const WayQuestScreen(),
      ),
    );
  }

  group('WayQuestScreen tests', () {
    testWidgets('renders setup screen with category chips and start button', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Deep Talks'), findsOneWidget);
      expect(find.text('Would You Rather'), findsOneWidget);
      expect(find.text('START VOYAGE'), findsOneWidget);
    });

    testWidgets('tapping start transitions from setup to active quest with 0 players (#71)', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('START VOYAGE'));
      await tester.pumpAndSettle();

      expect(find.text('START VOYAGE'), findsNothing);
      expect(find.text('QUEST 1'), findsOneWidget);
      expect(find.text('Tap for next quest'), findsOneWidget);
    });

    testWidgets('tapping start transitions to active quest with 2 players (#71)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          players: [
            Player(id: 'p1', name: 'Alice', avatarColor: '#FF0000'),
            Player(id: 'p2', name: 'Bob', avatarColor: '#00FF00'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('START VOYAGE'));
      await tester.pumpAndSettle();

      expect(find.text('START VOYAGE'), findsNothing);
      expect(find.text('QUEST 1'), findsOneWidget);
    });
  });
}
