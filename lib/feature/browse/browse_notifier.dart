import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/station_repository.dart';
import '../../core/providers.dart';
import 'browse_state.dart';

const _pageSize = 50;
const _debounce = Duration(milliseconds: 300);

class BrowseNotifier extends StateNotifier<BrowseUiState> {
  final StationRepository _repo;
  Timer? _debounceTimer;
  String _currentQuery = '';
  bool _isLoadingMore = false;

  BrowseNotifier(this._repo) : super(const BrowseLoading()) {
    _load('');
  }

  Future<void> onSearch(String query) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => _load(query));
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! BrowseSuccess || !current.hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final more = await _repo.searchStations(
        _currentQuery,
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

  Future<void> retry() => _load(_currentQuery);

  Future<void> _load(String query) async {
    _currentQuery = query;
    state = const BrowseLoading();
    try {
      final stations = await _repo.searchStations(query, 0, _pageSize);
      if (stations.isEmpty) {
        state = BrowseEmpty(query: query);
      } else {
        state = BrowseSuccess(
          stations: stations,
          hasMore: stations.length == _pageSize,
          query: query,
        );
      }
    } catch (e) {
      state = BrowseError(e.toString());
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final browseNotifierProvider =
    StateNotifierProvider<BrowseNotifier, BrowseUiState>((ref) {
  return BrowseNotifier(ref.watch(stationRepositoryProvider));
});
