import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/station_repository.dart';
import '../../core/providers.dart';
import 'discover_state.dart';

class DiscoverNotifier extends StateNotifier<DiscoverUiState> {
  final StationRepository _repo;

  DiscoverNotifier(this._repo) : super(const DiscoverLoading()) {
    _load();
  }

  Future<void> retry() => _load();

  Future<void> _load() async {
    state = const DiscoverLoading();
    try {
      final categories = await _repo.getAllCategoriesWithGroups();
      state = DiscoverSuccess(categories);
    } catch (e) {
      state = DiscoverError(e.toString());
    }
  }
}

final discoverNotifierProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverUiState>((ref) {
  return DiscoverNotifier(ref.watch(stationRepositoryProvider));
});
