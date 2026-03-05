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
      extendBody:
          false, // Prevents content from being obscured by the bottom nav bar
      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: MediaQuery.of(context).size.width > 600 ? 24.0 : 8.0,
          right: MediaQuery.of(context).size.width > 600 ? 24.0 : 8.0,
          bottom: MediaQuery.of(context).size.width > 600 ? 24.0 : 12.0,
        ),
        child: GlassContainer(
          borderRadius: 30.0,
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                return TextStyle(
                  fontSize: MediaQuery.of(context).size.width > 400 ? 12 : 11,
                  fontWeight: states.contains(WidgetState.selected)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  overflow: TextOverflow.ellipsis,
                );
              }),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: Theme.of(context).colorScheme.primaryContainer,
              selectedIndex: navigationShell.currentIndex,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
      ),
    );
  }
}
