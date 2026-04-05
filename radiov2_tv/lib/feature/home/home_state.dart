import '../../core/model/station.dart';

sealed class HomeUiState {
  const HomeUiState();
}

class HomeLoading extends HomeUiState {
  const HomeLoading();
}

class HomeSuccess extends HomeUiState {
  final List<Station> recentlyVisited;
  final List<Station> featured;

  const HomeSuccess({
    required this.recentlyVisited,
    required this.featured,
  });
}

class HomeError extends HomeUiState {
  final String message;
  const HomeError(this.message);
}
