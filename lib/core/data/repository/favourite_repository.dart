import '../../model/station.dart';

abstract interface class FavouriteRepository {
  Stream<List<Station>> watchFavourites();
  Future<List<Station>> getFavourites();
  Stream<bool> watchIsFavourite(int stationId);
  Future<void> toggleFavourite(int stationId);
  Future<void> addFavourite(int stationId);
}
