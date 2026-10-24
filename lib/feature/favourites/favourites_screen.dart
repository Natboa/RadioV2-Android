import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/station.dart';
import '../../core/ui/widgets/content_state.dart';
import '../../core/ui/widgets/radio_search_field.dart';
import '../../core/ui/widgets/station_list_item.dart';
import '../../navigation/app_destinations.dart';
import '../player/player_notifier.dart';
import 'favourites_notifier.dart';
import 'favourites_state.dart';

class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});
  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favouritesNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites'), actions: [
        IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.settings)),
        const SizedBox(width: 12),
      ]),
      body: switch (state) {
        FavouritesLoading() => const Center(child: CircularProgressIndicator()),
        FavouritesError() => ContentState(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn’t load your favourites',
            message: 'Try opening your library again.',
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(favouritesNotifierProvider)),
        FavouritesEmpty() => ContentState(
            icon: Icons.favorite_border_rounded,
            title: 'A place for your favourites',
            message:
                'Save the stations you love with a tap on the heart. They’ll be waiting here.',
            actionLabel: 'Discover a station',
            onAction: () => context.go(AppRoutes.discover)),
        FavouritesSuccess(:final stations) => _library(stations),
      },
    );
  }

  Widget _library(List<Station> stations) {
    final player = ref.watch(playerNotifierProvider);
    final filtered = stations
        .where((s) => s.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final positions = {
      for (var i = 0; i < filtered.length; i++) filtered[i].id: i
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Text(
              '${stations.length} saved ${stations.length == 1 ? 'station' : 'stations'}. Always within reach.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant))),
      Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: RadioSearchField(
              controller: _search,
              hint: 'Search your favourites',
              onChanged: (q) => setState(() => _query = q))),
      Expanded(
          child: filtered.isEmpty
              ? const ContentState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching favourites',
                  message: 'Try another name, or clear your search.')
              : ListView.builder(
                  key: const PageStorageKey('favourites'),
                  padding: const EdgeInsets.only(bottom: 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: filtered.length,
                  findChildIndexCallback: (key) =>
                      key is ValueKey<int> ? positions[key.value] : null,
                  itemBuilder: (context, i) {
                    final s = filtered[i];
                    return StationListItem(
                        key: ValueKey(s.id),
                        station: s,
                        isSelected: player.station?.id == s.id,
                        isPlaying: player.station?.id == s.id &&
                            player.isPlaying &&
                            !player.isBuffering &&
                            !player.isError,
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          ref
                              .read(playerNotifierProvider.notifier)
                              .playStation(s, filtered);
                        },
                        onFavouriteTap: () => ref
                            .read(playerNotifierProvider.notifier)
                            .toggleFavourite(s.id));
                  },
                )),
    ]);
  }
}
