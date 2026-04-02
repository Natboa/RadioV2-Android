import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/designsystem/colors.dart';
import 'now_playing_screen.dart';
import 'player_notifier.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerNotifierProvider);

    if (state.isIdle) return const SizedBox.shrink();

    final station = state.station!;

    return GestureDetector(
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const NowPlayingScreen(),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 320),
        ),
      ),
      child: Container(
      height: 72,
      decoration: const BoxDecoration(
        color: RadioV2Colors.surface,
        border: Border(
          top: BorderSide(color: RadioV2Colors.miniPlayerBorder, width: 2),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // Station logo
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: station.logoUrl != null
                ? CachedNetworkImage(
                    imageUrl: station.logoUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _logoPlaceholder(),
                  )
                : _logoPlaceholder(),
          ),
          const SizedBox(width: 12),
          // Station name + now playing text
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (state.nowPlayingText != null &&
                    state.nowPlayingText!.isNotEmpty)
                  Text(
                    state.nowPlayingText!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Previous
          IconButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () =>
                ref.read(playerNotifierProvider.notifier).previousStation(),
          ),
          // Play/Pause or spinner
          if (state.isBuffering)
            const SizedBox(
              width: 40,
              height: 40,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                color: RadioV2Colors.accent,
              ),
              onPressed: () =>
                  ref.read(playerNotifierProvider.notifier).playPause(),
            ),
          // Next
          IconButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () =>
                ref.read(playerNotifierProvider.notifier).nextStation(),
          ),
          // Favourite
          IconButton(
            icon: Icon(
              state.isFavourite ? Icons.favorite : Icons.favorite_outline,
              color: state.isFavourite ? const Color(0xFFE53935) : null,
            ),
            onPressed: state.station != null
                ? () => ref
                      .read(playerNotifierProvider.notifier)
                      .toggleFavourite(state.station!.id)
                : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
    ),
    );
  }

  Widget _logoPlaceholder() => Container(
    width: 48,
    height: 48,
    color: RadioV2Colors.surfaceVariant,
    child: const Icon(Icons.radio, color: RadioV2Colors.onSurfaceVariant),
  );
}
