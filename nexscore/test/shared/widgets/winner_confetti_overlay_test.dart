import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/shared/widgets/winner_confetti_overlay.dart';
import 'package:nexscore/core/providers/audio_provider.dart';
import 'package:nexscore/core/providers/share_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class FakeAudioPlayer extends Fake implements AudioPlayer {
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  group('WinnerConfettiOverlay', () {
    testWidgets('renders child widget', (tester) async {
      final controller = WinnerConfettiController();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WinnerConfettiOverlay(
                controller: controller,
                child: const Text('Game Body'),
              ),
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
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WinnerConfettiOverlay(
                controller: controller,
                child: const Text('Game Body'),
              ),
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
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WinnerConfettiOverlay(
                controller: controller,
                child: const Text('Game Body'),
              ),
            ),
          ),
        ),
      );

      controller.show(winnerName: 'Alice');
      // Animation duration is 600ms
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('WINNER!'), findsOneWidget);
      controller.dispose();
    });

    testWidgets('hides winner banner when Continue is pressed', (tester) async {
      final controller = WinnerConfettiController();
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: WinnerConfettiOverlay(
                controller: controller,
                child: const Text('Game Body'),
              ),
            ),
          ),
        ),
      );

      controller.show(winnerName: 'Bob');
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('WINNER!'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

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
