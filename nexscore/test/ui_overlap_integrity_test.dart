import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/volleyball/presentation/volleyball_scoreboard.dart';
import 'package:nexscore/features/games/volleyball/providers/volleyball_provider.dart';
import 'package:nexscore/features/games/volleyball/models/volleyball_models.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io';

void main() {
  group('UI Overlap Integrity', () {
    testWidgets('Volleyball Winner View buttons are not obscured', (
      tester,
    ) async {
      final container = ProviderContainer();
      final notifier = container.read(volleyballStateProvider.notifier);

      notifier.setupMatch(
        type: VolleyballType.beach,
        teamA: 'Team A',
        teamB: 'Team B',
        setsToWin: 1,
        pA: [],
        pB: [],
      );

      notifier.finishMatchEarly();

      // Use a larger surface size to ensure things don't go off context
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('en', '')],
            home: Scaffold(body: VolleyballScoreboard()),
          ),
        ),
      );

      notifier.finishMatchEarly();
      // Pump several times to handle the postFrameCallbacks and initial animations
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Diagnostic check: ensure match is finished
      final state = container.read(volleyballStateProvider);
      debugPrint('DEBUG: state.matchFinished = ${state.matchFinished}');
      debugPrint('DEBUG: state.setupDone = ${state.setupDone}');

      expect(state.matchFinished, isTrue);

      debugDumpApp();

      final pdfButton = find.byIcon(Icons.picture_as_pdf);
      final shareButton = find.byIcon(Icons.share);

      expect(pdfButton, findsWidgets);
      expect(shareButton, findsWidgets);

      final pdfCenter = tester.getCenter(pdfButton.first);
      final shareCenter = tester.getCenter(shareButton.first);

      // They should not be at the exact same position (overlap)
      // On wide screens they might be side-by-side (same dy), which is fine.
      expect(pdfCenter, isNot(equals(shareCenter)));

      // Clear pending timers from celebration
      await tester.pump(const Duration(seconds: 5));
    });

    test('Source code integrity: No risky Positioned.fill in Scoreboard', () {
      final file = File(
        'lib/features/games/volleyball/presentation/volleyball_scoreboard.dart',
      );
      if (!file.existsSync()) return;

      final content = file.readAsStringSync();
      final riskyMatch = RegExp(r'Positioned\.fill').allMatches(content);
      expect(
        riskyMatch.length,
        1,
        reason:
            'Exactly 1 Positioned.fill allowed for the Side Switch overlay. Others are risky.',
      );
    });
  });
}
