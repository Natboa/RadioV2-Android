import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/repository/favourite_repository.dart';
import '../../core/data/repository/station_repository.dart';
import '../../core/providers.dart';
import 'settings_state.dart';

class SettingsNotifier extends StateNotifier<SettingsUiState> {
  final StationRepository _stationRepo;
  final FavouriteRepository _favRepo;

  SettingsNotifier(this._stationRepo, this._favRepo)
      : super(const SettingsIdle());

  Future<void> importFavourites() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['m3u', 'm3u8', 'json'],
    );
    if (result == null) return; // user cancelled

    state = const SettingsImporting();
    try {
      final path = result.files.single.path;
      if (path == null) {
        state = const SettingsImportError('Could not read the selected file.');
        return;
      }

      final content = await File(path).readAsString();
      final ext = result.files.single.extension?.toLowerCase() ?? '';

      final urls = ext == 'json' ? _parseJson(content) : _parseM3U(content);

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

  void reset() => state = const SettingsIdle();

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

  List<String> _parseJson(String content) {
    final urls = <String>[];
    try {
      final list = jsonDecode(content);
      if (list is! List) return urls;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final url = item['streamUrl'] ??
              item['StreamUrl'] ??
              item['url'] ??
              item['stream_url'];
          if (url is String && url.isNotEmpty) urls.add(url);
        }
      }
    } catch (_) {}
    return urls;
  }
}

final settingsNotifierProvider =
    StateNotifierProvider.autoDispose<SettingsNotifier, SettingsUiState>((ref) {
  return SettingsNotifier(
    ref.watch(stationRepositoryProvider),
    ref.watch(favouriteRepositoryProvider),
  );
});
