import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radiov2_android/core/database/app_database.dart';
import 'package:sqlite3/open.dart';

void main() {
  if (Platform.isWindows) {
    final dll =
        Platform.environment['SQLITE3_DLL'] ?? r'C:\Python314\DLLs\sqlite3.dll';
    if (File(dll).existsSync()) {
      open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open(dll));
    }
  }
  test('featured stays pinned; ordinary logos precede missing art across pages',
      () async {
    final directory = Directory.systemTemp.createTempSync('radio_order_');
    final db = AppDatabase(File('${directory.path}/test.db'));
    try {
      final group =
          await db.into(db.groups).insert(GroupsCompanion.insert(name: 'Test'));
      Future<int> add(String name, String? logo, bool featured) =>
          db.into(db.stations).insert(StationsCompanion.insert(
              name: name,
              streamUrl: 'https://example.test/$name',
              groupId: group,
              logoUrl: Value(logo),
              isFeatured: Value(featured)));
      final featuredLogo =
          await add('Z featured logo', 'https://example.test/a.png', true);
      final featuredMissing = await add('A featured missing', null, true);
      final normalLogo =
          await add('B normal logo', 'https://example.test/b.png', false);
      final blankFeatured = await add('C blank featured', '   ', true);
      final blankOrdinary = await add('A blank ordinary', '   ', false);
      final normalMissing = await add('D normal missing', '', false);
      final failedLogo =
          await add('AA forbidden', 'https://test/forbidden.ico', false);
      final unsupportedLogo =
          await add('AB unsupported', 'https://test/logo.SVG?q=1', false);
      final featured = await db.stationDao.getFeaturedByGroup(group);
      final pageOne = await db.stationDao.getStationsByGroup(group, 0, 2,
          unavailableArtworkUrls: {'https://test/forbidden.ico'});
      final pageTwo = await db.stationDao.getStationsByGroup(group, 2, 4,
          unavailableArtworkUrls: {'https://test/forbidden.ico'});
      final ids =
          [...featured, ...pageOne, ...pageTwo].map((s) => s.id).toList();
      expect(featured.map((s) => s.id),
          [featuredLogo, featuredMissing, blankFeatured]);
      expect(pageOne.first.id, normalLogo);
      expect(ids.toSet(), {
        featuredLogo,
        featuredMissing,
        normalLogo,
        blankFeatured,
        normalMissing,
        blankOrdinary,
        failedLogo,
        unsupportedLogo
      });
      expect(ids.length, 8,
          reason:
              'Pagination must neither omit nor duplicate featured stations without art.');
      final searched = await db.stationDao
          .getStationsByGroup(group, 0, 30, query: 'featured');
      expect(searched.map((s) => s.id),
          containsAll([featuredMissing, blankFeatured]));
    } finally {
      await db.close();
      directory.deleteSync(recursive: true);
    }
  });
}
