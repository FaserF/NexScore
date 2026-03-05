import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/i18n/app_localizations.dart';
import 'core/presentation/environment_banner.dart';
import 'features/settings/provider/settings_provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Basic initialization. On Web, options are required but if missing,
    // we should at least catch the specific error gracefully.
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  runApp(const ProviderScope(child: NexScoreApp()));
}

class NexScoreApp extends ConsumerWidget {
  const NexScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeMode = settings.themeMode;
    final locale = settings.locale;

    final ThemeData lightTheme = AppTheme.lightTheme;
    final ThemeData darkTheme = AppTheme.darkTheme;

    final router = ref.watch(routerProvider);

    return EnvironmentBanner(
      child: MaterialApp.router(
        title: 'NexScore',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        locale: locale,
        routerConfig: router,
        supportedLocales: const [
          Locale('en', ''), // English
          Locale('de', ''), // German
        ],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}
