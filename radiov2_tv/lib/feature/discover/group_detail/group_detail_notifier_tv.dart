import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/repository/station_repository.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import 'group_detail_state_tv.dart';

const _pageSize = 30;

class GroupDetailTvNotifier extends StateNotifier<GroupDetailTvUiState> {
  final StationRepository _repo;
  final AppDatabase _db;
  final int groupId;
  bool _isLoadingMore = false;

  GroupDetailTvNotifier(this._repo, this._db, this.groupId)
      : super(const GroupDetailTvLoading()) {
    _load();
  }

  Future<void> retry() => _load();

  Future<void> loadMore() async {
    final current = state;
    if (current is! GroupDetailTvSuccess || !current.hasMore || _isLoadingMore) {
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

  Future<void> _load() async {
    state = const GroupDetailTvLoading();
    try {
      final groupRow = await _db.groupDao.getGroupById(groupId);
      final groupName = groupRow?.name ?? 'Group';
      final featured = await _repo.getFeaturedByGroup(groupId);
      final stations = await _repo.getStationsByGroup(groupId, 0, _pageSize);
      state = GroupDetailTvSuccess(
        groupName: groupName,
        featured: featured,
        stations: stations,
        hasMore: stations.length == _pageSize,
      );
    } catch (e) {
      state = GroupDetailTvError(e.toString());
    }
  }
}

final groupDetailTvNotifierProvider = StateNotifierProvider.family<
    GroupDetailTvNotifier, GroupDetailTvUiState, int>((ref, groupId) {
  return GroupDetailTvNotifier(
    ref.watch(stationRepositoryProvider),
    ref.watch(appDatabaseProvider).requireValue,
    groupId,
  );
});
