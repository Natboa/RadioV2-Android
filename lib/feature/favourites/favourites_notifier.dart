import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/favourite_repository.dart';
import '../../core/providers.dart';
import 'favourites_state.dart';

class FavouritesNotifier extends StateNotifier<FavouritesUiState> {
  final FavouriteRepository _repo;
  StreamSubscription? _sub;

  FavouritesNotifier(this._repo) : super(const FavouritesLoading()) {
    _sub = _repo.watchFavourites().listen(
      (stations) {
        state = stations.isEmpty
            ? const FavouritesEmpty()
            : FavouritesSuccess(stations);
      },
      onError: (e) => state = FavouritesError(e.toString()),
    );
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
