import '../../model/station.dart';
import '../../model/group.dart';
import '../../model/category.dart';

abstract interface class StationRepository {
  Future<List<Station>> searchStations(String query, int offset, int limit);

  Future<List<Station>> getStationsByGroup(
    int groupId,
    int offset,
    int limit, {
    String? query,
  });

  Future<List<Station>> getFeaturedByGroup(int groupId);

  Future<Station?> getStationById(int id);

  Future<List<Group>> getGroupsWithCountByCategory(int categoryId);

  Future<List<CategoryWithGroups>> getAllCategoriesWithGroups();

  /// Returns a map of streamUrl → stationId for all matching URLs found in the DB.
  Future<Map<String, int>> getStationIdsByStreamUrls(List<String> urls);
}
