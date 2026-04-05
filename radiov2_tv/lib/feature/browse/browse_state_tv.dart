import '../../core/model/station.dart';

sealed class BrowseTvUiState {
  const BrowseTvUiState();
}

class BrowseTvLoading extends BrowseTvUiState {
  const BrowseTvLoading();
}

class BrowseTvSuccess extends BrowseTvUiState {
  final List<Station> stations;
  final bool hasMore;

  const BrowseTvSuccess({required this.stations, required this.hasMore});

  BrowseTvSuccess copyWith({List<Station>? stations, bool? hasMore}) {
    return BrowseTvSuccess(
      stations: stations ?? this.stations,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class BrowseTvEmpty extends BrowseTvUiState {
  const BrowseTvEmpty();
}

class BrowseTvError extends BrowseTvUiState {
  final String message;
  const BrowseTvError(this.message);
}
