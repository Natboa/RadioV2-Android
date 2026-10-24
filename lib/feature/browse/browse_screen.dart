import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/station.dart';
import '../../core/providers.dart';
import '../../core/ui/widgets/content_state.dart';
import '../../core/ui/widgets/radio_search_field.dart';
import '../../core/ui/widgets/station_list_item.dart';
import '../../navigation/app_destinations.dart';
import '../player/player_notifier.dart';
import '../player/player_state.dart';
import 'browse_notifier.dart';
import 'browse_state.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});
  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMore);
  }

  void _loadMore() {
    if (_query.isNotEmpty && _scroll.position.extentAfter < 300) {
      ref.read(browseNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerNotifierProvider);
    final recent = ref.watch(recentlyVisitedProvider);
    final result = _query.isEmpty ? null : ref.watch(browseNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Browse'), actions: [
        IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push(AppRoutes.settings)),
        const SizedBox(width: 12),
      ]),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: RadioSearchField(
              controller: _search,
              hint: 'Find a station',
              onChanged: (q) {
                setState(() => _query = q.trim());
                ref.read(browseNotifierProvider.notifier).onSearch(q);
                if (_scroll.hasClients) _scroll.jumpTo(0);
              },
            )),
        Expanded(
            child: _query.isEmpty
                ? (recent.isEmpty
                    ? ContentState(
                        icon: Icons.radio_rounded,
                        title: 'Your next favourite is out there',
                        message:
                            'Search for a station, or explore a sound in Discover.',
                        actionLabel: 'Explore stations',
                        onAction: () => context.go(AppRoutes.discover),
                      )
                    : _list(recent, player,
                        heading: 'Back in rotation',
                        detail: 'Your recently played stations'))
                : switch (result!) {
                    BrowseLoading() =>
                      const Center(child: CircularProgressIndicator()),
                    BrowseError() => ContentState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Couldn’t load stations',
                        message: 'Try your search again.',
                        actionLabel: 'Try again',
                        onAction: () =>
                            ref.read(browseNotifierProvider.notifier).retry()),
                    BrowseEmpty() => ContentState(
                        icon: Icons.search_off_rounded,
                        title: 'No stations found',
                        message: 'Try a different name or a shorter search.',
                        actionLabel: 'Clear search',
                        onAction: () {
                          _search.clear();
                          setState(() => _query = '');
                          ref
                              .read(browseNotifierProvider.notifier)
                              .onSearch('');
                        }),
                    BrowseSuccess(:final stations, :final hasMore) => _list(
                        stations, player,
                        heading: 'Search results',
                        detail:
                            '${stations.length}${hasMore ? '+' : ''} ${stations.length == 1 && !hasMore ? 'station' : 'stations'}',
                        hasMore: hasMore),
                  }),
      ]),
    );
  }

  Widget _list(List<Station> stations, PlayerUiState player,
      {required String heading, required String detail, bool hasMore = false}) {
    return ListView.builder(
      key: PageStorageKey(_query.isEmpty ? 'history' : 'station-search'),
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: stations.length + 1 + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(detail, style: Theme.of(context).textTheme.bodySmall),
                  ]));
        }
        if (index > stations.length) {
          return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()));
        }
        final s = stations[index - 1];
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
                  .playStation(s, stations);
            },
            onFavouriteTap: () => ref
                .read(playerNotifierProvider.notifier)
                .toggleFavourite(s.id));
      },
    );
  }
}
