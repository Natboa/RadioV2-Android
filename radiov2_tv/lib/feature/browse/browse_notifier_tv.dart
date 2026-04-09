import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/station_repository.dart';
import '../../core/providers.dart';
import 'browse_state_tv.dart';

const _pageSize = 50;

class BrowseTvNotifier extends StateNotifier<BrowseTvUiState> {
  final StationRepository _repo;
  bool _isLoadingMore = false;
  String _query = '';
  Timer? _debounce;

  BrowseTvNotifier(this._repo) : super(const BrowseTvLoading()) {
    _load();
  }

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = query;
      _load();
    });
  }

  Future<void> retry() => _load();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! BrowseTvSuccess || !current.hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    try {
      final more = await _repo.searchStations(
        _query,
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
    state = const BrowseTvLoading();
    try {
      final stations = await _repo.searchStations(_query, 0, _pageSize);
      if (stations.isEmpty) {
        state = const BrowseTvEmpty();
      } else {
        state = BrowseTvSuccess(
          stations: stations,
          hasMore: stations.length == _pageSize,
        );
      }
    } catch (e) {
      state = BrowseTvError(e.toString());
    }
  }
}

final browseTvNotifierProvider =
    StateNotifierProvider<BrowseTvNotifier, BrowseTvUiState>((ref) {
  return BrowseTvNotifier(ref.watch(stationRepositoryProvider));
});
