import '../../core/model/station.dart';

sealed class FavouritesTvUiState {
  const FavouritesTvUiState();
}

class FavouritesTvLoading extends FavouritesTvUiState {
  const FavouritesTvLoading();
}

class FavouritesTvEmpty extends FavouritesTvUiState {
  const FavouritesTvEmpty();
}

class FavouritesTvSuccess extends FavouritesTvUiState {
  final List<Station> stations;
  const FavouritesTvSuccess(this.stations);
}

class FavouritesTvError extends FavouritesTvUiState {
  final String message;
  const FavouritesTvError(this.message);
}
