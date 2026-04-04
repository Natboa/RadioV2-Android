import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/data/repository/favourite_repository.dart';
import '../../core/data/repository/station_repository.dart';
import '../../core/database/app_database.dart';
import '../../core/providers.dart';
import 'settings_state.dart';

class SettingsNotifier extends StateNotifier<SettingsUiState> {
  final StationRepository _stationRepo;
  final FavouriteRepository _favRepo;
  final AppDatabase _db;

  SettingsNotifier(this._stationRepo, this._favRepo, this._db)
      : super(const SettingsIdle());

  void reset() => state = const SettingsIdle();

  // ── Import ──────────────────────────────────────────────────────────────

  Future<void> importFavourites() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8'],
    );
    if (result == null) return;

    state = const SettingsImporting();
    try {
      final path = result.files.single.path;
      if (path == null) {
        state = const SettingsImportError('Could not read the selected file.');
        return;
      }

      final content = await File(path).readAsString();
      final urls = _parseM3U(content);

      if (urls.isEmpty) {
        state = const SettingsImportError('No stations found in the file.');
        return;
      }

      final urlToId = await _stationRepo.getStationIdsByStreamUrls(urls);
      int added = 0;
      for (final id in urlToId.values) {
        await _favRepo.addFavourite(id);
        added++;
      }

      state = SettingsImportDone(added: added, total: urls.length);
    } catch (e) {
      state = SettingsImportError('Import failed: $e');
    }
  }

  // ── Export ──────────────────────────────────────────────────────────────

  Future<void> exportFavourites() async {
    state = const SettingsExporting();
    try {
      final stations = await _favRepo.getFavourites();
      if (stations.isEmpty) {
        state = const SettingsExportError('No favourites to export.');
        return;
      }

      // Build groupId → groupName map (one lookup per unique groupId)
      final groupNames = <int, String>{};
      for (final s in stations) {
        if (!groupNames.containsKey(s.groupId)) {
          final group = await _db.groupDao.getGroupById(s.groupId);
          groupNames[s.groupId] = group?.name ?? 'Unknown';
        }
      }

      const fileName = 'radiov2_favourites.m3u';
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsString(_buildM3U(stations, groupNames), encoding: utf8);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'audio/x-mpegurl', name: fileName)],
        subject: 'RadioV2 Favourites',
      );

      state = const SettingsExportDone();
    } catch (e) {
      state = SettingsExportError('Export failed: $e');
    }
  }

  // ── M3U ─────────────────────────────────────────────────────────────────

  String _buildM3U(List<dynamic> stations, Map<int, String> groupNames) {
    final sb = StringBuffer();
    sb.writeln('#EXTM3U');
    for (final s in stations) {
      final logo = s.logoUrl != null ? ' tvg-logo="${s.logoUrl}"' : '';
      final group = groupNames[s.groupId] ?? 'Uncategorized';
      sb.writeln('#EXTINF:-1$logo group-title="$group",${s.name}');
      sb.writeln(s.streamUrl);
    }
    return sb.toString();
  }

  List<String> _parseM3U(String content) {
    final urls = <String>[];
    final lines = content.split('\n').map((l) => l.trim()).toList();
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('#EXTINF')) {
        for (int j = i + 1; j < lines.length; j++) {
          final line = lines[j];
          if (line.isNotEmpty && !line.startsWith('#')) {
            urls.add(line);
            break;
          }
        }
      }
    }
    return urls;
  }
}

final settingsNotifierProvider =
    StateNotifierProvider.autoDispose<SettingsNotifier, SettingsUiState>((ref) {
  return SettingsNotifier(
    ref.watch(stationRepositoryProvider),
    ref.watch(favouriteRepositoryProvider),
    ref.watch(appDatabaseProvider).requireValue,
  );
});
