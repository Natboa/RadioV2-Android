import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/station_repository.dart';
import '../../core/model/category.dart';
import '../../core/providers.dart';
import 'discover_state.dart';

class DiscoverNotifier extends StateNotifier<DiscoverUiState> {
  final StationRepository _repo;
  List<CategoryWithGroups>? _cache;

  DiscoverNotifier(this._repo) : super(const DiscoverLoading()) {
    _load();
  }

  Future<void> retry() => _load(force: true);

  Future<void> _load({bool force = false}) async {
    if (!force && _cache != null) {
      state = DiscoverSuccess(_cache!);
      return;
    }
    state = const DiscoverLoading();
    try {
      final categories = await _repo.getAllCategoriesWithGroups();
      _cache = categories;
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
