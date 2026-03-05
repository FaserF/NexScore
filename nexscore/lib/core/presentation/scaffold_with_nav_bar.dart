import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../i18n/app_localizations.dart';
import '../theme/widgets/glass_container.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // critical for the floating effect
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
        child: GlassContainer(
          borderRadius: 30.0,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (int index) {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: AppLocalizations.of(context).get('nav_players'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.videogame_asset_outlined),
                selectedIcon: const Icon(Icons.videogame_asset),
                label: AppLocalizations.of(context).get('nav_games'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: AppLocalizations.of(context).get('nav_history'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.emoji_events_outlined),
                selectedIcon: const Icon(Icons.emoji_events),
                label: AppLocalizations.of(context).get('nav_leaderboard'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.account_circle_outlined),
                selectedIcon: const Icon(Icons.account_circle),
                label: AppLocalizations.of(context).get('nav_account'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.help_outline),
                selectedIcon: const Icon(Icons.help),
                label: AppLocalizations.of(context).get('nav_help'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
