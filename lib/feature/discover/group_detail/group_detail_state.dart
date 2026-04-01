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

  const GroupDetailSuccess({
    required this.groupName,
    required this.featured,
    required this.stations,
    required this.hasMore,
  });

  GroupDetailSuccess copyWith({List<Station>? stations, bool? hasMore}) {
    return GroupDetailSuccess(
      groupName: groupName,
      featured: featured,
      stations: stations ?? this.stations,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class GroupDetailError extends GroupDetailUiState {
  final String message;
  const GroupDetailError(this.message);
}
