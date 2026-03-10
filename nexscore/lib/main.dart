import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'core/firebase/firebase_options_web.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/router/app_router.dart';
import 'core/i18n/app_localizations.dart';
import 'core/presentation/environment_banner.dart';
import 'features/settings/provider/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_scroll_behavior.dart';
import 'core/lifecycle/app_lifecycle_observer.dart';
import 'core/utils/app_logger.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Intercept all debugPrint calls to route them into our AppLogger
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      AppLogger.addLog(message);
      // Only spam the console if the user explicitly enabled debug mode
      if (AppLogger.debugMode || kDebugMode) {
        originalDebugPrint(message, wrapWidth: wrapWidth);
      }
    }
  };

  // Catch Flutter-specific errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.addLog('FLUTTER ERROR: ${details.exceptionAsString()}\n${details.stack}');
  };

  // Catch errors not caught by the Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.addLog('PLATFORM ERROR: $error\n$stack');
    return false; // Let the platform handle it too
  };

  if (kIsWeb) {
    // For GitHub Pages compatibility, the Hash strategy is preferred.
    //   usePathUrlStrategy();
    setUrlStrategy(null);
  }

  try {
    if (kIsWeb) {
      if (FirebaseOptionsWeb.isConfigured) {
        debugPrint(
          'Firebase Web: Initializing with projectId: ${FirebaseOptionsWeb.projectId}',
        );
        await Firebase.initializeApp(
          options: FirebaseOptionsWeb.currentPlatform,
        );
        debugPrint('Firebase Web: Initialization successful');
      } else {
        debugPrint(
          'Firebase Web: Initialization skipped (No config detected in environment)',
        );
      }
    } else {
      debugPrint('Firebase Mobile: Initializing...');
      await Firebase.initializeApp();
      debugPrint('Firebase Mobile: Initialization successful');
    }
  } catch (e, stack) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stack');
  }

  // Configure Firestore specifically to prevent Web timeouts
  try {
    debugPrint('Firestore: Applying settings...');
    firestore.FirebaseFirestore.instance.settings = firestore.Settings(
      persistenceEnabled: false,
      // experimentalForceLongPolling is often required on GitHub Pages 
      // where gRPC-web connections can be unstable or blocked.
      webExperimentalForceLongPolling: kIsWeb,
    );
    debugPrint(
      'Firestore settings applied: persistenceEnabled=${firestore.FirebaseFirestore.instance.settings.persistenceEnabled}, webExperimentalForceLongPolling=$kIsWeb',
    );
  } catch (e) {
    debugPrint('Firestore settings error: $e');
  }

  runApp(const ProviderScope(child: NexScoreApp()));
}

class NexScoreApp extends ConsumerWidget {
  const NexScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Initialize the lifecycle observer to auto-save games
    ref.watch(appLifecycleObserverProvider);
    final themeMode = settings.themeMode;
    final locale = settings.locale;

    final ThemeData lightTheme = AppTheme.lightTheme;
    final ThemeData darkTheme = AppTheme.darkTheme;

    return MaterialApp.router(
      title: 'NexScore',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      routerConfig: ref.watch(routerProvider),
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
