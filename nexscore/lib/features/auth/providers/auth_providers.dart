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

      String message = 'Linking failed';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'credential-already-in-use':
            message =
                'This Google account is already linked to another user. Please sign in with Google directly or use a different account.';
            break;
          case 'provider-already-linked':
            message = 'This user already has a Google account linked.';
            break;
          case 'invalid-credential':
            message = 'The Google credential is invalid or has expired.';
            break;
          case 'requires-recent-login':
            message =
                'For security reasons, this operation requires a recent login. Please sign out and sign in again before linking.';
            break;
          default:
            message = 'Linking failed (${e.code})';
        }
      }

      return Result.failure(AuthFailure(message, error: e, stackTrace: stack));
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

      String message = 'GitHub linking failed';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'credential-already-in-use':
            message =
                'This GitHub account is already linked to another user. Please sign in with GitHub directly or use a different account.';
            break;
          case 'provider-already-linked':
            message = 'This user already has a GitHub account linked.';
            break;
          case 'invalid-credential':
            message = 'The GitHub credential is invalid or has expired.';
            break;
          case 'requires-recent-login':
            message =
                'For security reasons, this operation requires a recent login. Please sign out and sign in again before linking.';
            break;
          default:
            message = 'GitHub linking failed (${e.code})';
        }
      }

      return Result.failure(AuthFailure(message, error: e, stackTrace: stack));
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

/// Extension to determine the primary identity (name/photo) based on the first linked social provider.
extension UserPrimaryIdentity on User {
  UserInfo? get primaryProvider {
    if (providerData.isEmpty) return null;
    // We prioritize social providers over 'firebase' (password) or anonymous
    final socialProviders = providerData.where(
      (info) =>
          info.providerId == 'google.com' || info.providerId == 'github.com',
    );
    return socialProviders.isNotEmpty
        ? socialProviders.first
        : providerData.first;
  }

  String get primaryDisplayName =>
      primaryProvider?.displayName ?? displayName ?? 'User';
  String? get primaryPhotoURL => primaryProvider?.photoURL ?? photoURL;

  bool isPrimaryProvider(String providerId) {
    return primaryProvider?.providerId == providerId;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
