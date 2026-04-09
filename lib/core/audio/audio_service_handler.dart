import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../data/repository/station_repository.dart';
import '../data/repository/favourite_repository.dart';
import '../model/station.dart';

// Provided via ProviderScope override in main.dart
final audioHandlerProvider = Provider<RadioAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
});

class RadioAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final StationRepository _stationRepo;
  final FavouriteRepository _favouriteRepo;

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

  RadioAudioHandler({
    required StationRepository repository,
    required FavouriteRepository favouriteRepository,
  })  : _stationRepo = repository,
        _favouriteRepo = favouriteRepository {
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
    final defaultPlaceholder = Uri.parse('android.resource://com.radiov2.radiov2_android/drawable/radiov2_logo');
    mediaItem.add(MediaItem(
      id: id,
      title: title,
      artUri: (artUrl != null && artUrl.isNotEmpty) ? Uri.tryParse(artUrl) : defaultPlaceholder,
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

  // --- Android Auto Media Browser Setup ---

  MediaItem _stationToMediaItem(Station station) {
    Uri? uri;
    if (station.logoUrl != null && station.logoUrl!.isNotEmpty) {
      uri = Uri.tryParse(station.logoUrl!);
    }
    
    // A default logo placeholder for Android Auto when the station has no logo
    final defaultPlaceholder = Uri.parse('android.resource://com.radiov2.radiov2_android/drawable/radiov2_logo');

    return MediaItem(
      id: station.id.toString(),
      title: station.name,
      artist: ' ', // Empty space prevents Android Auto from defaulting to "RadioV2"
      displaySubtitle: ' ',
      displayDescription: ' ',
      artUri: uri ?? defaultPlaceholder,
      playable: true,
      extras: {'streamUrl': station.streamUrl},
    );
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    switch (parentMediaId) {
      case AudioService.browsableRootId:
      case AudioService.recentRootId:
      case 'suggested':
      case 'recommended':
        // Show a single Favourites folder at the root
        return [
          const MediaItem(
            id: 'favourites',
            title: 'Favourites',
            artist: ' ',
            displaySubtitle: ' ',
            displayDescription: ' ',
            playable: false,
          ),
        ];
      case 'favourites':
        final list = await _favouriteRepo.getFavourites();
        return list.map(_stationToMediaItem).toList();
      default:
        return [];
    }
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    final id = int.tryParse(mediaId);
    if (id == null) return null;
    final station = await _stationRepo.getStationById(id);
    if (station == null) return null;
    return _stationToMediaItem(station);
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    final id = int.tryParse(mediaId);
    if (id == null) return;
    final station = await _stationRepo.getStationById(id);
    if (station == null) return;
    
    // Set metadata before loading so OS updates UI
    mediaItem.add(_stationToMediaItem(station));
    
    await playUrl(station.streamUrl);
  }

  Future<void> dispose() async {
    await _player.dispose();
    await icyMetadataStream.close();
    await skipToNextStream.close();
    await skipToPreviousStream.close();
  }
}

