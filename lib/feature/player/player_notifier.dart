import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service_handler.dart';
import '../../core/data/repository/favourite_repository.dart';
import '../../core/data/repository/station_repository.dart';
import '../../core/model/station.dart';
import '../../core/providers.dart';
import 'player_state.dart';

class PlayerNotifier extends StateNotifier<PlayerUiState> {
  final RadioAudioHandler _handler;
  final StationRepository _stationRepo;
  final FavouriteRepository _favouriteRepo;
  final void Function(Station) _onStationVisited;

  StreamSubscription? _playbackSub;
  StreamSubscription? _metaSub;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _favSub;
  StreamSubscription? _skipNextSub;
  StreamSubscription? _skipPrevSub;
  StreamSubscription? _mediaItemSub;
  Timer? _stallTimer;
  static const _stallTimeout = Duration(seconds: 15);

  PlayerNotifier(
    this._handler,
    this._stationRepo,
    this._favouriteRepo,
    this._onStationVisited,
  )
      : super(const PlayerUiState()) {
    _listenPlayback();
    _listenConnectivity();
    _listenSkips();
    _listenMediaItem();
  }

  void _listenPlayback() {
    _playbackSub = _handler.playbackState.listen((ps) {
      final wasPlaying = state.isPlaying;
      final wasBuffering = state.isBuffering;
      final wasError = state.isError;

      final isError = ps.processingState == AudioProcessingState.error;
      final isBuffering =
          ps.processingState == AudioProcessingState.loading ||
          ps.processingState == AudioProcessingState.buffering;

      final startedPlaying = !wasPlaying && ps.playing;
      final shouldClearNowPlaying =
          startedPlaying && (wasBuffering || wasError || isBuffering);

        final bufferingStarted = !wasBuffering && isBuffering;
        final errorStarted = !wasError && isError;

      if (isBuffering) {
        _stallTimer ??= Timer(_stallTimeout, _reconnect);
      } else {
        _stallTimer?.cancel();
        _stallTimer = null;
      }

      if (shouldClearNowPlaying || bufferingStarted || errorStarted) {
        state = state.copyWith(
          isPlaying: ps.playing,
          isBuffering: isBuffering,
          isError: isError,
          nowPlayingText: null,
        );
      } else {
        state = state.copyWith(
          isPlaying: ps.playing,
          isBuffering: isBuffering,
          isError: isError,
        );
      }
    });

    _metaSub = _handler.icyMetadataStream.listen((text) {
      state = state.copyWith(nowPlayingText: text);
    });
  }

  void _listenSkips() {
    _skipNextSub = _handler.skipToNextStream.listen((_) => nextStation());
    _skipPrevSub = _handler.skipToPreviousStream.listen((_) => previousStation());
  }

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      if (!state.isBuffering || state.station == null) return;
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) _reconnect();
    });
  }

  void _listenMediaItem() {
    _mediaItemSub = _handler.mediaItem.listen((item) async {
      if (item == null) return;

      final stationId = int.tryParse(item.id) ?? (item.extras?['stationId'] as int?);
      if (stationId == null) return;

      // Only refresh if station actually changed.
      if (state.station?.id == stationId) return;

      final station = await _stationRepo.getStationById(stationId);
      if (station == null) return;

      // External start (Android Auto, notification browse) should update UI.
      _stallTimer?.cancel();
      _stallTimer = null;

      state = state.copyWith(
        station: station,
        nowPlayingText: null,
      );

      _favSub?.cancel();
      _favSub = _favouriteRepo.watchIsFavourite(station.id).listen((isFav) {
        state = state.copyWith(isFavourite: isFav);
      });
    });
  }

  Future<void> _reconnect() async {
    _stallTimer?.cancel();
    _stallTimer = null;
    final station = state.station;
    if (station == null) return;
    await _handler.playUrl(station.streamUrl);
  }

  Future<void> playStation(Station station, List<Station> playlist) async {
    _stallTimer?.cancel();
    _stallTimer = null;
    _onStationVisited(station);
    // Create a fresh state so nowPlayingText and isError are truly cleared
    state = PlayerUiState(
      station: station,
      playlist: playlist,
      isBuffering: true,
    );

    // Watch favourite status for this station
    _favSub?.cancel();
    _favSub = _favouriteRepo.watchIsFavourite(station.id).listen((isFav) {
      state = state.copyWith(isFavourite: isFav);
    });

    // Set notification immediately so it appears as soon as playback starts
    _handler.updateNowPlaying(
      stationId: station.id,
      streamUrl: station.streamUrl,
      title: station.name,
      artUrl: station.logoUrl,
    );
    await _handler.playUrl(station.streamUrl);

    // Note: do NOT upgrade to file:// URI here — Android Auto cannot load
    // file:// paths from the app cache. The HTTP URL works for both the
    // phone notification and Android Auto.
  }

  Future<void> playPause() async {
    if (state.isPlaying) {
      await _handler.pause();
    } else if (state.station != null) {
      if (state.isBuffering) return;
      await _handler.play();
    }
  }

  Future<void> stop() async {
    await _handler.stop();
    _favSub?.cancel();
    state = const PlayerUiState();
  }

  Future<void> nextStation() async {
    final playlist = state.playlist;
    final current = state.station;
    if (playlist.isEmpty || current == null) return;
    final idx = playlist.indexWhere((s) => s.id == current.id);
    if (idx < 0 || idx >= playlist.length - 1) return;
    await playStation(playlist[idx + 1], playlist);
  }

  Future<void> previousStation() async {
    final playlist = state.playlist;
    final current = state.station;
    if (playlist.isEmpty || current == null) return;
    final idx = playlist.indexWhere((s) => s.id == current.id);
    if (idx <= 0) return;
    await playStation(playlist[idx - 1], playlist);
  }

  Future<void> toggleFavourite(int stationId) async {
    await _favouriteRepo.toggleFavourite(stationId);
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    _playbackSub?.cancel();
    _metaSub?.cancel();
    _connectivitySub?.cancel();
    _favSub?.cancel();
    _skipNextSub?.cancel();
    _skipPrevSub?.cancel();
    _mediaItemSub?.cancel();
    super.dispose();
  }
}

final playerNotifierProvider =
    StateNotifierProvider<PlayerNotifier, PlayerUiState>((ref) {
  return PlayerNotifier(
    ref.watch(audioHandlerProvider),
    ref.watch(stationRepositoryProvider),
    ref.watch(favouriteRepositoryProvider),
    (station) => ref.read(recentlyVisitedProvider.notifier).visit(station),
  );
});
