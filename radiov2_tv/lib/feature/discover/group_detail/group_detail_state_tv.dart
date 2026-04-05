import '../../../core/model/station.dart';

sealed class GroupDetailTvUiState {
  const GroupDetailTvUiState();
}

class GroupDetailTvLoading extends GroupDetailTvUiState {
  const GroupDetailTvLoading();
}

class GroupDetailTvSuccess extends GroupDetailTvUiState {
  final String groupName;
  final List<Station> featured;
  final List<Station> stations;
  final bool hasMore;

  const GroupDetailTvSuccess({
    required this.groupName,
    required this.featured,
    required this.stations,
    required this.hasMore,
  });

  GroupDetailTvSuccess copyWith({List<Station>? stations, bool? hasMore}) {
    return GroupDetailTvSuccess(
      groupName: groupName,
      featured: featured,
      stations: stations ?? this.stations,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class GroupDetailTvError extends GroupDetailTvUiState {
  final String message;
  const GroupDetailTvError(this.message);
}
