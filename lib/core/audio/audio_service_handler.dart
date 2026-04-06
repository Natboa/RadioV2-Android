import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

// Provided via ProviderScope override in main.dart
final audioHandlerProvider = Provider<RadioAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
});

class RadioAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  // Track last broadcast values to avoid redundant notification redraws
  ProcessingState? _lastProcessingState;
  bool? _lastPlaying;

  /// Stream of ICY metadata (now-playing text from stream)
  final BehaviorSubject<String?> icyMetadataStream =
      BehaviorSubject.seeded(null);

  /// Emits when the lock-screen/notification next button is tapped
  final PublishSubject<void> skipToNextStream = PublishSubject();

  /// Emits when the lock-screen/notification previous button is tapped
  final PublishSubject<void> skipToPreviousStream = PublishSubject();

  RadioAudioHandler() {
    _player.playbackEventStream.listen(_broadcastPlaybackState);
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  /// Call this whenever a new station starts playing to update the
  /// notification's title, artwork, and lock-screen metadata.
  void updateNowPlaying({
    required String id,
    required String title,
    String? artUrl,
  }) {
    mediaItem.add(MediaItem(
      id: id,
      title: title,
      artUri: artUrl != null ? Uri.tryParse(artUrl) : null,
    ));
  }

  Future<void> playUrl(String url) async {
    icyMetadataStream.add(null);
    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(url), headers: {'Icy-MetaData': '1'}),
      );
      await _player.play();
    } catch (_) {
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
      ));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  /// Forwards lock-screen/notification next tap to [skipToNextStream].
  @override
  Future<void> skipToNext() async => skipToNextStream.add(null);

  /// Forwards lock-screen/notification previous tap to [skipToPreviousStream].
  @override
  Future<void> skipToPrevious() async => skipToPreviousStream.add(null);

  void _broadcastPlaybackState(PlaybackEvent event) {
    // ICY metadata (now-playing title) arrives via PlaybackEvent
    final icyTitle = event.icyMetadata?.info?.title;
    if (icyTitle != icyMetadataStream.value) {
      icyMetadataStream.add(icyTitle);
      // Reflect ICY text as notification subtitle
      final current = mediaItem.value;
      if (current != null) {
        mediaItem.add(current.copyWith(
          artist: (icyTitle != null && icyTitle.isNotEmpty) ? icyTitle : null,
        ));
      }
    }

    final isPlaying = _player.playing;
    final processingState = _player.processingState;

    // Skip broadcast when nothing meaningful changed — avoids redundant
    // notification redraws on every buffer tick during live stream playback
    if (isPlaying == _lastPlaying && processingState == _lastProcessingState) {
      return;
    }
    _lastPlaying = isPlaying;
    _lastProcessingState = processingState;

    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[processingState]!,
        playing: isPlaying,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ),
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'playUrl' && extras != null) {
      await playUrl(extras['url'] as String);
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
    await icyMetadataStream.close();
    await skipToNextStream.close();
    await skipToPreviousStream.close();
  }
}
