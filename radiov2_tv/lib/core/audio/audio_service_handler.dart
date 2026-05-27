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

  // Incremented to invalidate any in-flight playUrl operation.
  // This prevents a late setAudioSource/play from resuming after the user
  // has paused/stopped.
  int _connectToken = 0;

  // Serialize playUrl calls to avoid overlapping setAudioSource/play operations
  // which can lead to late/stale ICY metadata surfacing after a source swap.
  Future<void> _playUrlSerial = Future.value();

  // Track last broadcast values to avoid redundant notification redraws during steady streaming
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
    required int stationId,
    required String streamUrl,
    required String title,
    String? artUrl,
  }) {
    mediaItem.add(MediaItem(
      id: stationId.toString(),
      title: title,
      extras: {
        'stationId': stationId,
        'streamUrl': streamUrl,
      },
      artUri: artUrl != null ? Uri.tryParse(artUrl) : null,
    ));
  }

  Future<void> playUrl(String url) async {
    final token = ++_connectToken;
    icyMetadataStream.add(null);
    _playUrlSerial = _playUrlSerial.then((_) async {
      if (token != _connectToken) return;
      try {
        await _player.setAudioSource(
          AudioSource.uri(Uri.parse(url), headers: {'Icy-MetaData': '1'}),
        );
        if (token != _connectToken) return;
        await _player.play();
      } catch (_) {
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ));
      }
    });
    return _playUrlSerial;
  }

  @override
  Future<void> play() async {
    final extras = mediaItem.value?.extras;
    final url = extras?['streamUrl'];
    if (url is! String || url.isEmpty) return;

    // Live radio: always reconnect fresh to avoid resuming stale buffered audio.
    await playUrl(url);
  }

  @override
  Future<void> pause() async {
    // Live radio: "pause" is a full disconnect.
    await stop();
  }

  @override
  Future<void> stop() async {
    _connectToken++;
    icyMetadataStream.add(null);
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
    final isPlaying = _player.playing;
    final processingState = event.processingState;

    // ICY metadata can briefly report stale values during source swaps or
    // buffering. Only surface it once the player is in a steady ready state.
    final rawIcyTitle =
        processingState == ProcessingState.ready ? event.icyMetadata?.info?.title : null;
    final icyTitle = (rawIcyTitle != null && rawIcyTitle.trim().isNotEmpty)
        ? rawIcyTitle
        : null;

    if (icyTitle != icyMetadataStream.value) {
      icyMetadataStream.add(icyTitle);
      // Reflect ICY text as notification subtitle
      final current = mediaItem.value;
      if (current != null) {
        mediaItem.add(current.copyWith(
          artist: icyTitle ?? ' ',
        ));
      }
    }

    // Only skip broadcast during steady streaming to avoid excessive redraws.
    // Always broadcast when state changes or when not in ready state.
    if (isPlaying == _lastPlaying &&
        processingState == _lastProcessingState &&
        processingState == ProcessingState.ready) {
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
