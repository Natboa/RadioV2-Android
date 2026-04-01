import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/model/station.dart';
import '../../designsystem/colors.dart';

class StationListItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: _StationLogo(logoUrl: station.logoUrl, size: 48),
      title: Text(
        station.name,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: isPlaying ? RadioV2Colors.accent : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          station.isFavourite ? Icons.favorite : Icons.favorite_outline,
          color:
              station.isFavourite ? RadioV2Colors.accent : null,
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
