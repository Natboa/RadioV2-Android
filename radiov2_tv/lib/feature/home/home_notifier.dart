import 'package:drift/drift.dart' show OrderingMode, OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart' hide Station;
import '../../core/model/station.dart';
import '../../core/providers.dart';
import 'home_state.dart';

class HomeNotifier extends StateNotifier<HomeUiState> {
  final AppDatabase _db;
  final List<Station> _recentlyVisited;

  HomeNotifier(this._db, this._recentlyVisited) : super(const HomeLoading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final featuredRows = await (_db.select(_db.stations)
            ..where((s) => s.isFeatured.isValue(true))
            ..orderBy([
              (s) => OrderingTerm(
                    expression: s.logoUrl.isNotNull(),
                    mode: OrderingMode.desc,
                  ),
              (s) => OrderingTerm.asc(s.name),
            ])
            ..limit(20))
          .get();

      final featured = featuredRows
          .map(
            (r) => Station(
              id: r.id,
              name: r.name,
              streamUrl: r.streamUrl,
              logoUrl: r.logoUrl,
              groupId: r.groupId,
              isFeatured: r.isFeatured,
            ),
          )
          .toList();

      state = HomeSuccess(
        recentlyVisited: _recentlyVisited,
        featured: featured,
      );
    } catch (e) {
      state = HomeError(e.toString());
    }
  }
}

final homeNotifierProvider =
    StateNotifierProvider<HomeNotifier, HomeUiState>((ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  final recent = ref.watch(recentlyVisitedProvider);
  return HomeNotifier(db, recent);
});
