import 'dart:async';
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The bitmap image provider cannot decode SVG. No network request is needed
// to recognise this format; keep the original catalog URL intact.
bool supportsStationArtwork(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  return !(Uri.tryParse(url.trim())?.path.toLowerCase().endsWith('.svg') ??
      false);
}

final stationArtworkCacheProvider =
    Provider<StationArtworkCache>((_) => StationArtworkCache());

/// Non-reactive, bounded metadata learned from ordinary image requests.
/// It never fetches/decodes images or notifies an open list to reorder itself.
class StationArtworkCache {
  static const _key = 'stationArtworkFailures.v1';
  static const _ttl = Duration(hours: 6);
  static const _limit = 256;
  final SharedPreferences? _prefs;
  final DateTime Function() _clock;
  final _failures = <String, int>{};

  StationArtworkCache({SharedPreferences? prefs, DateTime Function()? clock})
      : _prefs = prefs,
        _clock = clock ?? DateTime.now {
    final raw = prefs?.getString(_key);
    if (raw == null || raw.length > 262144) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        for (final entry in decoded.entries.take(_limit)) {
          if (entry.value is int &&
              entry.value > _clock().millisecondsSinceEpoch) {
            _failures[entry.key] = entry.value as int;
          }
        }
      }
    } on FormatException {
      /* Corrupt optional metadata must not block startup. */
    }
  }

  Set<String> get snapshot {
    final now = _clock().millisecondsSinceEpoch;
    _failures.removeWhere((_, expiry) => expiry <= now);
    return Set.unmodifiable(_failures.keys);
  }

  bool isUnavailable(String url) =>
      !supportsStationArtwork(url) ||
      (_failures[url.trim()] ?? 0) > _clock().millisecondsSinceEpoch;

  bool recordFailure(String url, Object error) {
    final key = url.trim();
    if (key.isEmpty || key.length > 2048) return false;
    final permanentHttp = error is HttpExceptionWithStatus &&
        const [403, 404, 410].contains(error.statusCode);
    final decodeFailure = error.toString().contains('Invalid image data') ||
        error.toString().contains('ImageCodecException');
    // Offline, DNS, timeout, rate limiting and server errors are transient.
    if (!permanentHttp && !decodeFailure) return false;
    if ((_failures[key] ?? 0) > _clock().millisecondsSinceEpoch) return false;
    final now = _clock().millisecondsSinceEpoch;
    _failures.removeWhere((_, expiry) => expiry <= now);
    _failures[key] = _clock().add(_ttl).millisecondsSinceEpoch;
    while (_failures.length > _limit) {
      _failures.remove(_failures.keys.first);
    }
    unawaited(_persist());
    return true;
  }

  Future<void> _persist() async {
    try {
      await _prefs?.setString(_key, jsonEncode(_failures));
    } catch (_) {/* Best-effort metadata; playback and browsing stay usable. */}
  }
}
