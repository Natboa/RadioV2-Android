import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/station_table.dart';

part 'station_dao.g.dart';

@DriftAccessor(tables: [Stations, Groups, Favourites])
class StationDao extends DatabaseAccessor<AppDatabase>
    with _$StationDaoMixin {
  StationDao(super.db);

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
  }) {
    return (select(stations)
          ..where((s) {
            final byGroup = s.groupId.equals(groupId);
            if (query != null && query.isNotEmpty) {
              return byGroup & s.name.lower().like('%${query.toLowerCase()}%');
            }
            return byGroup;
          })
          ..orderBy([(s) => OrderingTerm.asc(s.name)])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<Station>> getFeaturedByGroup(int groupId) {
    return (select(stations)
          ..where((s) => s.groupId.equals(groupId) & s.isFeatured.isValue(true))
          ..orderBy([(s) => OrderingTerm.asc(s.name)]))
        .get();
  }

  Future<Station?> getStationById(int id) {
    return (select(stations)..where((s) => s.id.equals(id))).getSingleOrNull();
  }
}
