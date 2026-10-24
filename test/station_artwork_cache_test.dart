import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:radiov2_android/core/images/station_artwork_cache.dart';

void main() {
  test(
      'confirmed failures persist, expire, and do not classify connectivity as missing art',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var now = DateTime.utc(2026, 10, 23);
    final cache = StationArtworkCache(prefs: prefs, clock: () => now);
    const url = 'https://station.test/logo.png';
    expect(cache.recordFailure(url, const SocketException('offline')), isFalse);
    expect(
        cache.recordFailure(url, const HttpExceptionWithStatus(500, 'server')),
        isFalse);
    expect(cache.snapshot, isEmpty);
    expect(
        cache.recordFailure(
            url, const HttpExceptionWithStatus(403, 'forbidden')),
        isTrue);
    expect(
        cache.recordFailure(
            url, const HttpExceptionWithStatus(403, 'forbidden')),
        isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(StationArtworkCache(prefs: prefs, clock: () => now).snapshot, {url});
    final frozenVisit = cache.snapshot;
    cache.recordFailure('https://station.test/other.png',
        const HttpExceptionWithStatus(404, 'missing'));
    expect(frozenVisit, {url},
        reason: 'An open paginated list keeps its original ordering snapshot.');
    now = now.add(const Duration(hours: 7));
    expect(cache.snapshot, isEmpty);
  });
  test('failure metadata is bounded and malformed persisted data is ignored',
      () async {
    SharedPreferences.setMockInitialValues(
        {'stationArtworkFailures.v1': '{bad'});
    final cache =
        StationArtworkCache(prefs: await SharedPreferences.getInstance());
    expect(cache.snapshot, isEmpty);
    for (var i = 0; i < 300; i++) {
      cache.recordFailure(
          'https://test/$i.png', const HttpExceptionWithStatus(404, 'missing'));
    }
    expect(cache.snapshot.length, lessThanOrEqualTo(256));
  });
  test('unsupported SVG paths are recognised without fetching artwork', () {
    expect(supportsStationArtwork('https://test/LOGO.SVG?quality=85'), isFalse);
    expect(supportsStationArtwork('https://test/logo.png'), isTrue);
    expect(supportsStationArtwork(null), isFalse);
  });
}
