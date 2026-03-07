import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/features/multiplayer/presentation/multiplayer_hub_screen.dart';
import 'package:nexscore/features/multiplayer/presentation/lobby_screen.dart';
import 'package:nexscore/features/settings/provider/settings_provider.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../mocks/mock_multiplayer_service.dart';
import 'package:nexscore/core/multiplayer/providers/multiplayer_provider.dart';

void main() {
  group('MultiplayerHubScreen Tests', () {
    testWidgets('displays hub buttons and opens diagnostics', (tester) async {
      final mockService = MockMultiplayerService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            multiplayerServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('de')],
            home: const MultiplayerHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations(const Locale('en'));

      // Verify buttons exist
      expect(find.text(l10n.get('multiplayer_host')), findsOneWidget);
      expect(find.text(l10n.get('multiplayer_join')), findsOneWidget);

      // Open diagnostics
      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pumpAndSettle();

      // Verify diagnostic dialog content
      expect(
        find.text(l10n.get('multiplayer_diagnostics')),
        findsAtLeastNWidgets(1),
      );
      expect(find.text(l10n.get('multiplayer_auth_title')), findsOneWidget);
      expect(find.text(l10n.get('multiplayer_adblock_title')), findsOneWidget);
      expect(find.text(l10n.get('multiplayer_domains_title')), findsOneWidget);

      // Close dialog
      await tester.tap(find.text(l10n.get('close')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.get('multiplayer_diagnostics')), findsNothing);
    });

    testWidgets('LobbyScreen shows alert when Firebase not configured', (
      tester,
    ) async {
      final mockService = ErrorMockMultiplayerService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            multiplayerServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('de')],
            home: const LobbyScreen(isHostingStart: true),
          ),
        ),
      );

      // Wait for the hosting attempt and the error dialog
      await tester.pump(); // Start _initLobby
      await tester.pump(); // Trigger the dialog show

      final l10n = AppLocalizations(const Locale('en'));

      expect(
        find.text(l10n.get('multiplayer_firebase_missing')),
        findsOneWidget,
      );
      expect(
        find.text(l10n.get('multiplayer_firebase_missing_desc')),
        findsOneWidget,
      );
    });
  });
}

class ErrorMockMultiplayerService extends MockMultiplayerService {
  @override
  Future<String> hostLobby({
    required String hostName,
    required String hostAvatarColor,
    int maxPlayers = 10,
  }) async {
    throw Exception('FIREBASE_NOT_CONFIGURED');
  }
}
