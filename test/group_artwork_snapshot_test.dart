import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/open.dart';
import 'package:radiov2_android/core/database/app_database.dart';
import 'package:radiov2_android/core/data/repository/station_repository_impl.dart';
import 'package:radiov2_android/core/images/station_artwork_cache.dart';
import 'package:radiov2_android/core/providers.dart';
import 'package:radiov2_android/feature/discover/group_detail/group_detail_notifier.dart';
import 'package:radiov2_android/feature/discover/group_detail/group_detail_state.dart';

Future<GroupDetailSuccess> ready(GroupDetailNotifier notifier) async {
  if (notifier.state is GroupDetailSuccess) {
    return notifier.state as GroupDetailSuccess;
  }
  return await notifier.stream.firstWhere((s) => s is GroupDetailSuccess)
      as GroupDetailSuccess;
}

void main() {
  if (Platform.isWindows) {
    final dll =
        Platform.environment['SQLITE3_DLL'] ?? r'C:\Python314\DLLs\sqlite3.dll';
    if (File(dll).existsSync()) {
      open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open(dll));
    }
  }
  test(
      'late artwork failure never removes rows or changes offsets during a visit',
      () async {
    final directory = Directory.systemTemp.createTempSync('radio_snapshot_');
    final db = AppDatabase(File('${directory.path}/test.db'));
    GroupDetailNotifier? first;
    GroupDetailNotifier? reopened;
    try {
      final group =
          await db.into(db.groups).insert(GroupsCompanion.insert(name: 'Test'));
      for (var i = 0; i < 65; i++) {
        await db.into(db.stations).insert(StationsCompanion.insert(
            name: 'Station ${i.toString().padLeft(3, '0')}',
            streamUrl: 'https://stream/$i',
            logoUrl: Value('https://logo/$i.png'),
            groupId: group));
      }
      final cache = StationArtworkCache();
      final repository = StationRepositoryImpl(db);
      first = GroupDetailNotifier(repository, db, group,
          artworkFailures: () => cache.snapshot);
      final initial = await ready(first);
      expect(initial.stations.length, 30);
      final initialIds = initial.stations.map((s) => s.id).toList();
      cache.recordFailure('https://logo/4.png',
          const HttpExceptionWithStatus(403, 'forbidden'));
      await Future<void>.delayed(Duration.zero);
      expect(identical(first.state, initial), isTrue,
          reason:
              'No reactive sorting or row disappearance after an image error.');
      await first.loadMore();
      final paginated = first.state as GroupDetailSuccess;
      expect(paginated.stations.take(30).map((s) => s.id), initialIds);
      expect(paginated.stations.map((s) => s.id).toSet().length, 60);
      expect(paginated.stations.length, 60);
      reopened = GroupDetailNotifier(repository, db, group,
          artworkFailures: () => cache.snapshot);
      final nextVisit = await ready(reopened);
      expect(nextVisit.stations.any((s) => s.logoUrl == 'https://logo/4.png'),
          isFalse);
      await reopened.loadMore();
      await reopened.loadMore();
      final complete = reopened.state as GroupDetailSuccess;
      expect(complete.stations.length, 65);
      expect(complete.stations.map((s) => s.id).toSet().length, 65);
      expect(complete.stations.last.logoUrl, 'https://logo/4.png');
      final container = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        stationRepositoryProvider.overrideWithValue(repository),
        stationArtworkCacheProvider.overrideWithValue(cache),
      ]);
      try {
        final provider = groupDetailNotifierProvider(group);
        final subscription = container.listen(provider, (_, __) {});
        await ready(container.read(provider.notifier));
        subscription.close();
        await container.pump();
        expect(container.exists(provider), isFalse,
            reason:
                'Closing the group must release its old ordering snapshot.');
      } finally {
        container.dispose();
      }
    } finally {
      first?.dispose();
      reopened?.dispose();
      await db.close();
      directory.deleteSync(recursive: true);
    }
  });
}
