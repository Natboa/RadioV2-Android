import '../../../core/model/station.dart';

sealed class GroupDetailUiState {
  const GroupDetailUiState();
}

class GroupDetailLoading extends GroupDetailUiState {
  const GroupDetailLoading();
}

class GroupDetailSuccess extends GroupDetailUiState {
  final String groupName;
  final List<Station> featured;
  final List<Station> stations;
  final bool hasMore;
  final String searchQuery;

  const GroupDetailSuccess({
    required this.groupName,
    required this.featured,
    required this.stations,
    required this.hasMore,
    this.searchQuery = '',
  });

  GroupDetailSuccess copyWith({
    List<Station>? stations,
    bool? hasMore,
    String? searchQuery,
  }) {
    return GroupDetailSuccess(
      groupName: groupName,
      featured: featured,
      stations: stations ?? this.stations,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class GroupDetailError extends GroupDetailUiState {
  final String message;
  const GroupDetailError(this.message);
}
