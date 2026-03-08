import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/favorites_provider.dart';
import '../../../core/theme/widgets/animated_scale_button.dart';
import '../../../core/theme/widgets/glass_container.dart';
import '../../../core/utils/app_version.dart';
import '../../../core/pwa/pwa_prompt.dart' as pwa;
import '../../../core/theme/widgets/pwa_update_banner.dart';
import 'widgets/resume_banner.dart';

/// The main game selection screen shown at app start.
/// Displays all supported games as rich cards with name, icon, and description.
class GamesListScreen extends ConsumerStatefulWidget {
  const GamesListScreen({super.key});

  @override
  ConsumerState<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends ConsumerState<GamesListScreen> {
  String _searchQuery = '';
  String? _selectedTag;

  @override
  void initState() {
    super.initState();
    _initPwaListeners();
  }

  void _initPwaListeners() {
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
    final ref = this.ref;
    final l10n = AppLocalizations.of(context);
    final allGames = _gameEntries(context, l10n);
    final favorites = ref.watch(favoritesProvider);

    // Sort alphabetically
    allGames.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    // Apply Filters
    final filteredGames = allGames.where((g) {
      final matchesSearch =
          g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          g.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesTag = _selectedTag == null || g.tag == _selectedTag;
      return matchesSearch && matchesTag;
    }).toList();

    // Split games into favorites and others
    final favGames = filteredGames
        .where((g) => favorites.contains(g.id))
        .toList();
    final otherGames = filteredGames
        .where((g) => !favorites.contains(g.id))
        .toList();

    // Combine them with favorites first
    final games = [...favGames, ...otherGames];

    // Extract all unique tags for the filter chips
    final availableTags = allGames.map((g) => g.tag).toSet().toList()..sort();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NexScore',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                if (AppVersion.isPreRelease) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'BETA',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            centerTitle: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AnimatedScaleButton(
                  onPressed: () => context.go('/multiplayer'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.hub_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AnimatedScaleButton(
                  onPressed: () => context.go('/profile/settings'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: AnimatedScaleButton(
                  onPressed: () => context.go('/help'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: ResumeBanner()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('home_choose_game'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: l10n.get('home_search_games'),
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(l10n.get('home_filter_all')),
                                  selected: _selectedTag == null,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedTag = null);
                                    }
                                  },
                                ),
                              ),
                              ...availableTags.map((tag) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    label: Text(tag),
                                    selected: _selectedTag == tag,
                                    onSelected: (selected) {
                                      setState(
                                        () => _selectedTag = selected
                                            ? tag
                                            : null,
                                      );
                                    },
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                }
                final game = games[index - 1];
                final isFavorite = favorites.contains(game.id);

                return _GameCard(
                  entry: game,
                  isFavorite: isFavorite,
                  onToggleFavorite: () {
                    ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(game.id);
                  },
                );
              }, childCount: games.length + 1),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const PwaUpdateBanner(),
    );
  }

  List<_GameEntry> _gameEntries(BuildContext ctx, AppLocalizations l10n) {
    final cs = Theme.of(ctx).colorScheme;
    return [
      _GameEntry(
        id: 'wizard',
        name: l10n.get('game_wizard'),
        description: l10n.get('desc_wizard'),
        route: '/games/setup/wizard',
        icon: Icons.auto_awesome,
        color: cs.primary,
        playerCount: '2–6',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        id: 'qwixx',
        name: l10n.get('game_qwixx'),
        description: l10n.get('desc_qwixx'),
        route: '/games/setup/qwixx',
        icon: Icons.casino,
        color: Colors.orange.shade700,
        playerCount: '2–5',
        tag: l10n.get('home_tag_dice'),
      ),
      _GameEntry(
        id: 'schafkopf',
        name: l10n.get('game_schafkopf'),
        description: l10n.get('desc_schafkopf'),
        route: '/games/setup/schafkopf',
        icon: Icons.style,
        color: Colors.green.shade700,
        playerCount: '4',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        id: 'kniffel',
        name: l10n.get('game_kniffel'),
        description: l10n.get('desc_kniffel'),
        route: '/games/setup/kniffel',
        icon: Icons.grid_on,
        color: Colors.purple.shade700,
        playerCount: '2–8',
        tag: l10n.get('home_tag_dice'),
      ),
      _GameEntry(
        id: 'phase10',
        name: l10n.get('game_phase10'),
        description: l10n.get('desc_phase10'),
        route: '/games/setup/phase10',
        icon: Icons.looks_one,
        color: Colors.teal.shade700,
        playerCount: '2–6',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        id: 'darts',
        name: l10n.get('game_darts'),
        description: l10n.get('desc_darts'),
        route: '/games/setup/darts',
        icon: Icons.crisis_alert,
        color: Colors.red.shade700,
        playerCount: '2–8',
        tag: l10n.get('home_tag_sport'),
      ),
      _GameEntry(
        id: 'romme',
        name: l10n.get('game_romme'),
        description: l10n.get('desc_romme'),
        route: '/games/setup/romme',
        icon: Icons.layers,
        color: Colors.indigo.shade700,
        playerCount: '2–6',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        id: 'arschloch',
        name: l10n.get('game_arschloch'),
        description: l10n.get('desc_arschloch'),
        route: '/games/setup/arschloch',
        icon: Icons.military_tech,
        color: Colors.brown.shade700,
        playerCount: '3–8',
        tag: l10n.get('home_tag_card'),
      ),
      _GameEntry(
        id: 'sipdeck',
        name: l10n.get('game_sipdeck'),
        description: l10n.get('desc_sipdeck'),
        route: '/games/setup/sipdeck',
        icon: Icons.local_bar,
        color: Colors.pink.shade700,
        playerCount: '2+',
        tag: l10n.get('home_tag_party'),
        isAdult: true,
      ),
      _GameEntry(
        id: 'buzztap',
        name: l10n.get('game_buzztap'),
        description: l10n.get('desc_buzztap'),
        route: '/games/setup/buzztap',
        icon: Icons.touch_app,
        color: Colors.amber.shade700,
        playerCount: '2+',
        tag: l10n.get('home_tag_party'),
        isAdult: true,
      ),
      _GameEntry(
        id: 'wayquest',
        name: l10n.get('game_wayquest'),
        description: l10n.get('desc_wayquest'),
        route: '/games/wayquest',
        icon: Icons.directions_car,
        color: Colors.blueAccent.shade700,
        playerCount: '2+',
        tag: l10n.get('home_tag_ext'),
      ),
      _GameEntry(
        id: 'generic',
        name: l10n.get('game_generic'),
        description: l10n.get('desc_generic'),
        route: '/games/generic',
        icon: Icons.calculate,
        color: Colors.blueGrey,
        playerCount: '1+',
        tag: l10n.get('home_tag_ext'),
      ),
    ];
  }
}

class _GameEntry {
  final String id;
  final String name;
  final String description;
  final String route;
  final IconData icon;
  final Color color;
  final String playerCount;
  final String tag;
  final bool isAdult;

  const _GameEntry({
    required this.id,
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
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _GameCard({
    required this.entry,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AnimatedScaleButton(
        onPressed: () => context.go(entry.route),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [entry.color.withValues(alpha: 0.8), entry.color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: entry.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(entry.icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (entry.isAdult) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              '18+',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _Chip(label: entry.tag, color: entry.color),
                        const SizedBox(width: 8),
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
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        color: isFavorite
                            ? Colors.amber
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      onPressed: onToggleFavorite,
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ],
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
