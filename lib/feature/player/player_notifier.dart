import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/audio_service_handler.dart';
import '../../core/data/repository/favourite_repository.dart';
import '../../core/model/station.dart';
import '../../core/providers.dart';
import 'player_state.dart';

class PlayerNotifier extends StateNotifier<PlayerUiState> {
  final RadioAudioHandler _handler;
  final FavouriteRepository _favouriteRepo;
  final void Function(Station) _onStationVisited;

  StreamSubscription? _playbackSub;
  StreamSubscription? _metaSub;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _favSub;
  StreamSubscription? _skipNextSub;
  StreamSubscription? _skipPrevSub;

  PlayerNotifier(this._handler, this._favouriteRepo, this._onStationVisited)
      : super(const PlayerUiState()) {
    _listenPlayback();
    _listenConnectivity();
    _listenSkips();
  }

  void _listenPlayback() {
    _playbackSub = _handler.playbackState.listen((ps) {
      final isError = ps.processingState == AudioProcessingState.error;
      state = state.copyWith(
        isPlaying: ps.playing,
        isBuffering:
            ps.processingState == AudioProcessingState.loading ||
            ps.processingState == AudioProcessingState.buffering,
        isError: isError,
      );
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
      final hasConnection =
          results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && state.isBuffering && state.station != null) {
        _reconnect();
      }
    });
  }

  Future<void> _reconnect() async {
    final station = state.station;
    if (station == null) return;
    await _handler.playUrl(station.streamUrl);
  }

  Future<void> playStation(Station station, List<Station> playlist) async {
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
      id: station.streamUrl,
      title: station.name,
      artUrl: station.logoUrl,
    );
    await _handler.playUrl(station.streamUrl);

    // Upgrade artwork to a local file:// URI once cached — audio_service
    // loads file:// URIs reliably as the notification large icon / background
    if (station.logoUrl != null) {
      DefaultCacheManager()
          .getSingleFile(station.logoUrl!)
          .then((file) {
            // Only update if this station is still playing
            if (state.station?.id == station.id) {
              _handler.updateNowPlaying(
                id: station.streamUrl,
                title: station.name,
                artUrl: file.uri.toString(),
              );
            }
          })
          .catchError((_) {});
    }
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
    _playbackSub?.cancel();
    _metaSub?.cancel();
    _connectivitySub?.cancel();
    _favSub?.cancel();
    _skipNextSub?.cancel();
    _skipPrevSub?.cancel();
    super.dispose();
  }
}

final playerNotifierProvider =
    StateNotifierProvider<PlayerNotifier, PlayerUiState>((ref) {
  return PlayerNotifier(
    ref.watch(audioHandlerProvider),
    ref.watch(favouriteRepositoryProvider),
    (station) {
      final current = ref.read(recentlyVisitedProvider);
      ref.read(recentlyVisitedProvider.notifier).state = [
        station,
        ...current.where((s) => s.id != station.id),
      ].take(50).toList();
    },
  );
});
