import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/persistence_provider.dart';
import '../../../../core/providers/active_players_provider.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/widgets/glass_container.dart';
import '../../../players/repository/player_repository.dart';

class ResumeBanner extends ConsumerWidget {
  const ResumeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastGameIdAsync = ref.watch(persistenceNotifierProvider);
    final l10n = AppLocalizations.of(context);

    return lastGameIdAsync.when(
      data: (gameId) {
        if (gameId == null) return const SizedBox.shrink();

        // Get game name
        final gameName = l10n.get('game_$gameId');

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('resume_game_title'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.getWith('resume_game_desc', [gameName]),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(persistenceNotifierProvider.notifier)
                      .clearLastGame(),
                  child: Text(l10n.get('discard')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _resumeGame(context, ref, gameId),
                  child: Text(l10n.get('resume')),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Future<void> _resumeGame(BuildContext context, WidgetRef ref, String gameId) async {
    // Restore active players from saved IDs
    final service = ref.read(persistenceServiceProvider);
    final savedPlayerIds = await service.loadActivePlayerIds();

    if (savedPlayerIds.isNotEmpty) {
      final playersAsync = ref.read(playersProvider);
      final allPlayers = playersAsync.value ?? [];
      final activePlayers = allPlayers
          .where((p) => savedPlayerIds.contains(p.id))
          .toList();
      ref.read(activePlayersProvider.notifier).setPlayers(activePlayers);
    }

    // Set the active game ID
    ref.read(activeGameIdProvider.notifier).state = gameId;

    if (!context.mounted) return;

    // Navigate to the game screen
    if (gameId == 'wizard_digital') {
      context.push('/games/wizard-digital');
    } else if (gameId == 'kniffel_digital') {
      context.push('/games/kniffel-digital');
    } else if (gameId == 'arschloch_digital') {
      context.push('/games/arschloch-digital');
    } else if (gameId == 'qwixx_digital') {
      context.push('/games/qwixx-digital');
    } else if (gameId == 'romme_digital') {
      context.push('/games/romme-digital');
    } else if (gameId == 'phase10_digital') {
      context.push('/games/phase10-digital');
    } else if (gameId == 'sipdeck') {
      context.push('/games/sipdeck');
    } else if (gameId == 'buzztap') {
      context.push('/games/buzztap');
    } else if (gameId == 'wayquest') {
      context.push('/games/wayquest');
    } else if (gameId == 'volleyball') {
      context.push('/games/volleyball');
    }
  }
}
