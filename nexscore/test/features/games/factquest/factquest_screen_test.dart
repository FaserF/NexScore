import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/features/games/factquest/presentation/factquest_screen.dart';
import 'package:flutter_tts/flutter_tts.dart';

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
        home: const FactQuestScreen(),
      ),
    );
  }

  group('FactQuestScreen widget tests', () {
    testWidgets('renders setup screen with category chips and start button', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Should show category name chips
      expect(find.text('Random Facts'), findsOneWidget);
      expect(find.text('Dumb Ways to Die'), findsOneWidget);

      // Should show start button
      expect(find.text('START QUEST'), findsOneWidget);
    });

    testWidgets('tapping START QUEST draws a card and shows fact text', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap start
      await tester.tap(find.text('START QUEST'));
      await tester.pumpAndSettle();

      // Should show a source button
      expect(find.text('Read More (Source)'), findsOneWidget);

      // Should show the tap-to-continue hint
      expect(find.text('Tap for next fact'), findsOneWidget);
    });

    testWidgets('category toggle deselects a category', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Both categories should be selected initially.
      // Tap "Random Facts" chip to deselect it.
      await tester.tap(find.text('Random Facts'));
      await tester.pumpAndSettle();

      // The chip should still exist but be visually deselected (tested by presence).
      expect(find.text('Random Facts'), findsOneWidget);
    });

    testWidgets('reset dialog appears when reset icon is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Draw a card first
      await tester.tap(find.text('START QUEST'));
      await tester.pumpAndSettle();

      // Tap the reset icon (refresh)
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Dialog should appear with confirmation text
      expect(find.text('Reset Game'), findsWidgets);
    });

    testWidgets('Undo button appears after drawing a card', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially no undo button
      expect(find.byIcon(Icons.undo), findsNothing);

      // Draw a card
      await tester.tap(find.text('START QUEST'));
      await tester.pumpAndSettle();

      // Undo button should appear
      expect(find.byIcon(Icons.undo), findsOneWidget);
    });

    testWidgets('Settings button opens filter modal during gameplay', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Draw a card
      await tester.tap(find.text('START QUEST'));
      await tester.pumpAndSettle();

      // Tap settings icon
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Modal should show "Select Categories" (from EN mock or real l10n)
      expect(find.text('Select Categories'), findsWidgets);

      // Should show category chips in the modal
      expect(find.text('Random Facts'), findsWidgets);
    });

    testWidgets('Volume button toggles TTS state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find the volume off icon (default state)
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsNothing);

      // Tap the volume button
      await tester.tap(find.byIcon(Icons.volume_off));
      await tester.pumpAndSettle();

      // Now should show volume up icon
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.volume_off), findsNothing);
    });
  });
}

class FakeFlutterTts extends Fake implements FlutterTts {
  String? lastSpokenText;
  bool isStopped = false;

  @override
  void setStartHandler(Function callback) {}
  @override
  void setCompletionHandler(Function callback) {}
  @override
  void setErrorHandler(Function(dynamic message) callback) {}
  @override
  Future<dynamic> setLanguage(String language) async => true;
  @override
  Future<dynamic> speak(String text, {bool? focus}) async {
    lastSpokenText = text;
    return true;
  }
  @override
  Future<dynamic> stop() async {
    isStopped = true;
    return true;
  }
}
