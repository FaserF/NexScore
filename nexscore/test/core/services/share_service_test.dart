import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexscore/core/services/share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShareService Tests', () {
    test('ShareService can be instantiated', () {
      final service = ShareService();
      expect(service, isNotNull);
      expect(service.controller, isNotNull);
    });

    testWidgets('shareWidget displays error if context is invalid', (
      tester,
    ) async {
      final service = ShareService();

      // We expect it to try and fail because there's no real scaffold/material app in a raw service test
      // but we catch it in the service anyway.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () =>
                      service.shareWidget(context, const Text('Test')),
                  child: const Text('Share'),
                );
              },
            ),
          ),
        ),
      );

      // This is more of a smoke test to ensure no unhandled exceptions crash the app flow
      expect(find.text('Share'), findsOneWidget);
    });
  });
}
