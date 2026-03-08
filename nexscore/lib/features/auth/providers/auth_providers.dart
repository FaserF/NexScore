import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/logger.dart';
import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';

/// Provider for the current Firebase Auth user (null = signed out / anonymous).
final authUserProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges().handleError((error) {
      debugPrint('FirebaseAuth Stream Error: $error');
      return null;
    });
  } catch (e) {
    debugPrint('FirebaseAuth Initial Error: $e');
    return Stream.value(null);
  }
});

/// Auth service encapsulating Google/GitHub Sign-In and sign-out logic.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Result<UserCredential>> signInWithGoogleNative() async {
    final stopwatch = Stopwatch()..start();
    try {
      try {
        Firebase.app();
      } catch (_) {
        return Result.failure(
          const AuthFailure(
            'Firebase not initialized. Check your Web configuration/Secrets.',
          ),
        );
      }

      final googleProvider = GoogleAuthProvider();
      UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(googleProvider);
      } else {
        credential = await _auth.signInWithProvider(googleProvider);
      }
      AppLogger.info(
        'Google Sign-In successful',
        tag: 'Auth',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'uid': credential.user?.uid,
          'platform': kIsWeb ? 'web' : 'native',
        },
      );
      return Result.success(credential);
    } catch (e, stack) {
      AppLogger.error(
        'Google Sign-In failed',
        tag: 'Auth',
        error: e,
        stackTrace: stack,
      );
      if (e is FirebaseException && e.code == 'core/no-app') {
        return Result.failure(
          AuthFailure(
            'Cloud sync is not configured for this app instance.',
            error: e,
            stackTrace: stack,
          ),
        );
      }
      return Result.failure(
        AuthFailure('Sign-in failed', error: e, stackTrace: stack),
      );
    }
  }

  Future<Result<UserCredential>> signInWithGithub() async {
    final stopwatch = Stopwatch()..start();
    try {
      try {
        Firebase.app();
      } catch (_) {
        return Result.failure(
          const AuthFailure(
            'Firebase not initialized. Check your Web configuration/Secrets.',
          ),
        );
      }

      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('gist');
      githubProvider.setCustomParameters({'allow_signup': 'false'});

      UserCredential credential;
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(githubProvider);
      } else {
        credential = await _auth.signInWithProvider(githubProvider);
      }
      AppLogger.info(
        'GitHub Sign-In successful',
        tag: 'Auth',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'uid': credential.user?.uid,
        },
      );
      return Result.success(credential);
    } catch (e, stack) {
      AppLogger.error(
        'GitHub Sign-In failed',
        tag: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        AuthFailure('GitHub Sign-in failed', error: e, stackTrace: stack),
      );
    }
  }

  Future<Result<UserCredential>> linkWithGoogle() async {
    final stopwatch = Stopwatch()..start();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure('No user logged in'));
      }

      final googleProvider = GoogleAuthProvider();
      UserCredential credential;
      if (kIsWeb) {
        credential = await user.linkWithPopup(googleProvider);
      } else {
        credential = await user.linkWithProvider(googleProvider);
      }
      AppLogger.info(
        'Google linking successful',
        tag: 'Auth',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'uid': credential.user?.uid,
        },
      );
      return Result.success(credential);
    } catch (e, stack) {
      AppLogger.error(
        'Google linking failed',
        tag: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        AuthFailure('Linking failed', error: e, stackTrace: stack),
      );
    }
  }

  Future<Result<UserCredential>> linkWithGithub() async {
    final stopwatch = Stopwatch()..start();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Result.failure(const AuthFailure('No user logged in'));
      }

      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('gist');

      UserCredential credential;
      if (kIsWeb) {
        credential = await user.linkWithPopup(githubProvider);
      } else {
        credential = await user.linkWithProvider(githubProvider);
      }
      AppLogger.info(
        'GitHub linking successful',
        tag: 'Auth',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'uid': credential.user?.uid,
        },
      );
      return Result.success(credential);
    } catch (e, stack) {
      AppLogger.error(
        'GitHub linking failed',
        tag: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        AuthFailure('GitHub linking failed', error: e, stackTrace: stack),
      );
    }
  }

  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      AppLogger.info('Sign-out successful', tag: 'Auth');
      return const Result.success(null);
    } catch (e, stack) {
      AppLogger.error(
        'Sign-out failed',
        tag: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        AuthFailure('Sign-out failed', error: e, stackTrace: stack),
      );
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
