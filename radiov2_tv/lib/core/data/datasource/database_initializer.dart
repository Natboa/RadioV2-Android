import 'dart:io';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

class DatabaseInitializer {
  static const _dbAssetPath = 'assets/database/stations.db';
  static const _dbFileName = 'stations.db';
  static const _prefKey = 'last_db_app_version';

  /// Returns the database file and a list of favourite station IDs that need
  /// to be restored (non-empty only when the DB was just replaced on upgrade).
  static Future<(File, List<int>)> getOrCopyDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, _dbFileName));
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();
    final currentVersion = info.version;
    final lastVersion = prefs.getString(_prefKey);

    // First install — copy and record version; no favourites to restore.
    if (!dbFile.existsSync()) {
      await _copyAssetDb(dbFile);
      await prefs.setString(_prefKey, currentVersion);
      return (dbFile, <int>[]);
    }

    // App updated — replace the DB and preserve the user's favourites.
    if (lastVersion != currentVersion) {
      final favouriteIds = _readFavouriteIds(dbFile.path);
      await _copyAssetDb(dbFile);
      await prefs.setString(_prefKey, currentVersion);
      return (dbFile, favouriteIds);
    }

    return (dbFile, <int>[]);
  }

  static Future<void> _copyAssetDb(File dest) async {
    final data = await rootBundle.load(_dbAssetPath);
    await dest.writeAsBytes(data.buffer.asUint8List(), flush: true);
  }

  /// Opens the old DB with raw sqlite3 and reads all favourite station_ids.
  /// Returns an empty list if the table doesn't exist yet.
  static List<int> _readFavouriteIds(String dbPath) {
    try {
      final db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
      try {
        final tableCheck = db.select(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='favourites'",
        );
        if (tableCheck.isEmpty) return [];
        final rows = db.select('SELECT station_id FROM favourites');
        return rows.map((r) => r['station_id'] as int).toList();
      } finally {
        db.dispose();
      }
    } catch (_) {
      return [];
    }
  }
}
