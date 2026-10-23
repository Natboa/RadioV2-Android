import 'dart:io';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_upgrade.dart';

class DatabaseInitializer {
  static const _dbAssetPath = 'assets/database/stations.db';

  /// Returns the database file, ready to open. The first launch copies the
  /// bundled DB; after an app update the bundled DB replaces it and the user's
  /// favourites are carried over (see [DatabaseUpgrade]).
  static Future<File> getOrCopyDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final prefs = await SharedPreferences.getInstance();
    final info = await PackageInfo.fromPlatform();

    return DatabaseUpgrade.ensureDatabase(
      dir: docsDir,
      loadAsset: () async {
        final data = await rootBundle.load(_dbAssetPath);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      },
      appVersion: info.version,
      prefs: prefs,
    );
  }
}
