import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/storage/database_service.dart';
import '../../history/repository/session_repository.dart';
import '../../players/repository/player_repository.dart';
import '../provider/settings_provider.dart';
import '../../../core/theme/widgets/glass_container.dart';
import '../../../core/theme/widgets/animated_scale_button.dart';
import '../../../core/utils/app_version.dart';

import '../../../core/pwa/pwa_prompt.dart' as pwa;
import '../../../core/pwa/pwa_install_dialog.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/sync/local_backup_service.dart';
import '../../../core/services/updater_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for the install prompt being ready to refresh the UI
    pwa.onInstallPromptReady = () {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    };
  }

  @override
  void dispose() {
    pwa.onInstallPromptReady = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final showPwaInstall = kIsWeb && !pwa.isStandalone();
    final authUser = ref.watch(authUserProvider).asData?.value;

    // Auto-sync host name from account if it's still the default
    if (authUser != null &&
        !authUser.isAnonymous &&
        authUser.displayName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(settingsProvider.notifier)
            .updateHostNameIfDefault(authUser.displayName!);
      });
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l10n.get('settings'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            leading: AnimatedScaleButton(
              onPressed: () => context.pop(),
              child: const Icon(Icons.arrow_back_ios_new),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.tune),
                    title: Text(
                      l10n.get('settings_section_general'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.brightness_medium),
                        title: Text(l10n.get('settings_theme')),
                        trailing: DropdownButton<ThemeMode>(
                          value: settings.themeMode,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          borderRadius: BorderRadius.circular(16),
                          onChanged: (mode) {
                            if (mode != null) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setThemeMode(mode);
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text(l10n.get('settings_theme_system')),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text(l10n.get('settings_theme_light')),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text(l10n.get('settings_theme_dark')),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.language),
                        title: Text(l10n.get('settings_language')),
                        trailing: DropdownButton<String?>(
                          value: settings.locale?.languageCode,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.keyboard_arrow_down),
                          borderRadius: BorderRadius.circular(16),
                          onChanged: (code) {
                            final locale = code != null ? Locale(code) : null;
                            ref.read(settingsProvider.notifier).setLocale(locale);
                          },
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l10n.get('settings_theme_system')),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text(l10n.get('settings_language_en')),
                            ),
                            DropdownMenuItem(
                              value: 'de',
                              child: Text(l10n.get('settings_language_de')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    leading: const Icon(Icons.volume_up),
                    title: Text(
                      l10n.get('settings_section_audio_profile'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      SwitchListTile(
                        title: Text(l10n.get('settings_sfx')),
                        subtitle: Text(
                          l10n.get('settings_sfx_desc'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: settings.sfxEnabled,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).setSfxEnabled(val);
                        },
                      ),
                      if (settings.sfxEnabled) ...[
                        _SubSettingSwitch(
                          title: l10n.get('settings_sfx_beep'),
                          value: settings.sfxBeepEnabled,
                          onChanged: (val) => ref
                              .read(settingsProvider.notifier)
                              .setSfxBeepEnabled(val),
                        ),
                        _SubSettingSwitch(
                          title: l10n.get('settings_sfx_fanfare'),
                          value: settings.sfxFanfareEnabled,
                          onChanged: (val) => ref
                              .read(settingsProvider.notifier)
                              .setSfxFanfareEnabled(val),
                        ),
                        _SubSettingSwitch(
                          title: l10n.get('settings_sfx_other'),
                          value: settings.sfxOtherEnabled,
                          onChanged: (val) => ref
                              .read(settingsProvider.notifier)
                              .setSfxOtherEnabled(val),
                        ),
                      ],
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.get('settings_host_profile'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: TextEditingController(
                                text: settings.hostName,
                              ),
                              onChanged: (val) => ref
                                  .read(settingsProvider.notifier)
                                  .setHostName(val),
                              decoration: InputDecoration(
                                labelText: l10n.get('settings_host_name'),
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  l10n.get('settings_host_color'),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                ...[
                                  '#4287f5',
                                  '#f54242',
                                  '#42f560',
                                  '#f5d142',
                                  '#a142f5',
                                ].map((colorStr) {
                                  final color = Color(
                                    int.parse(colorStr.replaceFirst('#', '0xff')),
                                  );
                                  final isSelected = settings.hostColor == colorStr;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: GestureDetector(
                                      onTap: () => ref
                                          .read(settingsProvider.notifier)
                                          .setHostColor(colorStr),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/multiplayer'),
                              icon: const Icon(Icons.wifi_tethering),
                              label: Text(l10n.get('multiplayer_hub')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    leading: const Icon(Icons.settings_applications),
                    title: Text(
                      l10n.get('settings_section_advanced'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      if (showPwaInstall) ...[
                        ListTile(
                          leading: const Icon(Icons.install_mobile),
                          title: Text(l10n.get('settings_pwa_install')),
                          subtitle: Text(
                            l10n.get('settings_pwa_install_desc'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () async {
                            final handled = await pwa.showInstallPrompt();
                            if (context.mounted) {
                              if (!handled) {
                                PWAInstallDialog.show(context);
                              } else {
                                setState(() {});
                              }
                            }
                          },
                        ),
                        const Divider(height: 1),
                      ],
                      ListTile(
                        leading: const Icon(Icons.upload_file),
                        title: Text(l10n.get('backup_local_export')),
                        subtitle: settings.lastBackupTime != null &&
                                settings.lastBackupProvider == 'local'
                            ? Text(
                                '${l10n.get('last_backup')}: ${settings.lastBackupTime!.day}.${settings.lastBackupTime!.month}.${settings.lastBackupTime!.year}',
                                style: const TextStyle(fontSize: 11),
                              )
                            : null,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref
                                .read(localBackupServiceProvider)
                                .exportBackup();
                            if (context.mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.get('backup_local_export_success'),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.getWith('backup_local_import_error', [
                                      e.toString(),
                                    ]),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.download_for_offline),
                        title: Text(l10n.get('backup_local_import')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final success = await ref
                                .read(localBackupServiceProvider)
                                .importBackup();
                            if (success && context.mounted) {
                              ref.invalidate(playersProvider);
                              ref.invalidate(sessionsProvider);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.get('backup_local_import_success'),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.getWith('backup_local_import_error', [
                                      e.toString(),
                                    ]),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(l10n.get('settings_debug_mode')),
                        subtitle: Text(
                          l10n.get('settings_debug_mode_desc'),
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: settings.debugMode,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).setDebugMode(val);
                        },
                      ),
                      const Divider(height: 1),
                      FutureBuilder<bool>(
                        future: BuiltInUpdaterService.isSideloaded(),
                        builder: (context, snapshot) {
                          final showUpdateSettings = (snapshot.data == true) || kIsWeb;
                          if (!showUpdateSettings) return const SizedBox.shrink();
                          return Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.update),
                                title: const Text('Update Channel'),
                                subtitle: Text('Current: ${settings.updateChannel}'),
                                trailing: DropdownButton<String>(
                                  value: settings.updateChannel,
                                  underline: const SizedBox(),
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  borderRadius: BorderRadius.circular(16),
                                  onChanged: (channel) {
                                    if (channel != null) {
                                      ref
                                          .read(settingsProvider.notifier)
                                          .setUpdateChannel(channel);
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'stable',
                                      child: Text('Stable'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'beta',
                                      child: Text('Beta'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'dev',
                                      child: Text('Developer (Dev)'),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.system_update_alt),
                                title: const Text('Check for Updates'),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () => _checkForUpdates(context, settings.updateChannel),
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.ios_share),
                        title: Text(l10n.get('settings_export_logs')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await AppLogger.exportLogs();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever, color: Colors.red),
                        title: Text(
                          l10n.get('settings_db_reset'),
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                        onTap: () => _confirmReset(context, ref, l10n),
                      ),
                    ],
                  ),
                ),
                if (authUser != null) ...[
                  const SizedBox(height: 24),
                  AnimatedScaleButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await ref.read(authServiceProvider).signOut();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(l10n.get('account_sign_out')),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    child: GlassContainer(
                      borderRadius: 24,
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.05),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.logout,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        title: Text(
                          l10n.get('account_sign_out'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'NexScore ${AppVersion.displayVersion}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.outline,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (AppVersion.isPreRelease)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'BETA',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context, String channel) async {
    final messenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    GitHubRelease? release;
    try {
      release = await BuiltInUpdaterService.checkForUpdates(channel);
    } finally {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading indicator
      }
    }

    if (release == null) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Up to Date'),
            content: const Text('You are already running the latest version of NexScore for this channel.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('New Version Available: ${release!.tagName}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(kIsWeb
                    ? 'A new version of NexScore has been released on GitHub.'
                    : 'A new version of NexScore is available for download.'),
                const SizedBox(height: 12),
                const Text(
                  'Changelog:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(release!.body),
              ],
            ),
          ),
          actions: kIsWeb
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await BuiltInUpdaterService.performUpdate(release!);
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to trigger update: $e')),
                        );
                      }
                    },
                    child: const Text('Update Now'),
                  ),
                ],
        ),
      );
    }
  }

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('settings_db_reset')),
        content: Text(l10n.get('settings_db_reset_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.get('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.get('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.clearDatabase();
      // Invalidate providers to refresh UI
      ref.invalidate(playersProvider);
      ref.invalidate(sessionsProvider);

      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.get('settings_db_reset_success'))),
        );
      }
    }
  }
}


class _SubSettingSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SubSettingSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }
}
