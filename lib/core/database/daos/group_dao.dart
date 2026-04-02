import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/station_table.dart';

part 'group_dao.g.dart';

class GroupWithCount {
  final Group group;
  final int stationCount;

  const GroupWithCount({required this.group, required this.stationCount});
}

@DriftAccessor(tables: [Groups, Stations])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(super.db);

  Future<List<Group>> getGroupsByCategory(int categoryId) {
    return (select(groups)
          ..where((g) => g.categoryId.equals(categoryId))
          ..orderBy([(g) => OrderingTerm.asc(g.name)]))
        .get();
  }

  Future<List<GroupWithCount>> getGroupsWithCountByCategory(
    int categoryId,
  ) async {
    final all = await getAllGroupsWithCount();
    return all.where((g) => g.group.categoryId == categoryId).toList();
  }

  /// Single LEFT JOIN query — returns every group with its station count.
  Future<List<GroupWithCount>> getAllGroupsWithCount() async {
    final countCol = stations.id.count();
    final rows = await (select(groups).join([
      leftOuterJoin(stations, stations.groupId.equalsExp(groups.id)),
    ])
          ..addColumns([countCol])
          ..groupBy([groups.id])
          ..orderBy([OrderingTerm.asc(groups.name)]))
        .get();
    return rows
        .map(
          (row) => GroupWithCount(
            group: row.readTable(groups),
            stationCount: row.read(countCol) ?? 0,
          ),
        )
        .toList();
  }

  Future<Group?> getGroupById(int id) {
    return (select(groups)..where((g) => g.id.equals(id))).getSingleOrNull();
  }
}
