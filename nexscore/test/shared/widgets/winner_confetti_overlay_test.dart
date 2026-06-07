import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/shared/widgets/winner_confetti_overlay.dart';

void main() {
  group('WinnerConfettiOverlay', () {
    testWidgets('renders child widget', (tester) async {
      final controller = WinnerConfettiController();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('de')],
          localizationsDelegates: const [AppLocalizationsDelegate()],
          home: Scaffold(
            body: ProviderScope(
              child: WinnerConfettiOverlay(
                controller: controller,
                child: const Text('Game Body'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Game Body'), findsOneWidget);
    });

    test('WinnerConfettiController notifies listeners', () {
      final controller = WinnerConfettiController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.show(winnerName: 'Charlie');
      expect(notifyCount, 1);
      expect(controller.isShowing, true);
      expect(controller.winnerName, 'Charlie');

      controller.hide();
      expect(notifyCount, 2);
      expect(controller.isShowing, false);
    });
  });
}
