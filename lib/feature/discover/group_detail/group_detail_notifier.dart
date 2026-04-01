import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/repository/station_repository.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import 'group_detail_state.dart';

const _pageSize = 30;

class GroupDetailNotifier extends StateNotifier<GroupDetailUiState> {
  final StationRepository _repo;
  final AppDatabase _db;
  final int groupId;
  bool _isLoadingMore = false;

  GroupDetailNotifier(this._repo, this._db, this.groupId)
      : super(const GroupDetailLoading()) {
    _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! GroupDetailSuccess || !current.hasMore || _isLoadingMore) {
      return;
    }
    _isLoadingMore = true;
    try {
      final more = await _repo.getStationsByGroup(
        groupId,
        current.stations.length,
        _pageSize,
      );
      state = current.copyWith(
        stations: [...current.stations, ...more],
        hasMore: more.length == _pageSize,
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> retry() => _load();

  Future<void> _load() async {
    state = const GroupDetailLoading();
    try {
      final groupRow = await _db.groupDao.getGroupById(groupId);
      final groupName = groupRow?.name ?? 'Group';
      final featured = await _repo.getFeaturedByGroup(groupId);
      final stations = await _repo.getStationsByGroup(groupId, 0, _pageSize);
      state = GroupDetailSuccess(
        groupName: groupName,
        featured: featured,
        stations: stations,
        hasMore: stations.length == _pageSize,
      );
    } catch (e) {
      state = GroupDetailError(e.toString());
    }
  }
}

final groupDetailNotifierProvider = StateNotifierProvider.family<
  GroupDetailNotifier,
  GroupDetailUiState,
  int
>((ref, groupId) {
  return GroupDetailNotifier(
    ref.watch(stationRepositoryProvider),
    ref.watch(appDatabaseProvider),
    groupId,
  );
});
