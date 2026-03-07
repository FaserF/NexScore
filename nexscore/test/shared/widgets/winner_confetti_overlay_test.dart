import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/shared/widgets/winner_confetti_overlay.dart';

void main() {
  group('WinnerConfettiOverlay', () {
    testWidgets('renders child widget', (tester) async {
      final controller = WinnerConfettiController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WinnerConfettiOverlay(
              controller: controller,
              child: const Text('Game Body'),
            ),
          ),
        ),
      );

      expect(find.text('Game Body'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('does NOT show winner banner initially', (tester) async {
      final controller = WinnerConfettiController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WinnerConfettiOverlay(
              controller: controller,
              child: const Text('Game Body'),
            ),
          ),
        ),
      );

      expect(find.text('WINNER!'), findsNothing);
      controller.dispose();
    });

    testWidgets('shows winner banner when controller.show() is called', (
      tester,
    ) async {
      final controller = WinnerConfettiController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WinnerConfettiOverlay(
              controller: controller,
              child: const Text('Game Body'),
            ),
          ),
        ),
      );

      controller.show(winnerName: 'Alice');
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('WINNER!'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('hides winner banner when Continue is pressed', (tester) async {
      final controller = WinnerConfettiController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WinnerConfettiOverlay(
              controller: controller,
              child: const Text('Game Body'),
            ),
          ),
        ),
      );

      controller.show(winnerName: 'Bob');
      await tester.pump();
      expect(find.text('WINNER!'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('WINNER!'), findsNothing);
      controller.dispose();
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

      controller.dispose();
    });
  });
}
