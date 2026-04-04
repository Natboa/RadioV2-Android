import '../../database/app_database.dart' as db;
import '../../model/station.dart';
import 'favourite_repository.dart';

class FavouriteRepositoryImpl implements FavouriteRepository {
  final db.AppDatabase _database;

  FavouriteRepositoryImpl(this._database);

  @override
  Stream<List<Station>> watchFavourites() {
    return _database.favouriteDao.watchFavouriteStations().map(
      (rows) =>
          rows
              .map(
                (row) => Station(
                  id: row.id,
                  name: row.name,
                  streamUrl: row.streamUrl,
                  logoUrl: row.logoUrl,
                  groupId: row.groupId,
                  isFeatured: row.isFeatured,
                  isFavourite: true,
                ),
              )
              .toList(),
    );
  }

  @override
  Future<List<Station>> getFavourites() async {
    final rows = await _database.favouriteDao.watchFavouriteStations().first;
    return rows
        .map(
          (row) => Station(
            id: row.id,
            name: row.name,
            streamUrl: row.streamUrl,
            logoUrl: row.logoUrl,
            groupId: row.groupId,
            isFeatured: row.isFeatured,
            isFavourite: true,
          ),
        )
        .toList();
  }

  @override
  Stream<bool> watchIsFavourite(int stationId) {
    return _database.favouriteDao.watchIsFavourite(stationId);
  }

  @override
  Future<void> toggleFavourite(int stationId) async {
    final isFav = await _database.favouriteDao.isFavourite(stationId);
    if (isFav) {
      await _database.favouriteDao.removeFavourite(stationId);
    } else {
      await _database.favouriteDao.addFavourite(stationId);
    }
  }

  @override
  Future<void> addFavourite(int stationId) =>
      _database.favouriteDao.addFavourite(stationId);
}
