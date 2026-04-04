import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/widgets/station_list_item.dart';
import '../../core/designsystem/colors.dart';
import '../../navigation/app_destinations.dart';
import '../player/player_notifier.dart';
import 'favourites_notifier.dart';
import 'favourites_state.dart';

class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favouritesNotifierProvider);
    final playerState = ref.watch(playerNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: switch (state) {
        FavouritesLoading() =>
          const Center(child: CircularProgressIndicator()),
        FavouritesError(:final message) => Center(
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
            ],
          ),
        ),
        FavouritesEmpty() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_outline,
                color: RadioV2Colors.onSurfaceVariant,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No favourites yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the heart on any station to save it here',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        FavouritesSuccess(:final stations) => ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: stations.length,
          itemBuilder: (context, index) {
            final station = stations[index];
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
