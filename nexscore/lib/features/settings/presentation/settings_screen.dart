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
      if (mounted) setState(() {});
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
    final canInstall = pwa.canShowInstallPrompt();

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
                _SectionHeader(title: l10n.get('settings_theme')),
                GlassContainer(
                  borderRadius: 24,
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
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.brightness_medium,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      l10n.get('settings_theme'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: l10n.get('settings_language')),
                GlassContainer(
                  borderRadius: 24,
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
                        ).colorScheme.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.language,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    title: Text(
                      l10n.get('settings_language'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                ),
                const SizedBox(height: 24),
                if (canInstall) ...[
                  _SectionHeader(title: l10n.get('settings_pwa_install')),
                  AnimatedScaleButton(
                    onPressed: () async {
                      final accepted = await pwa.showInstallPrompt();
                      if (accepted && mounted) {
                        setState(() {});
                      }
                    },
                    child: GlassContainer(
                      borderRadius: 24,
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
                            ).colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.install_mobile,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        title: Text(
                          l10n.get('settings_pwa_install'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          l10n.get('settings_pwa_install_desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                _SectionHeader(title: l10n.get('settings_data')),
                AnimatedScaleButton(
                  onPressed: () => _confirmReset(context, ref, l10n),
                  child: GlassContainer(
                    borderRadius: 24,
                    color: Colors.red.withValues(alpha: 0.05),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                      ),
                      title: Text(
                        l10n.get('settings_db_reset'),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionHeader(title: 'Multiplayer Host Profile'),
                GlassContainer(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextField(
                        controller: TextEditingController(
                          text: settings.hostName,
                        ),
                        onChanged: (val) => ref
                            .read(settingsProvider.notifier)
                            .setHostName(val),
                        decoration: InputDecoration(
                          labelText: 'Host Name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Host Color',
                            style: TextStyle(fontWeight: FontWeight.w600),
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
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
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
                    ],
                  ),
                ),

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

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('settings_db_reset_success'))),
        );
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
