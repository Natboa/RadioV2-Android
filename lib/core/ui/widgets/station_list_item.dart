import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/model/station.dart';
import '../../../core/providers.dart';
import '../../designsystem/colors.dart';
import 'sound_bars.dart';

/// Live favourite status for a station, sourced directly from FavouriteTable.
final _isFavouriteProvider =
    StreamProvider.autoDispose.family<bool, int>((ref, stationId) {
  return ref.watch(favouriteRepositoryProvider).watchIsFavourite(stationId);
});

class StationListItem extends ConsumerWidget {
  final Station station;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;

  const StationListItem({
    super.key,
    required this.station,
    required this.isPlaying,
    required this.onTap,
    required this.onFavouriteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavourite =
        ref.watch(_isFavouriteProvider(station.id)).valueOrNull ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _StationLogo(logoUrl: station.logoUrl, size: 48),
      title: Row(
        children: [
          Expanded(
            child: Text(
              station.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isPlaying ? RadioV2Colors.accent : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPlaying) ...[
            const SizedBox(width: 8),
            SoundBars(isAnimating: isPlaying),
          ],
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          isFavourite ? Icons.favorite : Icons.favorite_outline,
          color: isFavourite ? const Color(0xFFE53935) : null,
        ),
        onPressed: onFavouriteTap,
      ),
      onTap: onTap,
    );
  }
}

class _StationLogo extends StatelessWidget {
  final String? logoUrl;
  final double size;

  const _StationLogo({this.logoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: logoUrl != null
          ? CachedNetworkImage(
              imageUrl: logoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _placeholder(size),
              placeholder: (_, __) => _placeholder(size),
            )
          : _placeholder(size),
    );
  }

  Widget _placeholder(double size) => Container(
    width: size,
    height: size,
    color: RadioV2Colors.surfaceVariant,
    child: const Icon(Icons.radio, color: RadioV2Colors.onSurfaceVariant),
  );
}
