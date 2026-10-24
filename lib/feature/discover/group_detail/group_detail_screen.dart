import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/model/station.dart';
import '../../../core/ui/widgets/station_list_item.dart';
import '../../../core/ui/widgets/radio_search_field.dart';
import '../../../core/ui/widgets/content_state.dart';
import '../../player/player_notifier.dart';
import 'group_detail_notifier.dart';
import 'group_detail_state.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final int groupId;
  const GroupDetailScreen({super.key, required this.groupId});
  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMore);
  }

  void _loadMore() {
    if (_scroll.position.extentAfter < 300) {
      ref.read(groupDetailNotifierProvider(widget.groupId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupDetailNotifierProvider(widget.groupId));
    return Scaffold(
      appBar: AppBar(title: const Text('Collection')),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: RadioSearchField(
                controller: _search,
                hint: 'Search this collection',
                onChanged: (q) {
                  ref
                      .read(
                          groupDetailNotifierProvider(widget.groupId).notifier)
                      .onSearch(q);
                  if (_scroll.hasClients) _scroll.jumpTo(0);
                })),
        Expanded(
            child: switch (state) {
          GroupDetailLoading() =>
            const Center(child: CircularProgressIndicator()),
          GroupDetailError() => ContentState(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn’t load this collection',
              message: 'Try opening these stations again.',
              actionLabel: 'Try again',
              onAction: () => ref
                  .read(groupDetailNotifierProvider(widget.groupId).notifier)
                  .retry()),
          GroupDetailSuccess() => _list(state),
        }),
      ]),
    );
  }

  Widget _list(GroupDetailSuccess state) {
    final player = ref.watch(playerNotifierProvider);
    final featured = state.searchQuery.isEmpty ? state.featured : <Station>[];
    final playlist = [...featured, ...state.stations];
    final headerCount = featured.isEmpty ? 1 : 2;
    return CustomScrollView(
      controller: _scroll,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(
            child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/groups/${state.groupName}.png',
                  width: 88,
                  height: 88,
                  cacheWidth:
                      (88 * MediaQuery.devicePixelRatioOf(context)).ceil(),
                  cacheHeight:
                      (88 * MediaQuery.devicePixelRatioOf(context)).ceil(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox.square(
                      dimension: 88, child: Icon(Icons.radio_rounded)),
                )),
            const SizedBox(width: 20),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(state.groupName,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('Find your frequency',
                      style: Theme.of(context).textTheme.bodySmall),
                ])),
          ]),
        )),
        if (playlist.isEmpty && !state.hasMore)
          const SliverFillRemaining(
              hasScrollBody: false,
              child: ContentState(
                  icon: Icons.search_off_rounded,
                  title: 'No stations found',
                  message: 'Try a different station name.'))
        else
          SliverList.builder(
            itemCount: playlist.length + headerCount + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _section(featured.isEmpty
                    ? (state.searchQuery.isEmpty
                        ? 'All stations'
                        : 'Search results')
                    : 'Featured stations');
              }
              if (featured.isNotEmpty && index == featured.length + 1) {
                return _section('More to explore');
              }
              final stationIndex = index -
                  1 -
                  (featured.isNotEmpty && index > featured.length ? 1 : 0);
              if (stationIndex >= playlist.length) {
                return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()));
              }
              final s = playlist[stationIndex];
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
                        .playStation(s, playlist);
                  },
                  onFavouriteTap: () => ref
                      .read(playerNotifierProvider.notifier)
                      .toggleFavourite(s.id));
            },
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium));
}
