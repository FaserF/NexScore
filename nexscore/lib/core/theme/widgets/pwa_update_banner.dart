import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../i18n/app_localizations.dart';
import '../pwa/pwa_update_service.dart';

class PwaUpdateBanner extends ConsumerWidget {
  const PwaUpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateAvailable = ref.watch(pwaUpdateProvider);
    if (!updateAvailable) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Material(
      color: Theme.of(context).colorScheme.primaryContainer,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.system_update, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.get('pwa_update_available'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(pwaUpdateProvider.notifier).reloadApp(),
                child: Text(
                  l10n.get('refresh'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
