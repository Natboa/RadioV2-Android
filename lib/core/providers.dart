import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart';
import 'data/repository/station_repository.dart';
import 'data/repository/station_repository_impl.dart';
import 'data/repository/favourite_repository.dart';
import 'data/repository/favourite_repository_impl.dart';

// Provided via ProviderScope override in main.dart after DB init
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden in main');
});

final stationRepositoryProvider = Provider<StationRepository>(
  (ref) => StationRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final favouriteRepositoryProvider = Provider<FavouriteRepository>(
  (ref) => FavouriteRepositoryImpl(ref.watch(appDatabaseProvider)),
);
