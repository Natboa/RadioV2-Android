import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseInitializer {
  static const _dbAssetPath = 'assets/database/stations.db';
  static const _dbFileName = 'stations.db';

  /// Returns the database file, copying from assets on first launch.
  static Future<File> getOrCopyDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(docsDir.path, _dbFileName));

    if (!dbFile.existsSync()) {
      final data = await rootBundle.load(_dbAssetPath);
      final bytes = data.buffer.asUint8List();
      await dbFile.writeAsBytes(bytes, flush: true);
    }

    return dbFile;
  }
}
