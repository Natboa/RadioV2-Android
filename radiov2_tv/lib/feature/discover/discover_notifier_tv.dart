import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/station_repository.dart';
import '../../core/providers.dart';
import 'discover_state_tv.dart';

class DiscoverTvNotifier extends StateNotifier<DiscoverTvUiState> {
  final StationRepository _repo;

  DiscoverTvNotifier(this._repo) : super(const DiscoverTvLoading()) {
    _load();
  }

  Future<void> retry() => _load();

  Future<void> _load() async {
    state = const DiscoverTvLoading();
    try {
      final categories = await _repo.getAllCategoriesWithGroups();
      state = DiscoverTvSuccess(categories);
    } catch (e) {
      state = DiscoverTvError(e.toString());
    }
  }
}

final discoverTvNotifierProvider =
    StateNotifierProvider<DiscoverTvNotifier, DiscoverTvUiState>((ref) {
  return DiscoverTvNotifier(ref.watch(stationRepositoryProvider));
});
