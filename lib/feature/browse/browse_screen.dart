import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/station.dart';
import '../../core/providers.dart';
import '../../core/ui/widgets/station_list_item.dart';
import '../../core/designsystem/colors.dart';
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
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(browseNotifierProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final recentlyVisited = ref.watch(recentlyVisitedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse'),
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
                setState(() => _query = q);
                ref.read(browseNotifierProvider.notifier).onSearch(q);
              },
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? _RecentlyVisitedView(
              stations: recentlyVisited,
              playerState: playerState,
              scrollController: _scrollController,
              onTap: (station) => ref
                  .read(playerNotifierProvider.notifier)
                  .playStation(station, recentlyVisited),
              onFavouriteTap: (id) => ref
                  .read(playerNotifierProvider.notifier)
                  .toggleFavourite(id),
            )
          : _SearchResultsView(
              scrollController: _scrollController,
              playerState: playerState,
              onRetry: () => ref.read(browseNotifierProvider.notifier).retry(),
              onTap: (station, stations) => ref
                  .read(playerNotifierProvider.notifier)
                  .playStation(station, stations),
              onFavouriteTap: (id) => ref
                  .read(playerNotifierProvider.notifier)
                  .toggleFavourite(id),
            ),
    );
  }
}

class _RecentlyVisitedView extends ConsumerWidget {
  final List<Station> stations;
  final PlayerUiState playerState;
  final ScrollController scrollController;
  final void Function(Station) onTap;
  final void Function(int) onFavouriteTap;

  const _RecentlyVisitedView({
    required this.stations,
    required this.playerState,
    required this.scrollController,
    required this.onTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radio,
              size: 64,
              color: RadioV2Colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No stations visited yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: RadioV2Colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Discover and play stations to see them here',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: RadioV2Colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: stations.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Recently Visited',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        final station = stations[index - 1];
        final isPlaying = playerState.maybeWhen(
          active: (s, _, __, ___, ____) => s.id == station.id,
          orElse: () => false,
        );
        return StationListItem(
          station: station,
          isPlaying: isPlaying,
          onTap: () => onTap(station),
          onFavouriteTap: () => onFavouriteTap(station.id),
        );
      },
    );
  }
}

class _SearchResultsView extends ConsumerWidget {
  final ScrollController scrollController;
  final PlayerUiState playerState;
  final VoidCallback onRetry;
  final void Function(Station, List<Station>) onTap;
  final void Function(int) onFavouriteTap;

  const _SearchResultsView({
    required this.scrollController,
    required this.playerState,
    required this.onRetry,
    required this.onTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(browseNotifierProvider);
    return switch (state) {
      BrowseLoading() => const Center(child: CircularProgressIndicator()),
      BrowseError(:final message) => _ErrorView(
        message: message,
        onRetry: onRetry,
      ),
      BrowseEmpty(:final query) => Center(
        child: Text(
          'No results for "$query"',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      BrowseSuccess(:final stations, :final hasMore) => ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: stations.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == stations.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final station = stations[index];
          final isPlaying = playerState.maybeWhen(
            active: (s, _, __, ___, ____) => s.id == station.id,
            orElse: () => false,
          );
          return StationListItem(
            station: station,
            isPlaying: isPlaying,
            onTap: () => onTap(station, stations),
            onFavouriteTap: () => onFavouriteTap(station.id),
          );
        },
      ),
    };
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: RadioV2Colors.error, size: 48),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
