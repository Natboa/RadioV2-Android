import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/widgets/station_logo.dart';
import 'player_notifier.dart';
import 'player_controls.dart';
import 'player_state.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerNotifierProvider);
    if (state.isIdle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            tooltip: 'Collapse player',
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            onPressed: () => Navigator.of(context).pop()),
        title: Text('Now playing', style: t.textTheme.titleMedium),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
              tooltip: 'Playback options',
              onSelected: (_) =>
                  ref.read(playerNotifierProvider.notifier).stop(),
              itemBuilder: (_) => const [
                    PopupMenuItem(value: 'stop', child: Text('Stop playback'))
                  ])
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            StationControls(state: state),
            if (state.playlist.any((s) => s.id == state.station!.id)) ...[
              const SizedBox(height: 12),
              Text(
                  'Station ${state.playlist.indexWhere((s) => s.id == state.station!.id) + 1} of ${state.playlist.length}',
                  style: t.textTheme.bodySmall),
            ],
          ]),
        ),
      ),
      body: SafeArea(
          top: false,
          child: LayoutBuilder(builder: (context, box) {
            final wide = box.maxWidth >= 700;
            final size = math.min(wide ? box.maxWidth * .4 : box.maxWidth - 64,
                math.max(144.0, math.min(300.0, box.maxHeight * .48)));
            final artwork = Hero(
                tag: 'player-art-${state.station!.id}',
                child: StationLogo(
                    url: state.station!.logoUrl,
                    stationName: state.station!.name,
                    size: size,
                    radius: 28));
            return SingleChildScrollView(
                child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
                child: wide
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            artwork,
                            const SizedBox(width: 48),
                            Flexible(
                                child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 380),
                                    child: _details(context, ref, state))),
                          ])
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: artwork),
                            const SizedBox(height: 24),
                            ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 440),
                                child: _details(context, ref, state)),
                          ]),
              ),
            ));
          })),
    );
  }

  Widget _details(BuildContext context, WidgetRef ref, PlayerUiState state) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final notifier = ref.read(playerNotifierProvider.notifier);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: Text(state.station!.name,
                style: t.textTheme.headlineMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        IconButton(
            tooltip: state.isFavourite
                ? 'Remove from favourites'
                : 'Save to favourites',
            isSelected: state.isFavourite,
            selectedIcon: Icon(Icons.favorite_rounded, color: c.onSurface),
            icon: Icon(Icons.favorite_border_rounded, color: c.onSurface),
            onPressed: () => notifier.toggleFavourite(state.station!.id)),
      ]),
      const SizedBox(height: 12),
      Align(
          alignment: Alignment.centerLeft,
          child: Text(
              state.isError
                  ? 'This station is unavailable right now. Try again or choose another station.'
                  : state.nowPlayingText?.isNotEmpty == true &&
                          !state.isBuffering
                      ? state.nowPlayingText!
                      : 'Live broadcasts. A fresh connection every time.',
              style:
                  t.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
      const SizedBox(height: 24),
      Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
              liveRegion: true,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color:
                        state.isPlaying && !state.isBuffering && !state.isError
                            ? c.primaryContainer
                            : c.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      state.isError
                          ? Icons.wifi_off_rounded
                          : state.isBuffering
                              ? Icons.sensors_rounded
                              : state.isPlaying
                                  ? Icons.sensors_rounded
                                  : Icons.pause_rounded,
                      size: 16,
                      color: state.isPlaying &&
                              !state.isBuffering &&
                              !state.isError
                          ? c.onPrimaryContainer
                          : c.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                      child: Text(playbackStatus(state),
                          style: t.textTheme.labelMedium?.copyWith(
                              color: state.isPlaying &&
                                      !state.isBuffering &&
                                      !state.isError
                                  ? c.onPrimaryContainer
                                  : c.onSurfaceVariant))),
                ]),
              ))),
    ]);
  }
}
