import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database/app_database.dart' hide Station;
import 'data/datasource/database_initializer.dart';
import 'data/repository/station_repository.dart';
import 'data/repository/station_repository_impl.dart';
import 'data/repository/favourite_repository.dart';
import 'data/repository/favourite_repository_impl.dart';
import 'model/station.dart';

/// Async provider — copies the 79MB DB on first launch in the background,
/// after runApp() has already shown the UI.
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final dbFile = await DatabaseInitializer.getOrCopyDatabase();
  return AppDatabase(dbFile);
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return StationRepositoryImpl(db);
});

final favouriteRepositoryProvider = Provider<FavouriteRepository>((ref) {
  final db = ref.watch(appDatabaseProvider).requireValue;
  return FavouriteRepositoryImpl(db);
});

/// In-memory list of recently played stations (most recent first, max 50).
final recentlyVisitedProvider = StateProvider<List<Station>>(
  (ref) => const [],
);
