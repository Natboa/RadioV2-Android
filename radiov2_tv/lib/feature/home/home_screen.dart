import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/model/station.dart';
import '../../designsystem/tv_colors.dart';
import '../../feature/player/player_notifier.dart';
import '../../navigation/tv_destinations.dart';
import '../../widgets/tv_station_tile.dart';
import 'home_notifier.dart';
import 'home_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeNotifierProvider);

    return switch (state) {
      HomeLoading() => const Center(child: CircularProgressIndicator()),
      HomeError(:final message) => _ErrorView(message: message),
      HomeSuccess(:final recentlyVisited, :final featured) =>
        _HomeContent(recentlyVisited: recentlyVisited, featured: featured),
    };
  }
}

class _HomeContent extends ConsumerWidget {
  final List<Station> recentlyVisited;
  final List<Station> featured;

  const _HomeContent({
    required this.recentlyVisited,
    required this.featured,
  });

  void _play(BuildContext context, WidgetRef ref, Station station, List<Station> playlist) {
    ref.read(playerNotifierProvider.notifier).playStation(station, playlist);
    context.push(TvRoutes.player);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 48, top: 48, bottom: 24),
      child: ListView(
        children: [
          if (recentlyVisited.isNotEmpty) ...[
            _SectionHeader(title: 'Continue Listening'),
            const SizedBox(height: 16),
            _StationRow(
              stations: recentlyVisited,
              autofocusFirst: true,
              onTap: (s) => _play(context, ref, s, recentlyVisited),
            ),
            const SizedBox(height: 40),
          ],
          if (featured.isNotEmpty) ...[
            _SectionHeader(title: 'Featured'),
            const SizedBox(height: 16),
            _StationRow(
              stations: featured,
              autofocusFirst: recentlyVisited.isEmpty,
              onTap: (s) => _play(context, ref, s, featured),
            ),
          ],
          if (recentlyVisited.isEmpty && featured.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Text(
                  'Browse or discover stations to get started.',
                  style: TextStyle(color: TvColors.onSurfaceVariant, fontSize: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _StationRow extends StatelessWidget {
  final List<Station> stations;
  final void Function(Station) onTap;
  final bool autofocusFirst;

  const _StationRow({
    required this.stations,
    required this.onTap,
    this.autofocusFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, i) => TvStationTile(
          station: stations[i],
          autofocus: autofocusFirst && i == 0,
          onTap: () => onTap(stations[i]),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: TvColors.error, size: 48),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: TvColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
