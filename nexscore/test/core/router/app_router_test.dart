import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/router/app_router.dart';
import 'package:nexscore/core/providers/active_players_provider.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';

void main() {
  testWidgets('App Router handles /games/arschloch route', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    container.read(activePlayersProvider.notifier).setPlayers([
      Player(id: '1', name: 'Alice', avatarColor: '#000000'),
      Player(id: '2', name: 'Bob', avatarColor: '#000000'),
      Player(id: '3', name: 'Charlie', avatarColor: '#000000'),
    ]);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', ''), Locale('de', '')],
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Go to arschloch route
    router.go('/games/arschloch');
    await tester.pumpAndSettle();

    // Verification that it did not crash and rendered Arschloch
    expect(find.byIcon(Icons.help_outline), findsWidgets);
  });
}
