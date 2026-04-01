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
    final groupList = await getGroupsByCategory(categoryId);
    final result = <GroupWithCount>[];
    for (final group in groupList) {
      final count = await (selectOnly(stations)
            ..addColumns([stations.id.count()])
            ..where(stations.groupId.equals(group.id)))
          .map((row) => row.read(stations.id.count()) ?? 0)
          .getSingle();
      result.add(GroupWithCount(group: group, stationCount: count));
    }
    return result;
  }

  Future<Group?> getGroupById(int id) {
    return (select(groups)..where((g) => g.id.equals(id))).getSingleOrNull();
  }
}
