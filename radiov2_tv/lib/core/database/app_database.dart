import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'tables/station_table.dart';
import 'daos/station_dao.dart';
import 'daos/group_dao.dart';
import 'daos/category_dao.dart';
import 'daos/favourite_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Stations, Groups, Categories, Favourites],
  daos: [StationDao, GroupDao, CategoryDao, FavouriteDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(File dbFile) : super(NativeDatabase.createInBackground(dbFile));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Ensure the Favourites table exists (not in the original bundled DB)
      await customStatement('''
        CREATE TABLE IF NOT EXISTS favourites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          station_id INTEGER NOT NULL UNIQUE REFERENCES stations(id)
        )
      ''');
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
