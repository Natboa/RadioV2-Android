import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model/station.dart';

typedef StationLoader = Future<List<Station>> Function(List<int> ids);

class RecentlyVisitedNotifier extends StateNotifier<List<Station>> {
  static const _prefsKey = 'recently_visited_ids';
  static const _maxCount = 50;

  final SharedPreferences _prefs;
  final StationLoader _loader;

  RecentlyVisitedNotifier({
    required SharedPreferences prefs,
    required StationLoader loader,
  })  : _prefs = prefs,
        _loader = loader,
        super(const []) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final raw = _prefs.getStringList(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    final ids = raw.map(int.parse).toList();
    final stations = await _loader(ids);
    if (mounted) state = stations;
  }

  void visit(Station station) {
    state = [
      station,
      ...state.where((s) => s.id != station.id),
    ].take(_maxCount).toList();
    _prefs.setStringList(
      _prefsKey,
      state.map((s) => s.id.toString()).toList(),
    );
  }
}
