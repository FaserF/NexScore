import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/router/app_router.dart';
import 'package:nexscore/core/multiplayer/providers/multiplayer_provider.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexscore/features/players/repository/player_repository.dart';
import 'package:nexscore/features/history/repository/session_repository.dart';
import 'package:nexscore/features/auth/presentation/profile_screen.dart';
import 'package:nexscore/core/models/player_model.dart';
import 'package:nexscore/core/models/session_model.dart';
import '../../mocks/mock_multiplayer_service.dart';

void main() {
  group('Navigation Integrity Tests', () {
    late MockMultiplayerService mockMultiplayer;

    setUp(() {
      mockMultiplayer = MockMultiplayerService();
    });

    testWidgets('Verify Multiplayer routes exist', (tester) async {
      final overrides = [
        multiplayerServiceProvider.overrideWithValue(mockMultiplayer),
        playersProvider.overrideWith(() => MockPlayersNotifier()),
        sessionsProvider.overrideWith(() => MockSessionsNotifier()),
        authUserProvider.overrideWith((ref) => Stream.value(null)),
      ];

      final container = ProviderContainer(overrides: overrides);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('de')],
          ),
        ),
      );

      final l10n = AppLocalizations(const Locale('en'));

      // Test absolute paths that previously failed
      router.go('/multiplayer/host');
      await tester.pumpAndSettle();
      expect(find.text(l10n.get('multiplayer_host')), findsAtLeastNWidgets(1));

      router.go('/multiplayer/join');
      await tester.pumpAndSettle();
      expect(find.text(l10n.get('multiplayer_join')), findsAtLeastNWidgets(1));

      router.go('/multiplayer');
      await tester.pumpAndSettle();
      expect(find.text(l10n.get('multiplayer_hub')), findsAtLeastNWidgets(1));
    });

    testWidgets('Verify all Game routes exist', (tester) async {
      final overrides = [
        multiplayerServiceProvider.overrideWithValue(mockMultiplayer),
        playersProvider.overrideWith(() => MockPlayersNotifier()),
        sessionsProvider.overrideWith(() => MockSessionsNotifier()),
        authUserProvider.overrideWith((ref) => Stream.value(null)),
      ];

      final container = ProviderContainer(overrides: overrides);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides,
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('de')],
          ),
        ),
      );

      final games = [
        'wizard',
        'qwixx',
        'schafkopf',
        'kniffel',
        'sipdeck',
        'phase10',
        'darts',
        'romme',
        'buzztap',
      ];

      for (final game in games) {
        router.go('/games/setup/$game');
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });
}

class MockPlayersNotifier extends PlayersNotifier {
  @override
  Future<List<Player>> build() async => [];
}

class MockSessionsNotifier extends SessionsNotifier {
  @override
  Future<List<Session>> build() async => [];
}
