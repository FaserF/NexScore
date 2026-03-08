import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../../../core/sync/gist_sync_service.dart';

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
                  return const _SignedOutView();
                }
                return _SignedInView(user: user);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutView extends ConsumerStatefulWidget {
  const _SignedOutView();

  @override
  ConsumerState<_SignedOutView> createState() => _SignedOutViewState();
}

class _SignedOutViewState extends ConsumerState<_SignedOutView> {
  bool _isGoogleLoading = false;
  bool _isGithubLoading = false;

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
            onPressed: _isGoogleLoading || _isGithubLoading
                ? null
                : () async {
                    setState(() => _isGoogleLoading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    debugPrint('Auth: Google Sign-In requested');
                    final authService = ref.read(authServiceProvider);
                    final result = await authService.signInWithGoogleNative();
                    debugPrint('Auth: Result received: ${result.isSuccess}');
                    if (mounted) {
                      setState(() => _isGoogleLoading = false);
                      result.fold(
                        (failure) {
                          debugPrint('Auth: Failure: ${failure.message}');
                          _showError(context, l10n, failure.message, messenger);
                        },
                        (_) {
                          debugPrint('Auth: Success');
                        },
                      );
                    }
                  },
            icon: _isGoogleLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login),
            label: Text(l10n.get('account_sign_in_google')),
            style: OutlinedButton.styleFrom(minimumSize: const Size(280, 52)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isGoogleLoading || _isGithubLoading
                ? null
                : () async {
                    setState(() => _isGithubLoading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    debugPrint('Auth: GitHub Sign-In requested');
                    final authService = ref.read(authServiceProvider);
                    final result = await authService.signInWithGithub();
                    debugPrint('Auth: Result received: ${result.isSuccess}');
                    if (mounted) {
                      setState(() => _isGithubLoading = false);
                      result.fold(
                        (failure) {
                          debugPrint('Auth: Failure: ${failure.message}');
                          _showError(context, l10n, failure.message, messenger);
                        },
                        (credential) {
                          debugPrint('Auth: Success');
                          // Capture GitHub OAuth access-token for Gist API calls
                          final oauthCred =
                              credential.credential as OAuthCredential?;
                          if (oauthCred?.accessToken != null) {
                            ref
                                .read(gistSyncServiceProvider)
                                .setAccessToken(oauthCred!.accessToken!);
                          }
                        },
                      );
                    }
                  },
            icon: _isGithubLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.code),
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

  void _showError(
    BuildContext context,
    AppLocalizations l10n,
    String message,
    ScaffoldMessengerState messenger,
  ) {
    // Show SnackBar
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.getWith('account_sign_in_error', [message])),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
      ),
    );

    // Also show a Dialog as a fallback
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('error')),
        content: Text(l10n.getWith('account_sign_in_error', [message])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('ok')),
          ),
        ],
      ),
    );
  }
}

class _SignedInView extends ConsumerStatefulWidget {
  const _SignedInView({required this.user});
  final User user;

  @override
  ConsumerState<_SignedInView> createState() => _SignedInViewState();
}

class _SignedInViewState extends ConsumerState<_SignedInView> {
  bool _isGoogleLoading = false;
  bool _isGithubLoading = false;

  /// Returns true when the current user signed in via GitHub.
  bool get _isGitHubProvider {
    return widget.user.providerData.any(
      (info) => info.providerId == 'github.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isGitHub = _isGitHubProvider;
    final isGuest = widget.user.isAnonymous;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 48,
            backgroundColor: isGuest ? Colors.grey.shade200 : null,
            backgroundImage: !isGuest && widget.user.photoURL != null
                ? NetworkImage(widget.user.photoURL!)
                : null,
            child: isGuest || widget.user.photoURL == null
                ? Icon(isGuest ? Icons.person_outline : Icons.person, size: 48)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            isGuest
                ? l10n.get('account_guest')
                : (widget.user.displayName ?? l10n.get('account_default_name')),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (!isGuest)
            Text(
              widget.user.email ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 8),
          Chip(
            label: Text(
              isGuest
                  ? l10n.get('account_guest_sync_label')
                  : (isGitHub
                        ? l10n.get('account_sync_github')
                        : l10n.get('account_sync_active')),
            ),
            avatar: Icon(
              isGuest
                  ? Icons.cloud_off
                  : (isGitHub ? Icons.code : Icons.cloud_done),
              size: 16,
            ),
            backgroundColor: isGuest
                ? Colors.orange.shade100
                : Colors.green.shade100,
          ),
          const SizedBox(height: 48),

          // ── Provider-specific sync tile ──
          if (isGuest) ...[
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange),
              title: Text(l10n.get('account_guest_status')),
              subtitle: Text(l10n.get('account_signed_out_body')),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _isGoogleLoading || _isGithubLoading
                  ? null
                  : () async {
                      setState(() => _isGoogleLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await ref
                          .read(authServiceProvider)
                          .signInWithGoogleNative();
                      if (mounted) setState(() => _isGoogleLoading = false);
                      result.fold((failure) {
                        _showError(context, l10n, failure.message, messenger);
                      }, (_) {});
                    },
              icon: _isGoogleLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(l10n.get('account_sign_in_google')),
              style: OutlinedButton.styleFrom(minimumSize: const Size(280, 52)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isGoogleLoading || _isGithubLoading
                  ? null
                  : () async {
                      setState(() => _isGithubLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await ref
                          .read(authServiceProvider)
                          .signInWithGithub();
                      if (mounted) setState(() => _isGithubLoading = false);
                      result.fold(
                        (failure) {
                          _showError(context, l10n, failure.message, messenger);
                        },
                        (credential) {
                          // Handle GitHub token persistence if needed
                          final oauthCred =
                              credential.credential as OAuthCredential?;
                          if (oauthCred?.accessToken != null) {
                            ref
                                .read(gistSyncServiceProvider)
                                .setAccessToken(oauthCred!.accessToken!);
                          }
                        },
                      );
                    },
              icon: _isGithubLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.code),
              label: Text(l10n.get('account_sign_in_github')),
              style: OutlinedButton.styleFrom(minimumSize: const Size(280, 52)),
            ),
          ] else if (isGitHub) ...[
            ListTile(
              leading: const Icon(Icons.backup),
              title: Text(l10n.get('account_gist_backup_title')),
              subtitle: Text(l10n.get('account_gist_backup_desc')),
              trailing: IconButton(
                icon: const Icon(Icons.cloud_upload),
                onPressed: () => _backupToGist(context),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: Text(l10n.get('account_gist_restore_title')),
              subtitle: Text(l10n.get('account_gist_restore_desc')),
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

  void _showError(
    BuildContext context,
    AppLocalizations l10n,
    String message,
    ScaffoldMessengerState messenger,
  ) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.getWith('account_sign_in_error', [message])),
        backgroundColor: Colors.red,
      ),
    );
  }
}
