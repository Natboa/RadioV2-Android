import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/repository/station_repository.dart';
import '../../../core/database/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/images/station_artwork_cache.dart';
import 'group_detail_state.dart';

const _pageSize = 30;

class GroupDetailNotifier extends StateNotifier<GroupDetailUiState> {
  final StationRepository _repo;
  final AppDatabase _db;
  final int groupId;
  bool _isLoadingMore = false;
  Timer? _debounce;
  final Set<String> Function() _artworkFailures;
  Set<String> _artworkSnapshot = const {};

  GroupDetailNotifier(this._repo, this._db, this.groupId,
      {Set<String> Function()? artworkFailures})
      : _artworkFailures = artworkFailures ?? (() => const {}),
        super(const GroupDetailLoading()) {
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadWithQuery(query);
    });
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! GroupDetailSuccess || !current.hasMore || _isLoadingMore) {
      return;
    }
    _isLoadingMore = true;
    try {
      final query = current.searchQuery.isEmpty ? null : current.searchQuery;
      final more = await _repo.getStationsByGroup(
        groupId,
        current.stations.length,
        _pageSize,
        query: query,
        unavailableArtworkUrls: _artworkSnapshot,
      );
      if (!mounted) return;
      state = current.copyWith(
        stations: [...current.stations, ...more],
        hasMore: more.length == _pageSize,
      );
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> retry() => _load();

  Future<void> _loadWithQuery(String query) async {
    final current = state;
    if (current is! GroupDetailSuccess) return;
    final dbQuery = query.isEmpty ? null : query;
    try {
      final stations = await _repo.getStationsByGroup(
        groupId,
        0,
        _pageSize,
        query: dbQuery,
        unavailableArtworkUrls: _artworkSnapshot,
      );
      if (!mounted) return;
      state = current.copyWith(
        searchQuery: query,
        stations: stations,
        hasMore: stations.length == _pageSize,
      );
    } catch (e) {
      if (mounted) state = GroupDetailError(e.toString());
    }
  }

  Future<void> _load() async {
    // Freeze once per open/explicit refresh, including every pagination/search
    // request. Late image failures cannot move or duplicate visible stations.
    _artworkSnapshot = Set.unmodifiable(_artworkFailures());
    state = const GroupDetailLoading();
    try {
      final groupRow = await _db.groupDao.getGroupById(groupId);
      if (!mounted) return;
      final groupName = groupRow?.name ?? 'Group';
      final featured = await _repo.getFeaturedByGroup(groupId,
          unavailableArtworkUrls: _artworkSnapshot);
      final stations = await _repo.getStationsByGroup(groupId, 0, _pageSize,
          unavailableArtworkUrls: _artworkSnapshot);
      if (!mounted) return;
      state = GroupDetailSuccess(
        groupName: groupName,
        featured: featured,
        stations: stations,
        hasMore: stations.length == _pageSize,
      );
    } catch (e) {
      if (mounted) state = GroupDetailError(e.toString());
    }
  }
}

final groupDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<GroupDetailNotifier, GroupDetailUiState, int>((ref, groupId) {
  return GroupDetailNotifier(
    ref.watch(stationRepositoryProvider),
    ref.watch(appDatabaseProvider),
    groupId,
    artworkFailures: () => ref.read(stationArtworkCacheProvider).snapshot,
  );
});
