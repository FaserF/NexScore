import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/shared/widgets/swipeable_card.dart';

void main() {
  group('SwipeableCard', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              cardKey: const ValueKey('card1'),
              onSwipe: () {},
              child: const Text('Test Card'),
            ),
          ),
        ),
      );

      expect(find.text('Test Card'), findsOneWidget);
    });

    testWidgets('calls onSwipe when tapped', (tester) async {
      bool swiped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              cardKey: const ValueKey('card1'),
              onSwipe: () => swiped = true,
              child: const SizedBox(width: 300, height: 300),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SwipeableCard));
      await tester.pumpAndSettle();

      expect(swiped, isTrue);
    });

    testWidgets('calls onSwipe on horizontal swipe past threshold', (
      tester,
    ) async {
      bool swiped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              cardKey: const ValueKey('card1'),
              onSwipe: () => swiped = true,
              child: const SizedBox(
                width: 300,
                height: 300,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      // Drag more than 100px threshold
      await tester.drag(find.byType(SwipeableCard), const Offset(150, 0));
      await tester.pumpAndSettle();

      expect(swiped, isTrue);
    });

    testWidgets('does NOT call onSwipe on small drag below threshold', (
      tester,
    ) async {
      bool swiped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              cardKey: const ValueKey('card1'),
              onSwipe: () => swiped = true,
              child: const SizedBox(
                width: 300,
                height: 300,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      );

      // Drag less than 100px threshold
      await tester.drag(find.byType(SwipeableCard), const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(swiped, isFalse);
    });

    testWidgets('animates transition when cardKey changes', (tester) async {
      int swipeCount = 0;
      final keyNotifier = ValueNotifier<String>('card1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: keyNotifier,
              builder: (context, key, _) {
                return SwipeableCard(
                  cardKey: ValueKey(key),
                  onSwipe: () {
                    swipeCount++;
                    keyNotifier.value = 'card${swipeCount + 1}';
                  },
                  child: Container(
                    width: 300,
                    height: 300,
                    color: Colors.blue,
                    child: Text('Card $key'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Card card1'), findsOneWidget);

      // Tap the colored container child to ensure hit-test works
      await tester.tap(find.text('Card card1'));
      await tester.pumpAndSettle();

      expect(find.text('Card card2'), findsOneWidget);
    });
  });
}
