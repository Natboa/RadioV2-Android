import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/model/station.dart';
import '../../../core/providers.dart';
import 'station_logo.dart';
import 'sound_bars.dart';

final _isFavouriteProvider =
    StreamProvider.autoDispose.family<bool, int>((ref, stationId) {
  return ref.watch(favouriteRepositoryProvider).watchIsFavourite(stationId);
});

class StationListItem extends ConsumerWidget {
  final Station station;
  final bool isSelected;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;
  const StationListItem(
      {super.key,
      required this.station,
      required this.isSelected,
      required this.isPlaying,
      required this.onTap,
      required this.onFavouriteTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved =
        ref.watch(_isFavouriteProvider(station.id)).valueOrNull ?? false;
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected
            ? t.colorScheme.primaryContainer.withValues(alpha: .28)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          minVerticalPadding: 12,
          leading: StationLogo(
              url: station.logoUrl, stationName: station.name, size: 48),
          title: Text(station.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.textTheme.titleSmall),
          subtitle: isSelected
              ? Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Row(children: [
                    if (isPlaying) ...[
                      const SoundBars(isAnimating: true),
                      const SizedBox(width: 6)
                    ],
                    Text(isPlaying ? 'Playing now' : 'Selected station',
                        style: t.textTheme.bodySmall
                            ?.copyWith(color: t.colorScheme.primary)),
                  ]))
              : null,
          selected: isSelected,
          selectedColor: t.colorScheme.onSurface,
          trailing: IconButton(
            tooltip: saved ? 'Remove from favourites' : 'Save to favourites',
            isSelected: saved,
            selectedIcon:
                Icon(Icons.favorite_rounded, color: t.colorScheme.onSurface),
            icon: Icon(Icons.favorite_border_rounded,
                color: t.colorScheme.onSurface),
            onPressed: onFavouriteTap,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
