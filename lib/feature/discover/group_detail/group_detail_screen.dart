import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/model/station.dart';
import '../../../core/ui/widgets/station_list_item.dart';
import '../../../core/designsystem/colors.dart';
import '../../player/player_notifier.dart';
import '../../player/player_state.dart';
import 'group_detail_notifier.dart';
import 'group_detail_state.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final int groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(groupDetailNotifierProvider(widget.groupId).notifier)
          .loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildList(
    BuildContext context, {
    required List<Station> featured,
    required List<Station> stations,
    required bool hasMore,
    required bool isSearching,
    required PlayerUiState playerState,
  }) {
    // When searching, skip the featured section entirely
    final effectiveFeatured = isSearching ? <Station>[] : featured;
    final hasFeatured = effectiveFeatured.isNotEmpty;

    final headerOffset = hasFeatured ? 1 : 0;
    final dividerOffset = hasFeatured ? 1 : 0;
    final totalItems =
        headerOffset +
        effectiveFeatured.length +
        dividerOffset +
        stations.length +
        (hasMore ? 1 : 0);
    final playlist = [...effectiveFeatured, ...stations];

    if (stations.isEmpty && !hasMore && !hasFeatured) {
      return Center(
        child: Text(
          isSearching ? 'No stations match your search' : 'No stations',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: RadioV2Colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // "Featured" header
        if (hasFeatured && index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Featured',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        // Featured stations
        if (hasFeatured && index < headerOffset + effectiveFeatured.length) {
          final station = effectiveFeatured[index - headerOffset];
          final isSelected = playerState.maybeWhen(
            active: (s, _, __, ___, ____) => s.id == station.id,
            orElse: () => false,
          );
          final isPlaying = playerState.maybeWhen(
            active: (s, playing, _, __, ___) => s.id == station.id && playing,
            orElse: () => false,
          );
          return StationListItem(
            station: station,
            isSelected: isSelected,
            isPlaying: isPlaying,
            onTap: () => ref
                .read(playerNotifierProvider.notifier)
                .playStation(station, playlist),
            onFavouriteTap: () => ref
                .read(playerNotifierProvider.notifier)
                .toggleFavourite(station.id),
          );
        }

        // Divider between featured and rest
        if (hasFeatured && index == headerOffset + effectiveFeatured.length) {
          return const Divider(
            color: RadioV2Colors.divider,
            thickness: 1,
            height: 1,
          );
        }

        final stationIndex =
            index - headerOffset - effectiveFeatured.length - dividerOffset;

        if (stationIndex == stations.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final station = stations[stationIndex];
        final isSelected = playerState.maybeWhen(
          active: (s, _, __, ___, ____) => s.id == station.id,
          orElse: () => false,
        );
        final isPlaying = playerState.maybeWhen(
          active: (s, playing, _, __, ___) => s.id == station.id && playing,
          orElse: () => false,
        );
        return StationListItem(
          station: station,
          isSelected: isSelected,
          isPlaying: isPlaying,
          onTap: () => ref
              .read(playerNotifierProvider.notifier)
              .playStation(station, playlist),
          onFavouriteTap: () => ref
              .read(playerNotifierProvider.notifier)
              .toggleFavourite(station.id),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupDetailNotifierProvider(widget.groupId));
    final playerState = ref.watch(playerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state is GroupDetailSuccess ? state.groupName : 'Loading…',
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search stations…',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (q) {
                ref
                    .read(
                      groupDetailNotifierProvider(widget.groupId).notifier,
                    )
                    .onSearch(q);
              },
            ),
          ),
        ),
      ),
      body: switch (state) {
        GroupDetailLoading() =>
          const Center(child: CircularProgressIndicator()),
        GroupDetailError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: RadioV2Colors.error,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref
                    .read(
                      groupDetailNotifierProvider(widget.groupId).notifier,
                    )
                    .retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        GroupDetailSuccess(
          :final featured,
          :final stations,
          :final hasMore,
          :final searchQuery,
        ) =>
          _buildList(
            context,
            featured: featured,
            stations: stations,
            hasMore: hasMore,
            isSearching: searchQuery.isNotEmpty,
            playerState: playerState,
          ),
      },
    );
  }
}
