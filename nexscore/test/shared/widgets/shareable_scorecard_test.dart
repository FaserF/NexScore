import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/shared/widgets/shareable_scorecard.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  testWidgets(
    'ShareableScorecard should not crash when built without Localizations and use fallback',
    (WidgetTester tester) async {
      // This test simulates a build without AppLocalizations in the tree.
      // Our fix makes it use 'Winner' as a fallback.

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShareableScorecard(
              gameName: 'Kniffel',
              winnerName: 'Player1',
              winnerColor: Colors.amber,
              finalScores: [
                PlayerScore('Player1', 250),
                PlayerScore('User', 200),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('WINNER'),
        findsOneWidget,
      ); // Case-insensitive or uppercase as per widget logic
    },
  );

  testWidgets('ShareableScorecard builds correctly with AppLocalizations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('de')],
        locale: const Locale('en'),
        home: const Scaffold(
          body: ShareableScorecard(
            gameName: 'Kniffel',
            winnerName: 'Player1',
            winnerColor: Colors.amber,
            finalScores: [PlayerScore('Player1', 250), PlayerScore('User', 200)],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('NexScore'), findsOneWidget);
    expect(
      find.text('Player1'),
      findsNWidgets(2),
    ); // Once in header, once in list
    expect(find.text('Kniffel'), findsOneWidget);
  });
}
