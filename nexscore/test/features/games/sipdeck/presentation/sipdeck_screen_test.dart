import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/games/sipdeck/presentation/sipdeck_screen.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/providers/active_players_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:nexscore/core/multiplayer/providers/multiplayer_provider.dart';
import '../../../../mocks/mock_multiplayer_service.dart';

void main() {
  testWidgets('SipDeckScreen setup view does not overflow on small screens', (
    WidgetTester tester,
  ) async {
    // Set a small screen size to force overflow if SingleChildScrollView is missing
    tester.view.physicalSize = const Size(300, 400);
    tester.view.devicePixelRatio = 1.0;

    final players = [
      Player(id: '1', name: 'Alice', avatarColor: '#000000'),
      Player(id: '2', name: 'Bob', avatarColor: '#FFFFFF'),
    ];

    final container = ProviderContainer(
      overrides: [
        multiplayerServiceProvider.overrideWithValue(MockMultiplayerService()),
      ],
    );
    container.read(activePlayersProvider.notifier).setPlayers(players);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('de', '')],
          home: SipDeckScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Start button is present
    final startButton = find.byIcon(Icons.play_arrow);
    expect(startButton, findsOneWidget);

    // Scroll to the start button
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // Reset view size
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
