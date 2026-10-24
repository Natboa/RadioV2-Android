import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/designsystem/motion.dart';
import '../../core/ui/widgets/station_logo.dart';
import 'now_playing_screen.dart';
import 'player_controls.dart';
import 'player_notifier.dart';

class MiniPlayerBar extends ConsumerWidget {
  const MiniPlayerBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(playerNotifierProvider);
    if (state.isIdle) return const SizedBox.shrink();
    final station = state.station!;
    final c = Theme.of(context).colorScheme;
    final notifier = ref.read(playerNotifierProvider.notifier);
    final index = state.playlist.indexWhere((s) => s.id == station.id);
    void open() =>
        Navigator.of(context, rootNavigator: true).push(PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) => const NowPlayingScreen(),
          transitionDuration: RadioMotion.duration(context, RadioMotion.player),
          reverseTransitionDuration:
              RadioMotion.duration(context, const Duration(milliseconds: 240)),
          transitionsBuilder: (context, animation, _, child) {
            final eased = animation.drive(CurveTween(curve: RadioMotion.ease));
            return FadeTransition(
                opacity: eased,
                child: SlideTransition(
                    position:
                        Tween(begin: const Offset(0, .12), end: Offset.zero)
                            .animate(eased),
                    child: child));
          },
        ));
    return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Material(
              color: c.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                  excludeFromSemantics: true,
                  onTap: open,
                  child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(children: [
                        Hero(
                            tag: 'player-art-${station.id}',
                            child: StationLogo(
                                url: station.logoUrl,
                                stationName: station.name,
                                size: 48)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Semantics(
                          button: true,
                          label: 'Open player, ${station.name}',
                          excludeSemantics: true,
                          onTap: open,
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(station.name,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(
                                    state.isPlaying &&
                                            !state.isBuffering &&
                                            !state.isError &&
                                            state.nowPlayingText?.isNotEmpty ==
                                                true
                                        ? state.nowPlayingText!
                                        : playbackStatus(state),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ]),
                        )),
                        const SizedBox(width: 8),
                        PlayPauseButton(
                            state: state, onPressed: notifier.playPause),
                        if (MediaQuery.sizeOf(context).width >= 360)
                          IconButton(
                              tooltip: 'Next station',
                              icon: const Icon(Icons.skip_next_rounded),
                              onPressed: index >= 0 &&
                                      index < state.playlist.length - 1
                                  ? notifier.nextStation
                                  : null),
                      ]))),
            ),
          ),
        ));
  }
}
