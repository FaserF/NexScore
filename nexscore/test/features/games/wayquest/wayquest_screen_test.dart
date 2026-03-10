import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/features/games/wayquest/presentation/wayquest_screen.dart';

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

    testWidgets('tapping start draws a card', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('START VOYAGE'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets); // Category selection cards + the drawn card
      // We expect the gesture detector on the card to be there
    });
  });
}
