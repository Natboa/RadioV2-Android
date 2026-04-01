import '../../core/model/station.dart';

sealed class BrowseUiState {
  const BrowseUiState();
}

class BrowseLoading extends BrowseUiState {
  const BrowseLoading();
}

class BrowseSuccess extends BrowseUiState {
  final List<Station> stations;
  final bool hasMore;
  final String query;

  const BrowseSuccess({
    required this.stations,
    required this.hasMore,
    required this.query,
  });

  BrowseSuccess copyWith({List<Station>? stations, bool? hasMore}) {
    return BrowseSuccess(
      stations: stations ?? this.stations,
      hasMore: hasMore ?? this.hasMore,
      query: query,
    );
  }
}

class BrowseEmpty extends BrowseUiState {
  final String query;
  const BrowseEmpty({required this.query});
}

class BrowseError extends BrowseUiState {
  final String message;
  const BrowseError(this.message);
}
