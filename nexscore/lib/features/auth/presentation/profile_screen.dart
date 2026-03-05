import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/logger.dart';
import '../../../core/error/failures.dart';
import '../../../core/error/result.dart';
import '../../../core/sync/gist_sync_service.dart';

/// Provider for the current Firebase Auth user (null = signed out / anonymous).
final authUserProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges().handleError((error) {
      debugPrint('FirebaseAuth Stream Error: $error');
      // Yield null user on any error like Firebase not configured
      return null;
    });
  } catch (e) {
    debugPrint('FirebaseAuth Initial Error: $e');
    return Stream.value(null);
  }
});

/// Auth service encapsulating Google Sign-In and sign-out logic.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Result<UserCredential>> signInWithGoogle() async {
    final stopwatch = Stopwatch()..start();
    try {
      final googleProvider = GoogleAuthProvider();
      final credential = await _auth.signInWithPopup(googleProvider);
      AppLogger.info(
        'Google Sign-In (Popup) successful',
        tag: 'Auth',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'uid': credential.user?.uid,
        },
      );
      return Result.success(credential);
    } catch (e, stack) {
      AppLogger.error(
        'Google Sign-In (Popup) failed',
        tag: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        AuthFailure('Sign-in failed', error: e, stackTrace: stack),
      );
    }
  }

  Future<Result<UserCredential>> signInWithGoogleNative() async {
    final stopwatch = Stopwatch()..start();
    try {
      final googleProvider = GoogleAuthProvider();
      UserCredential credential;
      if (kIsWeb) {
        // Use popup on web for better reliability on GitHub Pages
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
      final githubProvider = GithubAuthProvider();
      githubProvider.addScope('gist');
      githubProvider.setCustomParameters({'allow_signup': 'false'});

      final credential = await _auth.signInWithPopup(githubProvider);
      AppLogger.info(
        'GitHub Sign-In (Popup) successful',
        tag: 'Auth',
        metadata: {
          'duration': '${stopwatch.elapsedMilliseconds}ms',
          'uid': credential.user?.uid,
        },
      );
      return Result.success(credential);
    } catch (e, stack) {
      AppLogger.error(
        'GitHub Sign-In (Popup) failed',
        tag: 'Auth',
        error: e,
        stackTrace: stack,
      );
      return Result.failure(
        AuthFailure('GitHub Sign-in failed', error: e, stackTrace: stack),
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
final gistSyncServiceProvider = Provider<GistSyncService>(
  (ref) => GistSyncService(),
);

/// Profile / Account settings screen shown from settings or a dedicated tab.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authUserProvider);

    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l10n.get('account'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            centerTitle: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
          ),
          SliverToBoxAdapter(
            child: userAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(l10n.getWith('error_msg', [e.toString()])),
              ),
              data: (user) {
                if (user == null) {
                  return _SignedOutView(ref: ref);
                }
                return _SignedInView(user: user, ref: ref);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 96,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.get('account_signed_out_body'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.get('account_offline_note'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              final result = await authService.signInWithGoogleNative();
              result.fold((failure) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.getWith('account_sign_in_error', [
                          failure.message,
                        ]),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }, (_) {});
            },
            icon: const Icon(Icons.login),
            label: Text(l10n.get('account_sign_in_google')),
            style: OutlinedButton.styleFrom(minimumSize: const Size(280, 52)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final authService = ref.read(authServiceProvider);
              final result = await authService.signInWithGithub();
              result.fold(
                (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.getWith('account_sign_in_error', [
                            failure.message,
                          ]),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                (credential) {
                  // Capture GitHub OAuth access-token for Gist API calls
                  final oauthCred = credential.credential as OAuthCredential?;
                  if (oauthCred?.accessToken != null) {
                    ref
                        .read(gistSyncServiceProvider)
                        .setAccessToken(oauthCred!.accessToken!);
                  }
                },
              );
            },
            icon: const Icon(Icons.code),
            label: Text(l10n.get('account_sign_in_github')),
            style: OutlinedButton.styleFrom(minimumSize: const Size(280, 52)),
          ),
          const SizedBox(height: 48),
          Text(
            l10n.get('account_data_stay_note'),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView({required this.user, required this.ref});
  final User user;
  final WidgetRef ref;

  /// Returns true when the current user signed in via GitHub.
  bool get _isGitHubProvider {
    return user.providerData.any((info) => info.providerId == 'github.com');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGitHub = _isGitHubProvider;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 48,
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? const Icon(Icons.person, size: 48)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user.displayName ?? 'NexScore User',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(user.email ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Chip(
            label: Text(
              isGitHub
                  ? l10n.get('account_sync_github')
                  : l10n.get('account_sync_active'),
            ),
            avatar: Icon(isGitHub ? Icons.code : Icons.cloud_done, size: 16),
            backgroundColor: Colors.green.shade100,
          ),
          const SizedBox(height: 48),

          // ── Provider-specific sync tile ──
          if (isGitHub) ...[
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('GitHub Gist Backup'),
              subtitle: const Text('Backup your data to a private Gist'),
              trailing: IconButton(
                icon: const Icon(Icons.cloud_upload),
                onPressed: () => _backupToGist(context),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Restore from Gist'),
              subtitle: const Text('Download your data from GitHub'),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _restoreFromGist(context),
              ),
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.cloud_sync),
              title: const Text('Google Cloud Sync'),
              subtitle: Text(l10n.get('account_sync_active')),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.get('settings')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/settings'),
          ),
          const Divider(),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
            icon: const Icon(Icons.logout),
            label: Text(l10n.get('account_sign_out')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              side: BorderSide(color: Theme.of(context).colorScheme.error),
              minimumSize: const Size(200, 48),
            ),
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  // ── Gist helpers ──────────────────────────────────────────

  Future<void> _backupToGist(BuildContext context) async {
    final gistService = ref.read(gistSyncServiceProvider);
    final result = await gistService.backup();
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: ${failure.message}'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup to GitHub Gist complete ✓'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }

  Future<void> _restoreFromGist(BuildContext context) async {
    final gistService = ref.read(gistSyncServiceProvider);
    final result = await gistService.restore();
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: ${failure.message}'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restore from GitHub Gist complete ✓'),
          behavior: SnackBarBehavior.floating,
        ),
      ),
    );
  }
}
