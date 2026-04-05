import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'tv_destinations.dart';
import '../shell/tv_shell.dart';
import '../feature/home/home_screen.dart';
import '../feature/discover/discover_screen.dart';
import '../feature/discover/group_detail/group_detail_screen.dart';
import '../feature/browse/browse_screen.dart';
import '../feature/favourites/favourites_screen.dart';
import '../feature/settings/settings_screen.dart';
import '../feature/player/player_screen.dart';

final tvRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: TvRoutes.home,
    routes: [
      // Player is a fullscreen overlay outside the shell
      GoRoute(
        path: TvRoutes.player,
        builder: (context, state) => const PlayerScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TvShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TvRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TvRoutes.discover,
                builder: (context, state) => const DiscoverScreen(),
                routes: [
                  GoRoute(
                    path: 'group/:groupId',
                    builder: (context, state) {
                      final groupId =
                          int.parse(state.pathParameters['groupId']!);
                      return GroupDetailScreen(groupId: groupId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TvRoutes.browse,
                builder: (context, state) => const BrowseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TvRoutes.favourites,
                builder: (context, state) => const FavouritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: TvRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
