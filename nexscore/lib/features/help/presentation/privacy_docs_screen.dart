import 'package:flutter/material.dart';
import '../../../core/i18n/app_localizations.dart';

class PrivacyDocsScreen extends StatelessWidget {
  const PrivacyDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              l10n.get('privacy_title'),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            centerTitle: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _PrivacySection(
                  title: l10n.get('privacy_no_server_title'),
                  body: l10n.get('privacy_no_server_body'),
                  icon: Icons.security_outlined,
                ),
                const Divider(height: 48),
                _PrivacySection(
                  title: l10n.get('privacy_google_title'),
                  body: l10n.get('privacy_google_body'),
                  icon: Icons.cloud_sync_outlined,
                ),
                const Divider(height: 48),
                _PrivacySection(
                  title: l10n.get('privacy_github_title'),
                  body: l10n.get('privacy_github_body'),
                  icon: Icons.backup_outlined,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;

  const _PrivacySection({
    required this.title,
    required this.body,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
