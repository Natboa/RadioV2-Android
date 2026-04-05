import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/model/station.dart';
import '../designsystem/tv_colors.dart';
import '../designsystem/tv_focus.dart';

/// Square station tile used in Home, Browse, Favourites, and Group Detail.
class TvStationTile extends StatelessWidget {
  final Station station;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool showFocusBorder;

  const TvStationTile({
    super.key,
    required this.station,
    this.onTap,
    this.autofocus = false,
    this.showFocusBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusCard(
      onTap: onTap,
      autofocus: autofocus,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _StationLogo(logoUrl: station.logoUrl),
            // Gradient scrim at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 72,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                station.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationLogo extends StatelessWidget {
  final String? logoUrl;
  const _StationLogo({this.logoUrl});

  @override
  Widget build(BuildContext context) {
    if (logoUrl == null || logoUrl!.isEmpty) {
      return const ColoredBox(
        color: TvColors.surfaceVariant,
        child: Icon(Icons.radio, color: TvColors.onSurfaceVariant, size: 48),
      );
    }
    return CachedNetworkImage(
      imageUrl: logoUrl!,
      fit: BoxFit.cover,
      placeholder: (_, __) => const ColoredBox(
        color: TvColors.surfaceVariant,
        child: Icon(Icons.radio, color: TvColors.onSurfaceVariant, size: 48),
      ),
      errorWidget: (_, __, ___) => const ColoredBox(
        color: TvColors.surfaceVariant,
        child: Icon(Icons.radio, color: TvColors.onSurfaceVariant, size: 48),
      ),
    );
  }
}
