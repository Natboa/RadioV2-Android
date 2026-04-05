import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../designsystem/tv_colors.dart';
import '../../designsystem/tv_focus.dart';
import 'player_notifier.dart';
import 'player_state.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerNotifierProvider);

    if (state.isIdle) {
      // Nothing playing — go back
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.canPop()) context.pop();
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: TvColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Artwork
              _Artwork(state: state),
              const SizedBox(width: 64),
              // Info + controls
              Expanded(child: _InfoControls(state: state)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final PlayerUiState state;
  const _Artwork({required this.state});

  @override
  Widget build(BuildContext context) {
    final logoUrl = state.station?.logoUrl;

    return SizedBox(
      width: 240,
      height: 240,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (logoUrl != null && logoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: logoUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(
                  color: TvColors.surfaceVariant,
                  child: Icon(Icons.radio,
                      color: TvColors.onSurfaceVariant, size: 80),
                ),
                errorWidget: (_, __, ___) => const ColoredBox(
                  color: TvColors.surfaceVariant,
                  child: Icon(Icons.radio,
                      color: TvColors.onSurfaceVariant, size: 80),
                ),
              )
            else
              const ColoredBox(
                color: TvColors.surfaceVariant,
                child: Icon(Icons.radio,
                    color: TvColors.onSurfaceVariant, size: 80),
              ),
            if (state.isBuffering)
              const ColoredBox(
                color: Color(0x88000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (state.isError)
              const ColoredBox(
                color: Color(0x88000000),
                child: Center(
                  child: Icon(Icons.wifi_off, color: TvColors.error, size: 64),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoControls extends ConsumerWidget {
  final PlayerUiState state;
  const _InfoControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final station = state.station!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Back + favourite row
        Row(
          children: [
            TvFocusCard(
              autofocus: false,
              onTap: () => context.pop(),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back,
                    color: TvColors.onBackground, size: 28),
              ),
            ),
            const Spacer(),
            TvFocusCard(
              onTap: () => ref
                  .read(playerNotifierProvider.notifier)
                  .toggleFavourite(station.id),
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  state.isFavourite ? Icons.favorite : Icons.favorite_outline,
                  color:
                      state.isFavourite ? TvColors.favourite : TvColors.onSurfaceVariant,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Station name
        Text(
          station.name,
          style: Theme.of(context).textTheme.titleLarge,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        // ICY now-playing text
        if (state.nowPlayingText != null && state.nowPlayingText!.isNotEmpty)
          Text(
            state.nowPlayingText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: TvColors.onSurfaceVariant,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 48),
        // Playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _ControlButton(
              icon: Icons.skip_previous,
              onTap: () =>
                  ref.read(playerNotifierProvider.notifier).previousStation(),
            ),
            const SizedBox(width: 16),
            _ControlButton(
              icon: state.isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 64,
              iconColor: state.isError ? TvColors.error : TvColors.accent,
              autofocus: true,
              onTap: () =>
                  ref.read(playerNotifierProvider.notifier).playPause(),
            ),
            const SizedBox(width: 16),
            _ControlButton(
              icon: Icons.skip_next,
              onTap: () =>
                  ref.read(playerNotifierProvider.notifier).nextStation(),
            ),
          ],
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? iconColor;
  final bool autofocus;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.size = 48,
    this.iconColor,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusCard(
      autofocus: autofocus,
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: size,
          color: iconColor ?? TvColors.onBackground,
        ),
      ),
    );
  }
}
