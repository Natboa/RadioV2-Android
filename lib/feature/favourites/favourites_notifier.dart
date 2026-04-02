import 'dart:async';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/favourite_repository.dart';
import '../../core/model/station.dart';
import '../../core/providers.dart';
import 'favourites_state.dart';

class FavouritesNotifier extends StateNotifier<FavouritesUiState> {
  final FavouriteRepository _repo;
  StreamSubscription? _sub;
  List<Station> _lastStations = [];

  FavouritesNotifier(this._repo) : super(const FavouritesLoading()) {
    _sub = _repo.watchFavourites().listen(
      (stations) {
        _syncImageCache(stations);
        _lastStations = stations;
        state = stations.isEmpty
            ? const FavouritesEmpty()
            : FavouritesSuccess(stations);
      },
      onError: (e) => state = FavouritesError(e.toString()),
    );
  }

  void _syncImageCache(List<Station> stations) {
    final cache = DefaultCacheManager();

    // Removed from favourites → evict their cached logo
    for (final s in _lastStations) {
      if (s.logoUrl != null && !stations.any((n) => n.id == s.id)) {
        cache.removeFile(s.logoUrl!);
      }
    }

    // Added to favourites → pre-cache their logo
    for (final s in stations) {
      if (s.logoUrl != null && !_lastStations.any((o) => o.id == s.id)) {
        cache.getSingleFile(s.logoUrl!);
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final favouritesNotifierProvider =
    StateNotifierProvider<FavouritesNotifier, FavouritesUiState>((ref) {
  return FavouritesNotifier(ref.watch(favouriteRepositoryProvider));
});
