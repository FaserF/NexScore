import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/firebase/firebase_options_web.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/i18n/app_localizations.dart';
import 'core/presentation/environment_banner.dart';
import 'features/settings/provider/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      if (FirebaseOptionsWeb.isConfigured) {
        await Firebase.initializeApp(
          options: FirebaseOptionsWeb.currentPlatform,
        );
      } else {
        debugPrint('Firebase Web: Initialization skipped (No config)');
      }
    } else {
      // Basic initialization for mobile (uses google-services.json / plist)
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
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

    return MaterialApp.router(
      title: 'NexScore',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      scrollBehavior: AppScrollBehavior(),
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
      builder: (context, child) => EnvironmentBanner(child: child!),
    );
  }
}
