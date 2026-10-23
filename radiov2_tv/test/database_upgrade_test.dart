import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:radiov2_tv/core/data/datasource/database_upgrade.dart';
import 'package:radiov2_tv/core/database/app_database.dart';
import 'package:radiov2_tv/core/database/favourites_ddl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

// Same schema as assets/database/stations.db (without the favourites table,
// which the app adds itself).
const _schema = '''
CREATE TABLE Groups (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL UNIQUE, CategoryId INTEGER REFERENCES Categories(Id));
CREATE TABLE Stations (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, StreamUrl TEXT NOT NULL UNIQUE, LogoUrl TEXT, GroupId INTEGER NOT NULL REFERENCES Groups(Id), IsFavorite INTEGER NOT NULL DEFAULT 0, IsFeatured INTEGER NOT NULL DEFAULT 0);
CREATE TABLE Settings (Key TEXT PRIMARY KEY, Value TEXT NOT NULL);
CREATE TABLE Categories (Id INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, DisplayOrder INTEGER NOT NULL DEFAULT 0);
CREATE INDEX idx_stations_groupid ON Stations(GroupId);
''';

String urlOf(int id) => 'http://stream$id.example.com/live';
String nameOf(int id) => 'Station number $id ${'x' * 60}';

void main() {
  // On a Windows dev machine there is no system libsqlite3; point at any
  // sqlite3.dll (e.g. SQLITE3_DLL, or the one that ships with Python).
  if (Platform.isWindows) {
    final dll =
        Platform.environment['SQLITE3_DLL'] ?? r'C:\Python314\DLLs\sqlite3.dll';
    if (File(dll).existsSync()) {
      open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open(dll));
    }
  }
  String? skip;
  try {
    sqlite3.version;
  } catch (_) {
    skip = 'sqlite3 native library not available on this machine';
  }

  late Directory tmp;
  late File oldAsset; // what the phone has been running (1..1500)
  late File newAsset; // what the new release ships (some removed, some added)

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('radiov2_upgrade_');
    oldAsset = _buildCatalogue(File('${tmp.path}/old_asset.db'), [
      for (var i = 1; i <= 1500; i++) i,
    ]);
    newAsset = _buildCatalogue(File('${tmp.path}/new_asset.db'), [
      for (var i = 1; i <= 1500; i++)
        if (i != 7 && i != 99 && i != 450) i, // 7, 99, 450 were removed
      for (var i = 2000; i <= 3200; i++) i, // new stations
    ]);
  });

  tearDown(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<SharedPreferences> prefsWith(Map<String, Object> initial) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues(initial);
    return SharedPreferences.getInstance();
  }

  Future<File> upgrade(
    Directory app,
    SharedPreferences prefs, {
    File? asset,
    String version = '1.0.7',
    void Function(String step)? onStep,
  }) {
    final source = asset ?? newAsset;
    return DatabaseUpgrade.ensureDatabase(
      dir: app,
      loadAsset: () async => source.readAsBytesSync(),
      appVersion: version,
      prefs: prefs,
      onStep: onStep,
    );
  }

  List<String> urls(Iterable<int> ids) => ([for (final i in ids) urlOf(i)]..sort());

  group('the bug this guards against', () {
    test(
      'control: v1.0.6 overwrote only the main file; on this fixture that damages the database',
      () {
        final app = _killedOldApp(tmp, oldAsset, [5, 20, 1000]);
        // v1.0.6 behaviour: write the new file over stations.db, leave -wal/-shm.
        File('${app.path}/stations.db').writeAsBytesSync(newAsset.readAsBytesSync());

        final f = File('${app.path}/stations.db');
        final integrity = _integrity(f);
        final restored = _favouriteUrls(f);
        // Damage shows up as a failed integrity check and/or favourites that
        // no longer match what the user saved.
        expect(
          integrity != 'ok' || restored.join() != urls([5, 20, 1000]).join(),
          isTrue,
          reason: 'integrity=$integrity favourites=$restored',
        );
      },
      skip: skip,
    );
  });

  group('DatabaseUpgrade.ensureDatabase', () {
    test('fresh install copies the bundled DB and records the version', () async {
      final app = Directory('${tmp.path}/app')..createSync();
      final prefs = await prefsWith({});
      final f = await upgrade(app, prefs);

      expect(f.lengthSync(), newAsset.lengthSync());
      expect(prefs.getString(DatabaseUpgrade.versionKey), '1.0.7');
      expect(prefs.getStringList(DatabaseUpgrade.pendingFavouritesKey), isNull);
      expect(_integrity(f), 'ok');
    }, skip: skip);

    test('same version: does not touch the database or load the asset', () async {
      final app = Directory('${tmp.path}/app')..createSync();
      final prefs = await prefsWith({});
      final f = await upgrade(app, prefs);
      final before = f.readAsBytesSync();

      var loads = 0;
      await DatabaseUpgrade.ensureDatabase(
        dir: app,
        loadAsset: () async {
          loads++;
          return Uint8List(0);
        },
        appVersion: '1.0.7',
        prefs: prefs,
      );
      expect(loads, 0);
      expect(f.readAsBytesSync(), before);
    }, skip: skip);

    test('upgrade keeps favourites (matched by stream URL) even with a stale WAL', () async {
      final app = _killedOldApp(tmp, oldAsset, [5, 20, 1000]);
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await upgrade(app, prefs);

      expect(File('${f.path}-wal').existsSync(), isFalse, reason: 'old WAL must not survive');
      expect(_integrity(f), 'ok');
      expect(_favouriteUrls(f), urls([5, 20, 1000]));
      expect(prefs.getString(DatabaseUpgrade.versionKey), '1.0.7');
      expect(prefs.getStringList(DatabaseUpgrade.pendingFavouritesKey), isNull);
    }, skip: skip);

    test('upgrade from a build that never wrote a version pref (<= 1.0.5) also keeps favourites', () async {
      final app = _killedOldApp(tmp, oldAsset, [5, 20]);
      final prefs = await prefsWith({});

      final f = await upgrade(app, prefs);

      expect(_integrity(f), 'ok');
      expect(_favouriteUrls(f), urls([5, 20]));
    }, skip: skip);

    test('a favourite whose station was removed is dropped; startup does not throw', () async {
      final app = _killedOldApp(tmp, oldAsset, [5, 7, 99, 20, 450]);
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await upgrade(app, prefs);

      expect(_favouriteUrls(f), urls([5, 20])); // 7, 99, 450 no longer exist
      expect(_integrity(f), 'ok');
      expect(prefs.getStringList(DatabaseUpgrade.pendingFavouritesKey), isNull);
    }, skip: skip);

    test('ids that were re-assigned in the new catalogue: favourites follow the URL, not the id', () async {
      // New catalogue where station Id n carries the URL that Id n+1 had before.
      final shifted = _buildCatalogue(
        File('${tmp.path}/shifted.db'),
        [for (var i = 1; i <= 1500; i++) i],
        url: (id) => urlOf(id + 1),
      );
      final app = _killedOldApp(tmp, oldAsset, [5, 20]);
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await upgrade(app, prefs, asset: shifted);

      expect(_favouriteUrls(f), urls([5, 20]));
      final db = sqlite3.open(f.path);
      try {
        // The saved stations now live at ids 4 and 19.
        final ids = db
            .select('SELECT station_id FROM favourites ORDER BY station_id')
            .map((r) => r['station_id'] as int)
            .toList();
        expect(ids, [4, 19]);
      } finally {
        db.dispose();
      }
    }, skip: skip);

    test('phantom favourite ids (left by a database 1.0.6 already damaged) are not mapped onto unrelated stations', () async {
      // 3000 does not exist in the old catalogue but is a real, different
      // station in the new one.
      final app = _killedOldApp(tmp, oldAsset, [5], phantomIds: [3000]);
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await upgrade(app, prefs);

      expect(_favouriteUrls(f), urls([5]));
    }, skip: skip);

    for (final step in ['backupWritten', 'fileReplaced', 'versionWritten', 'restored']) {
      test('process killed right after "$step": the next launch still ends with the favourites restored', () async {
        final app = _killedOldApp(tmp, oldAsset, [5, 7, 20]);
        final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

        await expectLater(
          upgrade(app, prefs, onStep: (s) {
            if (s == step) throw StateError('simulated process death at $s');
          }),
          throwsA(isA<StateError>()),
        );

        final f = await upgrade(app, prefs); // the next launch

        expect(File('${f.path}-wal').existsSync(), isFalse);
        expect(_integrity(f), 'ok');
        expect(_favouriteUrls(f), urls([5, 20]));
        expect(prefs.getString(DatabaseUpgrade.versionKey), '1.0.7');
        expect(prefs.getStringList(DatabaseUpgrade.pendingFavouritesKey), isNull);
      }, skip: skip);
    }

    test('an unreadable old database does not block startup and is replaced', () async {
      final app = Directory('${tmp.path}/app')..createSync();
      File('${app.path}/stations.db').writeAsBytesSync(Uint8List.fromList(List.filled(4096, 7)));
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await upgrade(app, prefs);

      expect(_integrity(f), 'ok');
      expect(_favouriteUrls(f), isEmpty);
      expect(prefs.getString(DatabaseUpgrade.versionKey), '1.0.7');
    }, skip: skip);

    test('a leftover -wal next to an unreadable old database is not replayed onto the new one', () async {
      // Reading a healthy old DB removes its WAL on close; here the main file
      // is unreadable, so only the explicit cleanup stands between the stale
      // WAL and the new database.
      final app = _killedOldApp(tmp, oldAsset, [5, 20]);
      File('${app.path}/stations.db')
          .writeAsBytesSync(Uint8List.fromList(List.filled(4096, 7)));
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await upgrade(app, prefs);

      expect(File('${f.path}-wal').existsSync(), isFalse);
      expect(_integrity(f), 'ok');
      expect(_favouriteUrls(f), isEmpty);
      expect(_stationCount(f), _stationCount(newAsset)); // exactly the bundled catalogue
    }, skip: skip);

    test('an old database that never had a favourites table upgrades cleanly', () async {
      final app = Directory('${tmp.path}/app')..createSync();
      oldAsset.copySync('${app.path}/stations.db');
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await upgrade(app, prefs);

      expect(_integrity(f), 'ok');
      expect(_favouriteUrls(f), isEmpty);
    }, skip: skip);

    test('if restoring fails, startup still succeeds and the favourites stay queued for the next launch', () async {
      final app = _killedOldApp(tmp, oldAsset, [5, 20]);
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});
      final broken = File('${tmp.path}/broken_asset.db');
      final db = sqlite3.open(broken.path);
      db.execute('CREATE TABLE Unrelated (x INTEGER)'); // no Stations table
      db.dispose();

      final f = await upgrade(app, prefs, asset: broken);

      expect(f.existsSync(), isTrue);
      expect(
        prefs.getStringList(DatabaseUpgrade.pendingFavouritesKey)!.toList()..sort(),
        urls([5, 20]),
      );

      // A later launch with a good catalogue restores them.
      final fixed = await upgrade(app, prefs, version: '1.0.8');
      expect(_favouriteUrls(fixed), urls([5, 20]));
      expect(prefs.getStringList(DatabaseUpgrade.pendingFavouritesKey), isNull);
    }, skip: skip);

    test('if the new database cannot be written (e.g. disk full), the old one keeps working and the upgrade is retried next launch', () async {
      final app = _killedOldApp(tmp, oldAsset, [5, 20]);
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await DatabaseUpgrade.ensureDatabase(
        dir: app,
        loadAsset: () async => throw const FileSystemException('No space left on device'),
        appVersion: '1.0.7',
        prefs: prefs,
      );

      expect(f.existsSync(), isTrue);
      expect(File('${f.path}.tmp').existsSync(), isFalse, reason: 'no half-written temp file left behind');
      expect(prefs.getString(DatabaseUpgrade.versionKey), '1.0.6', reason: 'not recorded, so it retries');
      expect(prefs.getStringList(DatabaseUpgrade.pendingFavouritesKey), isNull,
          reason: 'old file still holds the favourites; a stale list would resurrect removed ones');
      expect(_stationCount(f), _stationCount(oldAsset)); // still the old catalogue
      expect(_favouriteUrls(f), urls([5, 20]));

      final retry = await upgrade(app, prefs); // space freed up
      expect(_stationCount(retry), _stationCount(newAsset));
      expect(_favouriteUrls(retry), urls([5, 20]));
      expect(prefs.getString(DatabaseUpgrade.versionKey), '1.0.7');
    }, skip: skip);

    test('a failed copy on a fresh install is reported (there is nothing to run on)', () async {
      final app = Directory('${tmp.path}/app')..createSync();
      final prefs = await prefsWith({});

      await expectLater(
        DatabaseUpgrade.ensureDatabase(
          dir: app,
          loadAsset: () async => throw const FileSystemException('No space left on device'),
          appVersion: '1.0.7',
          prefs: prefs,
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(prefs.getString(DatabaseUpgrade.versionKey), isNull);
    }, skip: skip);

    test('hundreds of favourites are all restored', () async {
      final ids = [for (var i = 1; i <= 1500; i += 3) i]; // 500 favourites
      final app = _killedOldApp(tmp, oldAsset, ids);
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});

      final f = await upgrade(app, prefs);

      final expected = ids.where((i) => i != 7 && i != 99 && i != 450);
      expect(_favouriteUrls(f), urls(expected));
    }, skip: skip);

    test('the real Drift AppDatabase opens the upgraded file and reads/writes favourites', () async {
      final app = _killedOldApp(tmp, oldAsset, [5, 20]);
      final prefs = await prefsWith({DatabaseUpgrade.versionKey: '1.0.6'});
      final f = await upgrade(app, prefs);

      final db = AppDatabase(f);
      try {
        final favs = await db.favouriteDao.watchFavouriteStations().first;
        expect(favs.map((s) => s.streamUrl).toList()..sort(), urls([5, 20]));

        await db.favouriteDao.addFavourite(2100); // FK is on; id exists
        expect(await db.favouriteDao.isFavourite(2100), isTrue);
      } finally {
        await db.close();
      }
    }, skip: skip);
  });
}

File _buildCatalogue(File f, Iterable<int> ids, {String Function(int)? url}) {
  final db = sqlite3.open(f.path);
  try {
    db.execute('PRAGMA journal_mode=WAL');
    db.execute(_schema);
    db.execute("INSERT INTO Categories (Id, Name) VALUES (1, 'c')");
    db.execute("INSERT INTO Groups (Id, Name, CategoryId) VALUES (1, 'g', 1)");
    final st = db.prepare(
      'INSERT INTO Stations (Id, Name, StreamUrl, GroupId) VALUES (?, ?, ?, 1)',
    );
    db.execute('BEGIN');
    for (final id in ids) {
      st.execute([id, nameOf(id), (url ?? urlOf)(id)]);
    }
    st.dispose();
    db.execute('COMMIT');
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
  } finally {
    db.dispose();
  }
  return f;
}

/// The device after the previous version ran and the process was killed:
/// stations.db plus a non-empty, un-checkpointed stations.db-wal.
Directory _killedOldApp(
  Directory tmp,
  File oldAsset,
  List<int> favouriteIds, {
  List<int> phantomIds = const [],
}) {
  final live = Directory('${tmp.path}/live')..createSync();
  final livePath = '${live.path}/stations.db';
  oldAsset.copySync(livePath);

  final db = sqlite3.open(livePath);
  db.execute(favouritesTableDdl);
  db.execute('PRAGMA foreign_keys = ON');
  for (final id in favouriteIds) {
    db.execute('INSERT OR IGNORE INTO favourites (station_id) VALUES (?)', [id]);
  }
  if (phantomIds.isNotEmpty) {
    db.execute('PRAGMA foreign_keys = OFF');
    for (final id in phantomIds) {
      db.execute('INSERT INTO favourites (station_id) VALUES (?)', [id]);
    }
  }

  final app = Directory('${tmp.path}/app')..createSync();
  for (final suffix in ['', '-wal', '-shm']) {
    final src = File(livePath + suffix);
    if (!src.existsSync()) continue;
    try {
      src.copySync('${app.path}/stations.db$suffix');
    } on FileSystemException {
      // -shm can be locked on Windows; it is only an index and is rebuilt.
    }
  }
  // Closing checkpoints the *live* copy only; `app` keeps the leftover WAL,
  // exactly as after Android kills the process.
  db.dispose();

  final wal = File('${app.path}/stations.db-wal');
  expect(wal.existsSync() && wal.lengthSync() > 0, isTrue,
      reason: 'fixture must leave a non-empty WAL behind');
  return app;
}

String _integrity(File f) {
  final db = sqlite3.open(f.path);
  try {
    return db.select('PRAGMA integrity_check').first.values.first as String;
  } catch (e) {
    return 'error: $e';
  } finally {
    db.dispose();
  }
}

int _stationCount(File f) {
  final db = sqlite3.open(f.path);
  try {
    return db.select('SELECT COUNT(*) AS n FROM Stations').first['n'] as int;
  } finally {
    db.dispose();
  }
}

List<String> _favouriteUrls(File f) {
  final db = sqlite3.open(f.path);
  try {
    final rows = db.select(
      'SELECT s.StreamUrl AS u FROM favourites f JOIN Stations s ON s.Id = f.station_id ORDER BY s.StreamUrl',
    );
    return rows.map((r) => r['u'] as String).toList();
  } on SqliteException {
    return <String>[];
  } finally {
    db.dispose();
  }
}
