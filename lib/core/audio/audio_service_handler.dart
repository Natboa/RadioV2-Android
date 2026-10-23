import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart'
    show PlayerInterruptedException, ProcessingState, PlaybackEvent;
import 'package:rxdart/rxdart.dart';

import '../data/repository/station_repository.dart';
import '../data/repository/favourite_repository.dart';
import '../model/station.dart';
import 'station_player.dart';

// Provided via ProviderScope override in main.dart
final audioHandlerProvider = Provider<RadioAudioHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main');
});

/// How long a station may take to start before we give up on it (while online).
const kStationLoadDeadline = Duration(seconds: 12);

Future<bool> _defaultIsOnline() async {
  try {
    final r = await Connectivity().checkConnectivity();
    return r.any((x) => x != ConnectivityResult.none);
  } catch (_) {
    return true; // can't tell: treat as online so a dead station still fails
  }
}

class RadioAudioHandler extends BaseAudioHandler {
  final Future<bool> Function() _isOnline;
  final Duration loadDeadline;
  final StationPlayer _player;
  final StationRepository _stationRepo;
  final FavouriteRepository _favouriteRepo;

  // Incremented to invalidate any in-flight playUrl operation.
  // This prevents a late setAudioSource/play from resuming after the user
  // has paused/stopped.
  int _connectToken = 0;

  _LoadAttempt? _loadAttempt;
  Future<void> _stopping = Future.value();
  bool _acceptPlayerEvents = true;
  PlaybackEvent? _latestEvent;
  bool _disposed = false;
  late final StreamSubscription<PlaybackEvent> _events;

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
    StationPlayer? player,
    Future<bool> Function()? isOnline,
    this.loadDeadline = kStationLoadDeadline,
    bool configureAudioSession = true,
  })  : _stationRepo = repository,
        _favouriteRepo = favouriteRepository,
        _player = player ?? JustAudioStationPlayer(),
        _isOnline = isOnline ?? _defaultIsOnline {
    _events = _player.playbackEventStream.listen(
      _broadcastPlaybackState,
      // A load failure also completes load() with an error. Ignore its duplicate
      // stream error until that attempt has settled.
      onError: (Object error, StackTrace stack) {
        if (_acceptPlayerEvents && !_disposed) _reportError(error);
      },
    );
    if (configureAudioSession) _initAudioSession();
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
    final defaultPlaceholder = Uri.parse(
        'android.resource://com.radiov2.radiov2_android/drawable/radiov2_logo');
    mediaItem.add(MediaItem(
      id: stationId.toString(),
      title: title,
      extras: {
        'stationId': stationId,
        'streamUrl': streamUrl,
      },
      artUri: (artUrl != null && artUrl.isNotEmpty)
          ? Uri.tryParse(artUrl)
          : defaultPlaceholder,
    ));
  }

  Future<void> playUrl(String url) async {
    if (_disposed) return;
    final token = ++_connectToken;
    final previous = _loadAttempt;
    _cancelLoad();
    _acceptPlayerEvents = false;
    icyMetadataStream.add(null);
    // Reset the broadcast cache: returning to the same state must clear errors.
    _lastProcessingState = null;
    _lastPlaying = null;
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.loading,
      playing: false,
      errorCode: null,
      errorMessage: null,
    ));
    if (previous != null) _stopPlayer();
    await _stopping;
    if (token != _connectToken || _disposed) return;
    _latestEvent = null;

    final attempt = _LoadAttempt(token);
    _loadAttempt = attempt;
    _armDeadline(attempt);
    try {
      // Attach a handler immediately; an interrupted native load can fail later.
      final load = _player.load(url, headers: const {'Icy-MetaData': '1'});
      unawaited(load.then((_) {
        if (attempt.done.isCompleted) return;
        attempt.timer?.cancel();
        attempt.done.complete(true);
      }, onError: (Object error, StackTrace stack) {
        if (attempt.done.isCompleted) return;
        attempt.timer?.cancel();
        attempt.done.completeError(error, stack);
      }));
      final ready = await attempt.done.future;
      if (!ready || token != _connectToken || _disposed) return;
      _loadAttempt = null;
      _acceptPlayerEvents = true;
      // just_audio keeps playing=true across a source swap; play() can then
      // return without emitting another event. Publish the ready event saved
      // during load so the UI doesn't stay on its loading spinner.
      final event = _latestEvent;
      if (event != null) _broadcastPlaybackState(event);
      // Live play() completes only when playback stops.
      unawaited(_player.play().catchError((Object error) {
        if (token == _connectToken && !_disposed) _reportError(error);
      }));
    } catch (error) {
      if (token != _connectToken || _disposed) return;
      _loadAttempt = null;
      if (error is PlayerInterruptedException) return;
      _reportError(error);
    } finally {
      attempt.timer?.cancel();
      if (identical(_loadAttempt, attempt)) _loadAttempt = null;
    }
  }

  void _armDeadline(_LoadAttempt attempt) {
    attempt.timer = Timer(loadDeadline, () async {
      if (attempt.done.isCompleted || attempt.token != _connectToken) return;
      final online = await _isOnline()
          .timeout(
            const Duration(seconds: 2),
            onTimeout: () => true,
          )
          .catchError((Object _) => true);
      if (attempt.done.isCompleted || attempt.token != _connectToken) return;
      if (!online) {
        _armDeadline(attempt);
        return;
      }
      // Complete independently of stop(): the UI deadline also holds if the
      // native side is slow to acknowledge cancellation.
      attempt.done.completeError(
          TimeoutException('Station did not respond', loadDeadline));
      _stopPlayer();
    });
  }

  void _cancelLoad() {
    final attempt = _loadAttempt;
    _loadAttempt = null;
    attempt?.timer?.cancel();
    if (attempt != null && !attempt.done.isCompleted) {
      attempt.done.complete(false);
    }
  }

  void _stopPlayer() {
    _stopping = _player.stop().catchError((Object _) {});
  }

  void _reportError(Object error) {
    _acceptPlayerEvents = false;
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.error,
      playing: false,
      errorCode: 1,
      errorMessage: error is TimeoutException
          ? 'Station did not respond. Try another station.'
          : 'Unable to play this station.',
    ));
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
    final token = ++_connectToken;
    _cancelLoad();
    _acceptPlayerEvents = false;
    icyMetadataStream.add(null);
    _stopPlayer();
    await _stopping;
    if (token == _connectToken) {
      playbackState.add(playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ));
      await super.stop();
    }
  }

  /// Forwards lock-screen/notification next tap to [skipToNextStream].
  @override
  Future<void> skipToNext() async => skipToNextStream.add(null);

  /// Forwards lock-screen/notification previous tap to [skipToPreviousStream].
  @override
  Future<void> skipToPrevious() async => skipToPreviousStream.add(null);

  void _broadcastPlaybackState(PlaybackEvent event) {
    _latestEvent = event;
    if (!_acceptPlayerEvents || _disposed) return;
    final isPlaying = _player.playing;
    final processingState = event.processingState;

    // ICY metadata can briefly report stale values during source swaps or
    // buffering. Only surface it once the player is in a steady ready state.
    final rawIcyTitle = processingState == ProcessingState.ready
        ? event.icyMetadata?.info?.title
        : null;
    final icyTitle = (rawIcyTitle != null && rawIcyTitle.trim().isNotEmpty)
        ? rawIcyTitle
        : null;

    if (icyTitle != icyMetadataStream.value) {
      icyMetadataStream.add(icyTitle);

      // Reflect ICY text as notification subtitle. Use a space when blank to
      // avoid Android Auto/OS defaults overriding the field.
      final current = mediaItem.value;
      if (current != null) {
        mediaItem.add(current.copyWith(
          artist: icyTitle ?? ' ',
        ));
      }
    }

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
    final defaultPlaceholder = Uri.parse(
        'android.resource://com.radiov2.radiov2_android/drawable/radiov2_logo');

    return MediaItem(
      id: station.id.toString(),
      title: station.name,
      artist:
          ' ', // Empty space prevents Android Auto from defaulting to "RadioV2"
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
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    final id = int.tryParse(mediaId);
    if (id == null) return;
    final station = await _stationRepo.getStationById(id);
    if (station == null) return;

    // Set metadata before loading so OS updates UI
    mediaItem.add(_stationToMediaItem(station));

    await playUrl(station.streamUrl);
  }

  Future<void> dispose() async {
    _disposed = true;
    _connectToken++;
    _cancelLoad();
    await _events.cancel();
    await _player.dispose();
    await icyMetadataStream.close();
    await skipToNextStream.close();
    await skipToPreviousStream.close();
  }
}

class _LoadAttempt {
  _LoadAttempt(this.token);
  final int token;
  final done = Completer<bool>();
  Timer? timer;
}
