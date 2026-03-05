import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Players',
              ),
              NavigationDestination(
                icon: Icon(Icons.videogame_asset_outlined),
                selectedIcon: Icon(Icons.videogame_asset),
                label: 'Games',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined),
                selectedIcon: Icon(Icons.emoji_events),
                label: 'Leaderboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle),
                label: 'Account',
              ),
              NavigationDestination(
                icon: Icon(Icons.help_outline),
                selectedIcon: Icon(Icons.help),
                label: 'Help',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
