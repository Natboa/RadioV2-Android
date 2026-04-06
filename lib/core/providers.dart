import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database/app_database.dart' hide Station;

import 'data/repository/station_repository.dart';
import 'data/repository/station_repository_impl.dart';
import 'data/repository/favourite_repository.dart';
import 'data/repository/favourite_repository_impl.dart';
import 'model/station.dart';
import 'recently_visited_notifier.dart';

/// Overridden in main.dart with the real SharedPreferences instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider not overridden');
});

/// Overridden in main.dart with the initialized database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider not overridden');
});

final stationRepositoryProvider = Provider<StationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return StationRepositoryImpl(db);
});

final favouriteRepositoryProvider = Provider<FavouriteRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FavouriteRepositoryImpl(db);
});

/// Recently visited stations, persisted across app launches via SharedPreferences.
/// IDs are stored in prefs; full Station objects are loaded from the DB on startup.
final recentlyVisitedProvider =
    StateNotifierProvider<RecentlyVisitedNotifier, List<Station>>((ref) {
  return RecentlyVisitedNotifier(
    prefs: ref.watch(sharedPreferencesProvider),
    loader: (ids) async {
      final db = ref.read(appDatabaseProvider);
      final repo = StationRepositoryImpl(db);
      final stations = <Station>[];
      for (final id in ids) {
        final s = await repo.getStationById(id);
        if (s != null) stations.add(s);
      }
      return stations;
    },
  );
});
