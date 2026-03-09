import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/features/games/volleyball/presentation/volleyball_scoreboard.dart';
import 'package:nexscore/features/games/volleyball/presentation/volleyball_signals_screen.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en', '')],
        home: const VolleyballScoreboard(),
      ),
    );
  }

  group('VolleyballScoreboard widget tests', () {
    testWidgets('renders setup dialog on first launch', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should find team name text fields and "Indoor" chip
      expect(find.text('Team A'), findsOneWidget);
      expect(find.text('Team B'), findsOneWidget);
      expect(find.text('Indoor'), findsOneWidget);
    });

    testWidgets('tapping OK on setup dialog starts the match', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Dialog should be gone, and we should see "Team A" and "Team B" on the scoreboard
      expect(find.text('Indoor'), findsNothing); // Chip is gone
      expect(find.text('0'), findsWidgets); // Score displays
    });

    testWidgets('tapping team area increments score', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Setup
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Tap Team A area (the first 0)
      final teamA0 = find.text('0').at(0);
      await tester.tap(teamA0);
      await tester.pumpAndSettle();

      // Score should be 1
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('long press team area removes point', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Add a point
      await tester.tap(find.text('0').at(0));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Long press same area
      await tester.longPress(find.text('1'));
      await tester.pumpAndSettle();

      // Score should be 0 again
      expect(find.text('0'), findsWidgets);
    });

    testWidgets(
      'Undo button is initially disabled and becomes enabled after a point',
      (tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Initially disabled
        final undoFinder = find.ancestor(
          of: find.byIcon(Icons.undo),
          matching: find.byType(IconButton),
        );
        expect(tester.widget<IconButton>(undoFinder).onPressed, isNull);

        // Add a point
        await tester.tap(find.text('0').at(0));
        await tester.pumpAndSettle();

        // Now enabled
        expect(tester.widget<IconButton>(undoFinder).onPressed, isNotNull);
      },
    );

    testWidgets('tapping rule icon navigates to Signals screen', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Tap rule icon
      await tester.tap(find.byIcon(Icons.rule));
      await tester.pumpAndSettle();

      // Should be on Signals screen
      expect(find.byType(VolleyballSignalsScreen), findsOneWidget);
    });
  });
}
