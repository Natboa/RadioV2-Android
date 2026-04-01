import '../../core/model/station.dart';

sealed class FavouritesUiState {
  const FavouritesUiState();
}

class FavouritesLoading extends FavouritesUiState {
  const FavouritesLoading();
}

class FavouritesEmpty extends FavouritesUiState {
  const FavouritesEmpty();
}

class FavouritesSuccess extends FavouritesUiState {
  final List<Station> stations;
  const FavouritesSuccess(this.stations);
}

class FavouritesError extends FavouritesUiState {
  final String message;
  const FavouritesError(this.message);
}
