import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/designsystem/colors.dart';
import '../../core/model/station.dart';
import 'player_notifier.dart';
import 'player_state.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerNotifierProvider);

    if (state.isIdle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Navigator.pop(context));
      return const SizedBox.shrink();
    }

    final station = state.station!;

    return Scaffold(
      backgroundColor: RadioV2Colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Top bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Now Playing',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: RadioV2Colors.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      state.isFavourite ? Icons.favorite : Icons.favorite_outline,
                      color: state.isFavourite ? const Color(0xFFE53935) : null,
                      size: 26,
                    ),
                    onPressed: () => ref
                        .read(playerNotifierProvider.notifier)
                        .toggleFavourite(station.id),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Album art ───────────────────────────────────────────────
            _AlbumArt(
              station: station,
              isBuffering: state.isBuffering,
              isError: state.isError,
            ),

            const SizedBox(height: 32),

            // ── Station name ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                station.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: RadioV2Colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── ICY text or error notice ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: state.isError
                    ? const Row(
                        key: ValueKey('error'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            color: RadioV2Colors.error,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Stream offline or unavailable',
                            style: TextStyle(
                              color: RadioV2Colors.error,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        key: ValueKey(state.nowPlayingText),
                        state.nowPlayingText?.isNotEmpty == true
                            ? state.nowPlayingText!
                            : 'Live',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: RadioV2Colors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),

            const Spacer(),

            // ── Playback controls ────────────────────────────────────────
            _Controls(state: state, ref: ref),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── Album art ──────────────────────────────────────────────────────────────────

class _AlbumArt extends StatelessWidget {
  final Station station;
  final bool isBuffering;
  final bool isError;

  const _AlbumArt({
    required this.station,
    required this.isBuffering,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.72;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isError ? 0.35 : 1.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: station.logoUrl != null
                ? CachedNetworkImage(
                    imageUrl: station.logoUrl!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _placeholder(size),
                    placeholder: (_, __) => _placeholder(size),
                  )
                : _placeholder(size),
          ),
        ),
        if (isBuffering)
          const CircularProgressIndicator(strokeWidth: 3),
        if (isError)
          Icon(
            Icons.wifi_off_rounded,
            color: RadioV2Colors.error.withValues(alpha: 0.9),
            size: size * 0.25,
          ),
      ],
    );
  }

  Widget _placeholder(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: RadioV2Colors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.radio,
          color: RadioV2Colors.onSurfaceVariant,
          size: 64,
        ),
      );
}

// ── Playback controls ──────────────────────────────────────────────────────────

class _Controls extends StatelessWidget {
  final PlayerUiState state;
  final WidgetRef ref;

  const _Controls({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(playerNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Previous
        IconButton(
          iconSize: 44,
          icon: const Icon(Icons.skip_previous_rounded),
          color: RadioV2Colors.onSurface,
          onPressed: () => notifier.previousStation(),
        ),

        // Play / Pause — large filled circle
        GestureDetector(
          onTap: state.isBuffering ? null : () => notifier.playPause(),
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: state.isError
                  ? RadioV2Colors.error
                  : RadioV2Colors.accent,
              shape: BoxShape.circle,
            ),
            child: state.isBuffering
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
          ),
        ),

        // Next
        IconButton(
          iconSize: 44,
          icon: const Icon(Icons.skip_next_rounded),
          color: RadioV2Colors.onSurface,
          onPressed: () => notifier.nextStation(),
        ),
      ],
    );
  }
}
