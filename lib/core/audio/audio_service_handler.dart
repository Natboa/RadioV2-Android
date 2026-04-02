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

  /// Stream of ICY metadata (now-playing text from stream)
  final BehaviorSubject<String?> icyMetadataStream =
      BehaviorSubject.seeded(null);

  RadioAudioHandler() {
    _player.playbackEventStream.listen(_broadcastPlaybackState);
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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

  void _broadcastPlaybackState(PlaybackEvent event) {
    // ICY metadata (now-playing title) arrives via PlaybackEvent
    final icyTitle = event.icyMetadata?.info?.title;
    if (icyTitle != icyMetadataStream.value) {
      icyMetadataStream.add(icyTitle);
    }

    final isPlaying = _player.playing;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
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
  }
}
