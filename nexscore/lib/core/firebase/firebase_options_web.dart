import 'package:firebase_core/firebase_core.dart';

/// Helper class to construct [FirebaseOptions] from environment variables.
/// These are provided via --dart-define during the build process.
class FirebaseOptionsWeb {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'nexscore-app.firebaseapp.com',
  );
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'nexscore-app',
  );
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'nexscore-app.firebasestorage.app',
  );
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '96410867697',
  );
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');

  static bool get isConfigured => apiKey.isNotEmpty && appId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: apiKey,
      authDomain: authDomain,
      projectId: projectId,
      storageBucket: storageBucket,
      messagingSenderId: messagingSenderId,
      appId: appId,
    );
  }
}
