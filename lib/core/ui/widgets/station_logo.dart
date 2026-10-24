import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../images/station_artwork_cache.dart';

/// Shared disk cache and bounded memory decoding; contain protects station branding.
class StationLogo extends ConsumerWidget {
  final String? url;
  final String stationName;
  final double size;
  final double radius;
  const StationLogo(
      {super.key,
      this.url,
      this.stationName = '',
      required this.size,
      this.radius = 12});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artwork = ref.read(stationArtworkCacheProvider);
    final c = Theme.of(context).colorScheme;
    final pixels =
        (size * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(1, 1024);
    final words = stationName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && !['&', '|', '-'].contains(word))
        .toList();
    final initials = words.isEmpty
        ? ''
        : words.length == 1
            ? words.first.characters.take(2).toString().toUpperCase()
            : words
                .take(2)
                .map((word) => word.characters.first)
                .join()
                .toUpperCase();
    Widget fallback() => ExcludeSemantics(
        child: SizedBox.square(
            dimension: size,
            child: initials.isEmpty
                ? Icon(Icons.radio_rounded,
                    size: size * .42, color: c.onSurfaceVariant)
                : Center(
                    child: Padding(
                        padding: EdgeInsets.all(size * .16),
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(initials,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                    fontSize: size * .34,
                                    fontWeight: FontWeight.w700,
                                    color: c.onSurfaceVariant)))))));
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: c.surfaceContainerHigh,
          child: supportsStationArtwork(url) && !artwork.isUnavailable(url!)
              ? Image(
                  image: ResizeImage(CachedNetworkImageProvider(url!),
                      width: pixels,
                      height: pixels,
                      policy: ResizeImagePolicy.fit),
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  frameBuilder: (_, child, frame, synchronous) =>
                      synchronous || frame != null ? child : fallback(),
                  errorBuilder: (_, error, ___) {
                    artwork.recordFailure(url!, error);
                    return fallback();
                  },
                )
              : fallback(),
        ));
  }
}
