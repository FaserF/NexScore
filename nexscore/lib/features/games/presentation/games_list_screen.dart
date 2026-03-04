import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';

/// The main game selection screen shown at app start.
/// Displays all supported games as rich cards with name, icon, and description.
class GamesListScreen extends StatelessWidget {
  const GamesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final games = _gameEntries(context, l10n);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('NexScore'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.go('/settings'),
                tooltip: l10n.get('settings'),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () => context.go('/help'),
                tooltip: l10n.get('help_title'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                    child: Text(
                      l10n.get('home_choose_game'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                final game = games[index - 1];
                return _GameCard(entry: game);
              }, childCount: games.length + 1),
            ),
          ),
        ],
      ),
    );
  }

  List<_GameEntry> _gameEntries(BuildContext ctx, AppLocalizations l10n) {
    final cs = Theme.of(ctx).colorScheme;
    return [
      _GameEntry(
        name: l10n.get('game_wizard'),
        description: l10n.get('desc_wizard'),
        route: '/games/setup/wizard',
        icon: Icons.auto_awesome,
        color: cs.primary,
        playerCount: '2–6',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        name: l10n.get('game_qwixx'),
        description: l10n.get('desc_qwixx'),
        route: '/games/setup/qwixx',
        icon: Icons.casino,
        color: Colors.orange.shade700,
        playerCount: '2–5',
        tag: l10n.get('home_tag_dice'),
      ),
      _GameEntry(
        name: l10n.get('game_schafkopf'),
        description: l10n.get('desc_schafkopf'),
        route: '/games/setup/schafkopf',
        icon: Icons.style,
        color: Colors.green.shade700,
        playerCount: '4',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        name: l10n.get('game_kniffel'),
        description: l10n.get('desc_kniffel'),
        route: '/games/setup/kniffel',
        icon: Icons.grid_on,
        color: Colors.purple.shade700,
        playerCount: '2–8',
        tag: l10n.get('home_tag_dice'),
      ),
      _GameEntry(
        name: l10n.get('game_phase10'),
        description: l10n.get('desc_phase10'),
        route: '/games/setup/phase10',
        icon: Icons.looks_one,
        color: Colors.teal.shade700,
        playerCount: '2–6',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        name: l10n.get('game_darts'),
        description: l10n.get('desc_darts'),
        route: '/games/setup/darts',
        icon: Icons.crisis_alert,
        color: Colors.red.shade700,
        playerCount: '2–8',
        tag: l10n.get('home_tag_sport'),
      ),
      _GameEntry(
        name: l10n.get('game_romme'),
        description: l10n.get('desc_romme'),
        route: '/games/setup/romme',
        icon: Icons.layers,
        color: Colors.indigo.shade700,
        playerCount: '2–6',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        name: l10n.get('game_arschloch'),
        description: l10n.get('desc_arschloch'),
        route: '/games/setup/arschloch',
        icon: Icons.military_tech,
        color: Colors.brown.shade700,
        playerCount: '3–8',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        name: l10n.get('game_sipdeck'),
        description: l10n.get('desc_sipdeck'),
        route: '/games/setup/sipdeck',
        icon: Icons.local_bar,
        color: Colors.pink.shade700,
        playerCount: '3+',
        tag: l10n.get('home_tag_party'),
        isAdult: true,
      ),
    ];
  }
}

class _GameEntry {
  final String name;
  final String description;
  final String route;
  final IconData icon;
  final Color color;
  final String playerCount;
  final String tag;
  final bool isAdult;

  const _GameEntry({
    required this.name,
    required this.description,
    required this.route,
    required this.icon,
    required this.color,
    required this.playerCount,
    required this.tag,
    this.isAdult = false,
  });
}

class _GameCard extends StatelessWidget {
  final _GameEntry entry;

  const _GameCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(entry.route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: entry.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(entry.icon, color: entry.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (entry.isAdult)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '18+',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Chip(label: entry.tag, color: entry.color),
                          const SizedBox(width: 6),
                          _Chip(
                            label: '👥 ${entry.playerCount}',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
