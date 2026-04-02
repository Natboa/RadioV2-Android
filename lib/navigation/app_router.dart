import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_destinations.dart';
import '../core/designsystem/colors.dart';
import '../feature/browse/browse_screen.dart';
import '../feature/player/mini_player.dart';
import '../feature/player/player_notifier.dart';
import '../feature/player/player_state.dart';
import '../feature/discover/discover_screen.dart';
import '../feature/discover/group_detail/group_detail_screen.dart';
import '../feature/favourites/favourites_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.favourites,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.browse,
                builder: (context, state) => const BrowseScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.discover,
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
                path: AppRoutes.favourites,
                builder: (context, state) => const FavouritesScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class AppScaffold extends ConsumerWidget {
  final StatefulNavigationShell shell;

  const AppScaffold({super.key, required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<PlayerUiState>(playerNotifierProvider, (prev, next) {
      if (next.isError && !(prev?.isError ?? false)) {
        final name = next.station?.name ?? 'Station';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name is offline or unavailable.'),
            backgroundColor: RadioV2Colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (index) =>
                shell.goBranch(index, initialLocation: index == shell.currentIndex),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.radio_outlined),
                selectedIcon: Icon(Icons.radio),
                label: 'Browse',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline),
                selectedIcon: Icon(Icons.favorite),
                label: 'Favourites',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
