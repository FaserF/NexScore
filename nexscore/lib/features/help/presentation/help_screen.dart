import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/app_version.dart';

/// In-app Help screen.
/// Links to GitHub Pages docs, bug report, and feature request.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String _docsUrl = 'https://faserf.github.io/NexScore/docs/';
  static const String _bugUrl =
      'https://github.com/FaserF/NexScore/issues/new?template=bug_report.yml';
  static const String _featureUrl =
      'https://github.com/FaserF/NexScore/issues/new?template=feature_request.yml';
  static const String _discussUrl =
      'https://github.com/FaserF/NexScore/discussions';
  static const String _repoUrl = 'https://github.com/FaserF/NexScore';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l10n.get('help_title'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            centerTitle: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/profile/settings'),
                tooltip: l10n.get('settings'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionHeader(
                  icon: Icons.menu_book_outlined,
                  title: l10n.get('help_docs'),
                ),
                _HelpTile(
                  icon: Icons.open_in_browser,
                  title: l10n.get('help_docs'),
                  subtitle: l10n.get('help_docs_desc'),
                  url: _docsUrl,
                ),
                const SizedBox(height: 8),
                _HelpTile(
                  icon: Icons.settings_outlined,
                  title: l10n.get('help_settings'),
                  subtitle: l10n.get('settings'),
                  onTap: () => context.push('/profile/settings'),
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  icon: Icons.feedback_outlined,
                  title: 'Feedback',
                ),
                _HelpTile(
                  icon: Icons.bug_report_outlined,
                  iconColor: Colors.red.shade700,
                  title: l10n.get('help_bug'),
                  subtitle: l10n.get('help_bug_desc'),
                  url: _bugUrl,
                ),
                _HelpTile(
                  icon: Icons.lightbulb_outline,
                  iconColor: Colors.amber.shade700,
                  title: l10n.get('help_feature'),
                  subtitle: l10n.get('help_feature_desc'),
                  url: _featureUrl,
                ),
                _HelpTile(
                  icon: Icons.forum_outlined,
                  iconColor: Colors.blue.shade700,
                  title: l10n.get('help_discuss'),
                  subtitle: l10n.get('help_discuss_desc'),
                  url: _discussUrl,
                ),
                const SizedBox(height: 16),
                _SectionHeader(
                  icon: Icons.info_outline,
                  title: l10n.get('help_title'),
                ),
                _HelpTile(
                  icon: Icons.code,
                  title: l10n.get('help_source'),
                  subtitle: l10n.get('help_source_desc'),
                  url: _repoUrl,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'NexScore ${AppVersion.displayVersion}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '© 2026 Fabian Seitz (FaserF) · MIT License',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? url;
  final VoidCallback? onTap;

  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.url,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: onTap ?? () => _launchUrl(context, url!),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open: $url')));
      }
    }
  }
}
