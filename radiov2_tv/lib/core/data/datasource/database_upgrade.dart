import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../database/favourites_ddl.dart';

/// Puts the bundled station database in place on first launch and replaces it
/// after an app update, without losing the user's favourites.
///
/// Favourites live inside the very file that is replaced, so the order of
/// operations is what keeps them safe:
///  1. read favourites from the old DB, keyed by stream URL (station ids are
///     not a stable identity across catalogue rebuilds). A normal open also
///     replays any write-ahead log left behind when Android killed the app;
///  2. save them to SharedPreferences as "pending" BEFORE touching the file;
///  3. write the new DB to a temp file, delete the old -wal/-shm/-journal
///     (replaying a stale WAL onto a different database corrupts it), then
///     rename the temp file into place;
///  4. record the app version;
///  5. insert the pending favourites into the new DB, then clear "pending".
///
/// Every step can be interrupted. The next launch resumes from whatever is
/// durable, so a favourite is only lost when its station is no longer in the
/// bundled catalogue. Nothing here may throw on bad data: a failure to read or
/// restore favourites must never stop the app from starting.
class DatabaseUpgrade {
  static const dbFileName = 'stations.db';
  static const versionKey = 'last_db_app_version';
  static const pendingFavouritesKey = 'favourite_urls_pending_restore';

  /// [onStep] is called after each durable step ('backupWritten',
  /// 'fileReplaced', 'versionWritten', 'restored'); tests use it to simulate
  /// the process dying at that point.
  static Future<File> ensureDatabase({
    required Directory dir,
    required Future<Uint8List> Function() loadAsset,
    required String appVersion,
    required SharedPreferences prefs,
    void Function(String step)? onStep,
  }) async {
    final dbFile = File(p.join(dir.path, dbFileName));
    final needsReplace =
        !dbFile.existsSync() || prefs.getString(versionKey) != appVersion;

    if (needsReplace) {
      final hadDb = dbFile.existsSync();
      final priorPending = prefs.getStringList(pendingFavouritesKey);
      if (hadDb) {
        // Union with any list left by an interrupted earlier attempt: after
        // such a crash the file on disk is already the new, favourite-less DB.
        final pending = <String>{
          ...?priorPending,
          ..._readFavouriteUrls(dbFile),
        };
        if (pending.isNotEmpty) {
          await prefs.setStringList(pendingFavouritesKey, pending.toList());
        }
      }
      onStep?.call('backupWritten');

      try {
        await _replace(dbFile, await loadAsset());
      } catch (e) {
        // Typically a full disk: the temp copy needs room for a second DB.
        // The old file is untouched, so keep running on it and retry on the
        // next launch (the version is not recorded).
        debugPrint('DatabaseUpgrade: could not install the new database: $e');
        final tmp = File('${dbFile.path}.tmp');
        if (tmp.existsSync()) tmp.deleteSync();
        if (!hadDb) rethrow; // fresh install: there is nothing to run on
        if (priorPending == null) {
          await prefs.remove(pendingFavouritesKey);
        } else {
          await prefs.setStringList(pendingFavouritesKey, priorPending);
        }
        return dbFile;
      }
      onStep?.call('fileReplaced');

      await prefs.setString(versionKey, appVersion);
      onStep?.call('versionWritten');
    }

    final pending = prefs.getStringList(pendingFavouritesKey);
    if (pending != null) {
      var restored = false;
      try {
        _restoreFavourites(dbFile, pending);
        restored = true;
      } catch (e) {
        // Keep the list queued; the next launch tries again.
        debugPrint('DatabaseUpgrade: favourites not restored yet: $e');
      }
      if (restored) {
        onStep?.call('restored');
        await prefs.remove(pendingFavouritesKey);
      }
    }

    return dbFile;
  }

  /// Favourite stream URLs in the order they were added. Empty (never throws)
  /// if the file is missing the table, unreadable or damaged.
  static List<String> _readFavouriteUrls(File dbFile) {
    Database? db;
    try {
      db = sqlite3.open(dbFile.path);
      final hasTable = db
          .select(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name='favourites'",
          )
          .isNotEmpty;
      if (!hasTable) return const [];
      // Joining from favourites keeps this a handful of primary-key lookups
      // instead of a scan of the 139k-row stations table.
      final rows = db.select(
        'SELECT s.StreamUrl AS u FROM favourites f '
        'JOIN Stations s ON s.Id = f.station_id ORDER BY f.id',
      );
      return [for (final r in rows) r['u'] as String];
    } catch (e) {
      debugPrint('DatabaseUpgrade: could not read favourites from old DB: $e');
      return const [];
    } finally {
      db?.dispose();
    }
  }

  static Future<void> _replace(File dbFile, Uint8List bytes) async {
    final tmp = File('${dbFile.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    if (tmp.lengthSync() != bytes.length) {
      tmp.deleteSync();
      throw FileSystemException('Incomplete copy of the bundled database', tmp.path);
    }
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final f = File('${dbFile.path}$suffix');
      if (f.existsSync()) f.deleteSync();
    }
    await tmp.rename(dbFile.path);
  }

  static void _restoreFavourites(File dbFile, List<String> urls) {
    final db = sqlite3.open(dbFile.path);
    try {
      db.execute(favouritesTableDdl);
      // The station id always comes from the new catalogue, so a station that
      // no longer exists is simply skipped and the foreign key cannot fail.
      final insert = db.prepare(
        'INSERT OR IGNORE INTO favourites (station_id) '
        'SELECT Id FROM Stations WHERE StreamUrl = ?',
      );
      try {
        db.execute('BEGIN');
        try {
          for (final url in urls) {
            insert.execute([url]);
          }
          db.execute('COMMIT');
        } catch (_) {
          db.execute('ROLLBACK');
          rethrow;
        }
      } finally {
        insert.dispose();
      }
    } finally {
      db.dispose();
    }
  }
}
