import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/scaffold_with_nav_bar.dart';

import '../../features/players/presentation/players_screen.dart';
import '../../features/games/presentation/games_list_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/games/wizard/presentation/wizard_screen.dart';
import '../../features/games/qwixx/presentation/qwixx_screen.dart';
import '../../features/games/schafkopf/presentation/schafkopf_screen.dart';
import '../../features/games/kniffel/presentation/kniffel_screen.dart';
import '../../features/games/sipdeck/presentation/sipdeck_screen.dart';
import '../../features/games/extras/presentation/phase10_screen.dart';
import '../../features/games/extras/presentation/darts_screen.dart';
import '../../features/games/extras/presentation/romme_screen.dart';
import '../../features/games/buzztap/presentation/buzztap_screen.dart';
import '../../features/games/wayquest/presentation/wayquest_screen.dart';
import '../../features/games/wizard/presentation/wizard_extreme_screen.dart';
import '../../features/leaderboards/presentation/leaderboard_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/help/presentation/help_screen.dart';
import '../../features/games/extras/presentation/generic_score_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/games/presentation/game_setup_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/games',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/players',
                builder: (context, state) => const PlayersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/games',
                builder: (context, state) => const GamesListScreen(),
                routes: [
                  GoRoute(
                    path: 'setup/:gameId',
                    builder: (context, state) {
                      final gameId = state.pathParameters['gameId']!;
                      return GameSetupScreen(gameId: gameId);
                    },
                  ),
                  GoRoute(
                    path: 'wizard',
                    builder: (context, state) => const WizardScreen(),
                  ),
                  GoRoute(
                    path: 'qwixx',
                    builder: (context, state) => const QwixxScreen(),
                  ),
                  GoRoute(
                    path: 'schafkopf',
                    builder: (context, state) => const SchafkopfScreen(),
                  ),
                  GoRoute(
                    path: 'kniffel',
                    builder: (context, state) => const KniffelScreen(),
                  ),
                  GoRoute(
                    path: 'sipdeck',
                    builder: (context, state) => const SipDeckScreen(),
                  ),
                  GoRoute(
                    path: 'phase10',
                    builder: (context, state) => const Phase10Screen(),
                  ),
                  GoRoute(
                    path: 'darts',
                    builder: (context, state) => const DartsScreen(),
                  ),
                  GoRoute(
                    path: 'romme',
                    builder: (context, state) => const RommeScreen(),
                  ),
                  GoRoute(
                    path: 'buzztap',
                    builder: (context, state) => const BuzzTapScreen(),
                  ),
                  GoRoute(
                    path: 'wayquest',
                    builder: (context, state) => const WayQuestScreen(),
                  ),
                  GoRoute(
                    path: 'wizard_extreme',
                    builder: (context, state) => const WizardExtremeScreen(),
                  ),
                  GoRoute(
                    path: 'generic',
                    builder: (context, state) => const GenericScoreScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/help',
                builder: (context, state) => const HelpScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
