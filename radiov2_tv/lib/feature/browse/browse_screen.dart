import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/station.dart';
import '../../designsystem/tv_colors.dart';
import '../../feature/player/player_notifier.dart';
import '../../navigation/tv_destinations.dart';
import '../../widgets/tv_station_tile.dart';
import 'browse_notifier_tv.dart';
import 'browse_state_tv.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(browseTvNotifierProvider);

    return switch (state) {
      BrowseTvLoading() => const Center(child: CircularProgressIndicator()),
      BrowseTvEmpty() => const Center(
          child: Text(
            'No stations found.',
            style: TextStyle(color: TvColors.onSurfaceVariant, fontSize: 18),
          ),
        ),
      BrowseTvError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: TvColors.error, size: 48),
              const SizedBox(height: 16),
              Text(message,
                  style:
                      const TextStyle(color: TvColors.onSurfaceVariant)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(browseTvNotifierProvider.notifier).retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      BrowseTvSuccess(:final stations, :final hasMore) =>
        _BrowseGrid(stations: stations, hasMore: hasMore),
    };
  }
}

class _BrowseGrid extends ConsumerWidget {
  final List<Station> stations;
  final bool hasMore;

  const _BrowseGrid({required this.stations, required this.hasMore});

  void _play(BuildContext context, WidgetRef ref, Station station) {
    ref.read(playerNotifierProvider.notifier).playStation(station, stations);
    context.push(TvRoutes.player);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 48, top: 48, bottom: 24),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is ScrollEndNotification && n.metrics.extentAfter < 600) {
            ref.read(browseTvNotifierProvider.notifier).loadMore();
          }
          return false;
        },
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemCount: stations.length,
          itemBuilder: (context, i) => TvStationTile(
            station: stations[i],
            autofocus: i == 0,
            onTap: () => _play(context, ref, stations[i]),
          ),
        ),
      ),
    );
  }
}
