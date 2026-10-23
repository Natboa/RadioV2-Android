import 'package:just_audio/just_audio.dart';

/// The part of the audio player that [RadioAudioHandler] depends on, so the
/// handler's start/stop/switch logic can be tested without a real player.
abstract interface class StationPlayer {
  Stream<PlaybackEvent> get playbackEventStream;
  bool get playing;
  Duration get position;
  Duration get bufferedPosition;
  double get speed;

  /// Starts loading [url] and completes when it is ready to play. An unfinished
  /// load is aborted with [PlayerInterruptedException] when [stop] is called.
  Future<void> load(String url, {Map<String, String>? headers});

  /// For a live stream this future only completes when playback stops.
  Future<void> play();
  Future<void> stop();
  Future<void> dispose();
}

/// [StationPlayer] backed by just_audio (ExoPlayer on Android).
class JustAudioStationPlayer implements StationPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;
  @override
  bool get playing => _player.playing;
  @override
  Duration get position => _player.position;
  @override
  Duration get bufferedPosition => _player.bufferedPosition;
  @override
  double get speed => _player.speed;

  @override
  Future<void> load(String url, {Map<String, String>? headers}) =>
      _player.setAudioSource(AudioSource.uri(Uri.parse(url), headers: headers));

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() => _player.dispose();
}
