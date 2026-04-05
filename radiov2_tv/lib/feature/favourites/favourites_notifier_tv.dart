import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/favourite_repository.dart';
import '../../core/providers.dart';
import 'favourites_state_tv.dart';

class FavouritesTvNotifier extends StateNotifier<FavouritesTvUiState> {
  final FavouriteRepository _repo;
  StreamSubscription? _sub;

  FavouritesTvNotifier(this._repo) : super(const FavouritesTvLoading()) {
    _sub = _repo.watchFavourites().listen(
      (stations) {
        state = stations.isEmpty
            ? const FavouritesTvEmpty()
            : FavouritesTvSuccess(stations);
      },
      onError: (e) => state = FavouritesTvError(e.toString()),
    );
  }

  Future<void> removeFavourite(int stationId) =>
      _repo.toggleFavourite(stationId);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final favouritesTvNotifierProvider =
    StateNotifierProvider<FavouritesTvNotifier, FavouritesTvUiState>((ref) {
  return FavouritesTvNotifier(ref.watch(favouriteRepositoryProvider));
});
