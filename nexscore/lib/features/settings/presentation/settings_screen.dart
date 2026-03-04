import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/storage/database_service.dart';
import '../../history/repository/session_repository.dart';
import '../../players/repository/player_repository.dart';
import '../provider/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader(title: l10n.get('settings_theme')),
          ListTile(
            leading: const Icon(Icons.brightness_medium),
            title: Text(l10n.get('settings_theme')),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
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
          const Divider(),
          _SectionHeader(title: l10n.get('settings_language')),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.get('settings_language')),
            trailing: DropdownButton<String?>(
              value: settings.locale?.languageCode,
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
          const Divider(),
          _SectionHeader(title: l10n.get('settings_data')),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              l10n.get('settings_db_reset'),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _confirmReset(context, ref, l10n),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
