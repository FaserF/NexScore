import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexscore/core/utils/app_version.dart';
import 'package:nexscore/features/settings/presentation/settings_screen.dart';
import 'package:nexscore/features/help/presentation/help_screen.dart';
import 'package:nexscore/core/i18n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: child,
      ),
    );
  }

  testWidgets('SettingsScreen displays correct version label', (tester) async {
    await tester.pumpWidget(createTestWidget(const SettingsScreen()));
    await tester.pumpAndSettle();

    final versionText = 'NexScore ${AppVersion.displayVersion}';
    final finder = find.text(versionText);

    // Scroll to the bottom to find the version label
    // Specify the main Scrollable to avoid conflict with TextField's internal scrollable
    await tester.scrollUntilVisible(
      finder,
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(finder, findsOneWidget);
  });

  testWidgets('HelpScreen displays correct version label', (tester) async {
    await tester.pumpWidget(createTestWidget(const HelpScreen()));
    await tester.pumpAndSettle();

    final versionText = 'NexScore ${AppVersion.displayVersion}';
    final finder = find.text(versionText);

    // Scroll to the bottom to find the version label
    await tester.scrollUntilVisible(finder, 100.0);
    await tester.pumpAndSettle();

    expect(finder, findsOneWidget);
  });
}
