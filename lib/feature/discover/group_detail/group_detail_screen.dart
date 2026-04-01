import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/widgets/station_list_item.dart';
import '../../../core/designsystem/colors.dart';
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
  final _scrollController = ScrollController();

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
    super.dispose();
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
        ) =>
          ListView.builder(
            controller: _scrollController,
            itemCount:
                (featured.isEmpty ? 0 : featured.length + 1) +
                stations.length +
                (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              int i = index;
              if (featured.isNotEmpty) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Featured',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  );
                }
                i--;
                if (i < featured.length) {
                  final station = featured[i];
                  final isPlaying = playerState.maybeWhen(
                    active: (s, _, __, ___, ____) => s.id == station.id,
                    orElse: () => false,
                  );
                  return StationListItem(
                    station: station,
                    isPlaying: isPlaying,
                    onTap: () => ref
                        .read(playerNotifierProvider.notifier)
                        .playStation(station, [...featured, ...stations]),
                    onFavouriteTap: () => ref
                        .read(playerNotifierProvider.notifier)
                        .toggleFavourite(station.id),
                  );
                }
                i -= featured.length;
              }
              if (i == stations.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final station = stations[i];
              final isPlaying = playerState.maybeWhen(
                active: (s, _, __, ___, ____) => s.id == station.id,
                orElse: () => false,
              );
              return StationListItem(
                station: station,
                isPlaying: isPlaying,
                onTap: () => ref
                    .read(playerNotifierProvider.notifier)
                    .playStation(station, [...featured, ...stations]),
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
