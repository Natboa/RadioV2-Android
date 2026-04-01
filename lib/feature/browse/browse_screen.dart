import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/widgets/station_list_item.dart';
import '../../core/designsystem/colors.dart';
import '../player/player_notifier.dart';
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
    final state = ref.watch(browseNotifierProvider);
    final playerState = ref.watch(playerNotifierProvider);

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
              onChanged: (q) =>
                  ref.read(browseNotifierProvider.notifier).onSearch(q),
            ),
          ),
        ),
      ),
      body: switch (state) {
        BrowseLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        BrowseError(:final message) => _ErrorView(
          message: message,
          onRetry: () =>
              ref.read(browseNotifierProvider.notifier).retry(),
        ),
        BrowseEmpty(:final query) => Center(
          child: Text(
            query.isEmpty
                ? 'No stations found'
                : 'No results for "$query"',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        BrowseSuccess(:final stations, :final hasMore) => ListView.builder(
          controller: _scrollController,
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
              onTap: () => ref
                  .read(playerNotifierProvider.notifier)
                  .playStation(station, stations),
              onFavouriteTap: () => ref
                  .read(playerNotifierProvider.notifier)
                  .toggleFavourite(station.id),
            );
          },
        ),
      },
    );
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
