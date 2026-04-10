import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/model/station.dart';
import '../../../designsystem/tv_colors.dart';
import '../../../feature/player/player_notifier.dart';
import '../../../navigation/tv_destinations.dart';
import '../../../widgets/tv_station_tile.dart';
import 'group_detail_notifier_tv.dart';
import 'group_detail_state_tv.dart';

class GroupDetailScreen extends ConsumerWidget {
  final int groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupDetailTvNotifierProvider(groupId));

    return switch (state) {
      GroupDetailTvLoading() =>
        const Center(child: CircularProgressIndicator()),
      GroupDetailTvError(:final message) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: TvColors.error, size: 48),
              const SizedBox(height: 16),
              Text(message,
                  style: const TextStyle(color: TvColors.onSurfaceVariant)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(groupDetailTvNotifierProvider(groupId).notifier)
                    .retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      GroupDetailTvSuccess() => _GroupDetailContent(
          groupId: groupId,
          state: state,
        ),
    };
  }
}

class _GroupDetailContent extends ConsumerWidget {
  final int groupId;
  final GroupDetailTvSuccess state;

  const _GroupDetailContent({required this.groupId, required this.state});

  void _play(BuildContext context, WidgetRef ref, Station station, List<Station> playlist) {
    ref.read(playerNotifierProvider.notifier).playStation(station, playlist);
    context.push(TvRoutes.player);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStations = [...state.featured, ...state.stations];
    final hasFeatured = state.featured.isNotEmpty;

    return Scaffold(
      backgroundColor: TvColors.background,
      body: Padding(
        padding: const EdgeInsets.only(left: 48, right: 48, top: 48, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: TvColors.onBackground),
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 16),
                Text(
                  state.groupName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollEndNotification && n.metrics.extentAfter < 400) {
                    ref.read(groupDetailTvNotifierProvider(groupId).notifier).loadMore();
                  }
                  return false;
                },
                child: CustomScrollView(
                  slivers: [
                    if (hasFeatured) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Featured',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: TvColors.accent,
                            ),
                          ),
                        ),
                      ),
                      SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => TvStationTile(
                            station: state.featured[i],
                            autofocus: i == 0,
                            onTap: () => _play(context, ref, state.featured[i], allStations),
                          ),
                          childCount: state.featured.length,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: TvColors.divider, thickness: 1),
                        ),
                      ),
                    ],
                    SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => TvStationTile(
                          station: state.stations[i],
                          autofocus: !hasFeatured && i == 0,
                          onTap: () => _play(context, ref, state.stations[i], allStations),
                        ),
                        childCount: state.stations.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
