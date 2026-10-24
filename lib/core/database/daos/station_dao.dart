import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/station_table.dart';

part 'station_dao.g.dart';

@DriftAccessor(tables: [Stations, Groups, Favourites])
class StationDao extends DatabaseAccessor<AppDatabase> with _$StationDaoMixin {
  StationDao(super.db);

  Expression<bool> _hasLogo(Stations s, Set<String> unavailable) {
    final url = s.logoUrl.trim();
    // LIKE is ASCII case-insensitive. Only run suffix checks for the rare SVG
    // candidates, instead of repeatedly normalising every URL in a large group.
    final supported = CaseWhenExpression<bool>(cases: [
      CaseWhen(s.logoUrl.like('%.svg%'),
          then: s.logoUrl.like('%.svg').not() &
              s.logoUrl.like('%.svg?%').not() &
              s.logoUrl.like('%.svg#%').not()),
    ], orElse: const Constant(true));
    return s.logoUrl.isNotNull() &
        url.isNotValue('') &
        supported &
        (unavailable.isEmpty ? const Constant(true) : url.isNotIn(unavailable));
  }

  Future<List<Station>> searchStations(
    String query,
    int offset,
    int limit,
  ) {
    final q = '%${query.toLowerCase()}%';
    return (select(stations)
          ..where((s) => s.name.lower().like(q))
          ..orderBy([(s) => OrderingTerm.asc(s.name)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<Station>> getStationsByGroup(
    int groupId,
    int offset,
    int limit, {
    String? query,
    Set<String> unavailableArtworkUrls = const {},
  }) {
    return (select(stations)
          ..where((s) {
            final byGroup = s.groupId.equals(groupId);
            if (query != null && query.isNotEmpty) {
              return byGroup & s.name.lower().like('%${query.toLowerCase()}%');
            }
            // Keep featured pinned separately; ordinary logos precede missing
            // or blank artwork across the entire paginated remainder.
            return byGroup & s.isFeatured.isValue(false);
          })
          ..orderBy([
            (s) => OrderingTerm(
                  expression: _hasLogo(s, unavailableArtworkUrls),
                  mode: OrderingMode.desc,
                ),
            (s) => OrderingTerm.asc(s.name),
            (s) => OrderingTerm.asc(s.id),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<Station>> getFeaturedByGroup(int groupId,
      {Set<String> unavailableArtworkUrls = const {}}) {
    return (select(stations)
          ..where((s) => s.groupId.equals(groupId) & s.isFeatured.isValue(true))
          ..orderBy([
            (s) => OrderingTerm(
                  expression: _hasLogo(s, unavailableArtworkUrls),
                  mode: OrderingMode.desc,
                ),
            (s) => OrderingTerm.asc(s.name),
            (s) => OrderingTerm.asc(s.id),
          ]))
        .get();
  }

  Future<Station?> getStationById(int id) {
    return (select(stations)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  /// Returns a map of streamUrl → stationId for all URLs that exist in the DB.
  Future<Map<String, int>> getStationIdsByStreamUrls(List<String> urls) async {
    if (urls.isEmpty) return {};
    final rows =
        await (select(stations)..where((s) => s.streamUrl.isIn(urls))).get();
    return {for (final r in rows) r.streamUrl: r.id};
  }
}
