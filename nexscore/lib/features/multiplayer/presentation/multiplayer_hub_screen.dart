import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/firebase/firebase_options_web.dart';

class MultiplayerHubScreen extends ConsumerWidget {
  const MultiplayerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('multiplayer_hub')),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => _showDiagnostics(context, ref, l10n),
            tooltip: l10n.get('multiplayer_diagnostics'),
          ),
        ],
      ),

      body: Column(
        children: [
          if (kIsWeb && !FirebaseOptionsWeb.isConfigured)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.get('multiplayer_firebase_missing_desc'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.wifi_tethering,
                      size: 100,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () => context.push('/multiplayer/host'),
                      icon: const Icon(Icons.add_box),
                      label: Text(l10n.get('multiplayer_host')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      onPressed: () => context.push('/multiplayer/join'),
                      icon: const Icon(Icons.login),
                      label: Text(l10n.get('multiplayer_join')),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(20),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDiagnostics(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.get('multiplayer_diagnostics')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.get('multiplayer_diagnostics_desc'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security, color: Colors.orange),
              title: Text(l10n.get('multiplayer_auth_title')),
              subtitle: Text(l10n.get('multiplayer_auth_desc')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text(l10n.get('multiplayer_adblock_title')),
              subtitle: Text(l10n.get('multiplayer_adblock_desc')),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.domain, color: Colors.blue),
              title: Text(l10n.get('multiplayer_domains_title')),
              subtitle: Text(l10n.get('multiplayer_domains_desc')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('close')),
          ),
        ],
      ),
    );
  }
}
