import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_destinations.dart';
import '../core/designsystem/app_notification.dart';
import '../core/designsystem/motion.dart';
import '../feature/browse/browse_screen.dart';
import '../feature/player/mini_player.dart';
import '../feature/player/player_notifier.dart';
import '../feature/player/player_state.dart';
import '../feature/discover/discover_screen.dart';
import '../feature/discover/group_detail/group_detail_screen.dart';
import '../feature/favourites/favourites_screen.dart';
import '../feature/settings/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(initialLocation: AppRoutes.favourites, routes: [
    GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppScaffold(shell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.browse, builder: (_, __) => const BrowseScreen())
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.discover,
              builder: (_, __) => const DiscoverScreen(),
              routes: [
                GoRoute(
                    path: 'group/:groupId',
                    builder: (context, state) => GroupDetailScreen(
                        groupId: int.parse(state.pathParameters['groupId']!))),
              ])
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: AppRoutes.favourites,
              builder: (_, __) => const FavouritesScreen())
        ]),
      ],
    ),
  ]);
  ref.onDispose(router.dispose);
  return router;
});

class AppScaffold extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const AppScaffold({super.key, required this.shell});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<PlayerUiState>(playerNotifierProvider, (prev, next) {
      if (next.isError && !(prev?.isError ?? false)) {
        AppNotification.show(context,
            '${next.station?.name ?? 'This station'} isn’t available right now.',
            icon: Icons.wifi_off_rounded, actionLabel: 'Retry', onAction: () {
          if (next.station != null) {
            ref
                .read(playerNotifierProvider.notifier)
                .playStation(next.station!, next.playlist);
          }
        });
      }
    });
    final wide = MediaQuery.sizeOf(context).width >= 700;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    void select(int index) {
      FocusScope.of(context).unfocus();
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
    }

    return Scaffold(
      body: wide
          ? Row(children: [
              SafeArea(
                  right: false,
                  child: NavigationRail(
                    selectedIndex: shell.currentIndex,
                    onDestinationSelected: select,
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                          icon: Icon(Icons.radio_outlined),
                          selectedIcon: Icon(Icons.radio_rounded),
                          label: Text('Browse')),
                      NavigationRailDestination(
                          icon: Icon(Icons.explore_outlined),
                          selectedIcon: Icon(Icons.explore_rounded),
                          label: Text('Discover')),
                      NavigationRailDestination(
                          icon: Icon(Icons.favorite_border_rounded),
                          selectedIcon: Icon(Icons.favorite_rounded),
                          label: Text('Favourites')),
                    ],
                  )),
              const VerticalDivider(width: 1),
              Expanded(child: shell),
            ])
          : shell,
      bottomNavigationBar: keyboard
          ? null
          : Column(mainAxisSize: MainAxisSize.min, children: [
              const MiniPlayerBar(),
              if (!wide)
                NavigationBar(
                  animationDuration: RadioMotion.duration(context),
                  selectedIndex: shell.currentIndex,
                  onDestinationSelected: select,
                  destinations: const [
                    NavigationDestination(
                        icon: Icon(Icons.radio_outlined),
                        selectedIcon: Icon(Icons.radio_rounded),
                        label: 'Browse'),
                    NavigationDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore_rounded),
                        label: 'Discover'),
                    NavigationDestination(
                        icon: Icon(Icons.favorite_border_rounded),
                        selectedIcon: Icon(Icons.favorite_rounded),
                        label: 'Favourites'),
                  ],
                )
              else
                SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ]),
    );
  }
}
