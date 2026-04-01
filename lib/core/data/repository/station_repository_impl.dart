import '../../database/app_database.dart' as db;
import '../../model/station.dart';
import '../../model/group.dart';
import '../../model/category.dart';
import 'station_repository.dart';

class StationRepositoryImpl implements StationRepository {
  final db.AppDatabase _db;

  StationRepositoryImpl(this._db);

  @override
  Future<List<Station>> searchStations(
    String query,
    int offset,
    int limit,
  ) async {
    final rows = await _db.stationDao.searchStations(query, offset, limit);
    return rows.map(_mapStation).toList();
  }

  @override
  Future<List<Station>> getStationsByGroup(
    int groupId,
    int offset,
    int limit, {
    String? query,
  }) async {
    final rows = await _db.stationDao.getStationsByGroup(
      groupId,
      offset,
      limit,
      query: query,
    );
    return rows.map(_mapStation).toList();
  }

  @override
  Future<List<Station>> getFeaturedByGroup(int groupId) async {
    final rows = await _db.stationDao.getFeaturedByGroup(groupId);
    return rows.map(_mapStation).toList();
  }

  @override
  Future<Station?> getStationById(int id) async {
    final row = await _db.stationDao.getStationById(id);
    return row == null ? null : _mapStation(row);
  }

  @override
  Future<List<Group>> getGroupsWithCountByCategory(int categoryId) async {
    final rows = await _db.groupDao.getGroupsWithCountByCategory(categoryId);
    return rows
        .map(
          (gwc) => Group(
            id: gwc.group.id,
            name: gwc.group.name,
            categoryId: gwc.group.categoryId,
            stationCount: gwc.stationCount,
          ),
        )
        .toList();
  }

  @override
  Future<List<CategoryWithGroups>> getAllCategoriesWithGroups() async {
    final cats = await _db.categoryDao.getAllCategories();
    final result = <CategoryWithGroups>[];
    for (final cat in cats) {
      final groups = await getGroupsWithCountByCategory(cat.id);
      result.add(
        CategoryWithGroups(
          category: Category(
            id: cat.id,
            name: cat.name,
            displayOrder: cat.displayOrder,
          ),
          groups: groups,
        ),
      );
    }
    return result;
  }

  Station _mapStation(db.Station row) => Station(
    id: row.id,
    name: row.name,
    streamUrl: row.streamUrl,
    logoUrl: row.logoUrl,
    groupId: row.groupId,
    isFeatured: row.isFeatured,
  );
}
