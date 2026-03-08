import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../providers/auth_providers.dart';
import '../../../core/sync/gist_sync_service.dart';
import '../../settings/provider/settings_provider.dart';

final gistSyncServiceProvider = Provider<GistSyncService>(
  (ref) => GistSyncService(ref: ref),
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
                    final authService = ref.read(authServiceProvider);
                    final result = await authService.signInWithGoogleNative();
                    if (mounted) {
                      setState(() => _isGoogleLoading = false);
                      result.fold((failure) {
                        _showError(context, l10n, failure.message, messenger);
                      }, (_) {});
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
                    final authService = ref.read(authServiceProvider);
                    final result = await authService.signInWithGithub();
                    if (mounted) {
                      setState(() => _isGithubLoading = false);
                      result.fold(
                        (failure) {
                          _showError(context, l10n, failure.message, messenger);
                        },
                        (credential) {
                          final oauthCred =
                              credential.credential as OAuthCredential?;
                          if (oauthCred != null &&
                              oauthCred.accessToken != null) {
                            final gistService = ref.read(
                              gistSyncServiceProvider,
                            );
                            gistService.setAccessToken(oauthCred.accessToken!);
                            _checkAndPromptRestore(context, gistService);
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

  Future<void> _checkAndPromptRestore(
    BuildContext context,
    GistSyncService gistService,
  ) async {
    final timestamp = await gistService.getBackupTimestamp();
    if (timestamp != null && context.mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Found'),
          content: Text(
            'A backup from ${timestamp.toLocal().toString().split('.')[0]} was found on GitHub. Would you like to restore it now?\n\nThis will merge the cloud data with your local data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore Now'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        await _restoreFromGist(context);
      }
    }
  }

  Future<void> _restoreFromGist(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final gistService = ref.read(gistSyncServiceProvider);

    final result = await gistService.restore();
    if (context.mounted) {
      if (result.isSuccess) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.get('account_gist_restore_success'))),
        );
      } else {
        _showError(context, l10n, result.failure.message, messenger);
      }
    }
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
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
      ),
    );

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

  bool get _isGitHubLinked {
    return widget.user.providerData.any(
      (info) => info.providerId == 'github.com',
    );
  }

  bool get _isGoogleLinked {
    return widget.user.providerData.any(
      (info) => info.providerId == 'google.com',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final isGoogle = _isGoogleLinked;
    final isGitHub = _isGitHubLinked;
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
            backgroundImage: !isGuest && widget.user.primaryPhotoURL != null
                ? NetworkImage(widget.user.primaryPhotoURL!)
                : null,
            child: isGuest || widget.user.primaryPhotoURL == null
                ? Icon(isGuest ? Icons.person_outline : Icons.person, size: 48)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            isGuest
                ? l10n.get('account_guest')
                : widget.user.primaryDisplayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (!isGuest)
            Text(
              widget.user.email ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (isGuest)
                Chip(
                  label: Text(l10n.get('account_guest_sync_label')),
                  avatar: const Icon(Icons.cloud_off, size: 16),
                  backgroundColor: Colors.orange.shade100,
                ),
              if (isGoogle)
                Chip(
                  label: Text(
                    widget.user.isPrimaryProvider('google.com')
                        ? 'Google (${l10n.get('account_primary')})'
                        : 'Google (${l10n.get('account_backup')})',
                  ),
                  avatar: const Icon(Icons.cloud_done, size: 16),
                  backgroundColor: const Color(0xFFE8F5E9),
                ),
              if (isGitHub)
                Chip(
                  label: Text(
                    widget.user.isPrimaryProvider('github.com')
                        ? '${l10n.get('account_sync_github')} (${l10n.get('account_primary')})'
                        : '${l10n.get('account_sync_github')} (${l10n.get('account_backup')})',
                  ),
                  avatar: const Icon(Icons.code, size: 16),
                  backgroundColor: Colors.blue.shade100,
                ),
            ],
          ),
          const SizedBox(height: 48),

          if (isGuest) ...[
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.orange),
              title: Text(l10n.get('account_guest_status')),
              subtitle: Text(l10n.get('account_signed_out_body')),
            ),
            const SizedBox(height: 32),
            _AuthButton(
              label: l10n.get('account_sign_in_google'),
              icon: Icons.login,
              isLoading: _isGoogleLoading,
              onPressed: () async {
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
            ),
            const SizedBox(height: 12),
            _AuthButton(
              label: l10n.get('account_sign_in_github'),
              icon: Icons.code,
              isLoading: _isGithubLoading,
              onPressed: () async {
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
                    final oauthCred = credential.credential as OAuthCredential?;
                    if (oauthCred != null && oauthCred.accessToken != null) {
                      final gistService = ref.read(gistSyncServiceProvider);
                      gistService.setAccessToken(oauthCred.accessToken!);
                      _checkAndPromptRestore(context, gistService);
                    }
                  },
                );
              },
            ),
          ] else ...[
            if (isGitHub) ...[
              const _SectionLabel(label: 'GitHub Backup (Gist)'),
              ListTile(
                leading: const Icon(Icons.backup),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.get('account_gist_backup_desc')),
                    if (settings.lastBackupTime != null &&
                        settings.lastBackupProvider == 'github')
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Last backup: ${settings.lastBackupTime!.toLocal().toString().split('.')[0]}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  onPressed: () => _backupToGist(context),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download),
                title: Text(l10n.get('account_gist_restore_title')),
                subtitle: Text(l10n.get('account_gist_restore_desc')),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _restoreFromGist(context),
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Auto Backup'),
                subtitle: const Text('Automatically backup to GitHub daily'),
                secondary: const Icon(Icons.sync),
                value: settings.autoBackupEnabled,
                onChanged: (val) {
                  ref.read(settingsProvider.notifier).setAutoBackupEnabled(val);
                },
              ),
              const Divider(),
            ],
            if (isGoogle) ...[
              const _SectionLabel(label: 'Google Account'),
              ListTile(
                leading: const Icon(Icons.account_circle),
                title: const Text('Google Cloud Sync'),
                subtitle: Text(l10n.get('account_sync_active')),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
              const Divider(),
            ],
            if (!isGoogle || !isGitHub) ...[
              _SectionLabel(label: l10n.get('account_link_additional')),
              if (!isGoogle)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _AuthButton(
                    label: l10n.get('account_link_google'),
                    icon: Icons.add_link,
                    isLoading: _isGoogleLoading,
                    onPressed: () async {
                      setState(() => _isGoogleLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await ref
                          .read(authServiceProvider)
                          .linkWithGoogle();
                      if (mounted) setState(() => _isGoogleLoading = false);
                      result.fold(
                        (failure) {
                          _showError(context, l10n, failure.message, messenger);
                        },
                        (_) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Google account linked!'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              if (!isGitHub)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: _AuthButton(
                    label: l10n.get('account_link_github'),
                    icon: Icons.code,
                    isLoading: _isGithubLoading,
                    onPressed: () async {
                      setState(() => _isGithubLoading = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final result = await ref
                          .read(authServiceProvider)
                          .linkWithGithub();
                      if (mounted) setState(() => _isGithubLoading = false);
                      result.fold(
                        (failure) {
                          _showError(context, l10n, failure.message, messenger);
                        },
                        (credential) {
                          final oauthCred =
                              credential.credential as OAuthCredential?;
                          if (oauthCred != null &&
                              oauthCred.accessToken != null) {
                            final gistService = ref.read(
                              gistSyncServiceProvider,
                            );
                            gistService.setAccessToken(oauthCred.accessToken!);
                            _checkAndPromptRestore(context, gistService);
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('GitHub account linked!'),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              const Divider(),
            ],
          ],
          const Divider(),
          _SectionLabel(label: l10n.get('help_title')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.get('account_privacy_info'),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.get('account_privacy_link')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile/docs'),
          ),
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

  Future<void> _checkAndPromptRestore(
    BuildContext context,
    GistSyncService gistService,
  ) async {
    final timestamp = await gistService.getBackupTimestamp();
    if (timestamp != null && context.mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Found'),
          content: Text(
            'A backup from ${timestamp.toLocal().toString().split('.')[0]} was found on GitHub. Would you like to restore it now?\n\nThis will merge the cloud data with your local data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore Now'),
            ),
          ],
        ),
      );

      if (confirm == true && context.mounted) {
        await _restoreFromGist(context);
      }
    }
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('error')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.getWith('account_sign_in_error', [message])),
            const SizedBox(height: 16),
            const Text(
              'Please check the browser console for more details.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
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

class _AuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(minimumSize: const Size(280, 52)),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
