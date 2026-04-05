import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/station_table.dart';

part 'favourite_dao.g.dart';

@DriftAccessor(tables: [Favourites, Stations])
class FavouriteDao extends DatabaseAccessor<AppDatabase>
    with _$FavouriteDaoMixin {
  FavouriteDao(super.db);

  Stream<List<Station>> watchFavouriteStations() {
    final query = select(stations).join([
      innerJoin(favourites, favourites.stationId.equalsExp(stations.id)),
    ]);
    query.orderBy([OrderingTerm.asc(stations.name)]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(stations)).toList(),
    );
  }

  Future<bool> isFavourite(int stationId) async {
    final result = await (select(favourites)
          ..where((f) => f.stationId.equals(stationId)))
        .getSingleOrNull();
    return result != null;
  }

  Future<void> addFavourite(int stationId) async {
    await into(favourites).insert(
      FavouritesCompanion.insert(stationId: stationId),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> removeFavourite(int stationId) async {
    await (delete(favourites)
          ..where((f) => f.stationId.equals(stationId)))
        .go();
  }

  Stream<bool> watchIsFavourite(int stationId) {
    return (select(favourites)
          ..where((f) => f.stationId.equals(stationId)))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }
}
