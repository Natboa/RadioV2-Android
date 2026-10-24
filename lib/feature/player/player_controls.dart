import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/designsystem/motion.dart';
import 'player_notifier.dart';
import 'player_state.dart';

class PlayPauseButton extends StatelessWidget {
  final PlayerUiState state;
  final VoidCallback onPressed;
  final bool large;
  const PlayPauseButton(
      {super.key,
      required this.state,
      required this.onPressed,
      this.large = false});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final size = large ? 80.0 : 48.0;
    final label = state.isBuffering
        ? 'Connecting'
        : state.isError
            ? 'Retry station'
            : state.isPlaying
                ? 'Pause'
                : 'Play';
    return Semantics(
        label: label,
        button: true,
        enabled: !state.isBuffering,
        child: Tooltip(
          excludeFromSemantics: true,
          message: label,
          child: SizedBox.square(
              dimension: size,
              child: FilledButton(
                style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                    disabledBackgroundColor: c.primaryContainer,
                    disabledForegroundColor: c.onPrimaryContainer),
                onPressed: state.isBuffering ? null : onPressed,
                child: ExcludeSemantics(
                    child: state.isBuffering
                        ? SizedBox.square(
                            dimension: large ? 28 : 20,
                            child: CircularProgressIndicator(
                                semanticsLabel: 'Connecting to station',
                                strokeWidth: 2.5, color: c.onPrimaryContainer))
                        : state.isError
                            ? Icon(Icons.refresh_rounded, size: large ? 36 : 26)
                            : TweenAnimationBuilder<double>(
                                tween: Tween(end: state.isPlaying ? 1 : 0),
                                duration: RadioMotion.duration(context),
                                curve: RadioMotion.ease,
                                builder: (_, value, __) => AnimatedIcon(
                                    icon: AnimatedIcons.play_pause,
                                    progress: AlwaysStoppedAnimation(value),
                                    size: large ? 40 : 28,
                                    color: c.onPrimary),
                              )),
              )),
        ));
  }
}

class StationControls extends ConsumerWidget {
  final PlayerUiState state;
  const StationControls({super.key, required this.state});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(playerNotifierProvider.notifier);
    final index = state.playlist.indexWhere((s) => s.id == state.station?.id);
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                tooltip: 'Previous station',
                iconSize: 36,
                icon: const Icon(Icons.skip_previous_rounded),
                onPressed: index > 0 ? notifier.previousStation : null),
            PlayPauseButton(
                state: state, large: true, onPressed: notifier.playPause),
            IconButton(
                tooltip: 'Next station',
                iconSize: 36,
                icon: const Icon(Icons.skip_next_rounded),
                onPressed: index >= 0 && index < state.playlist.length - 1
                    ? notifier.nextStation
                    : null),
          ],
        ));
  }
}

String playbackStatus(PlayerUiState state) => state.isBuffering
    ? 'Connecting…'
    : state.isError
        ? 'Station unavailable'
        : state.isPlaying
            ? 'Live radio'
            : 'Paused';
