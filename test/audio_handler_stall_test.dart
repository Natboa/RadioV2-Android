import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:radiov2_android/core/audio/audio_service_handler.dart';
import 'package:radiov2_android/core/audio/station_player.dart';
import 'package:radiov2_android/core/data/repository/favourite_repository.dart';
import 'package:radiov2_android/core/data/repository/station_repository.dart';

class _Stations extends Fake implements StationRepository {}

class _Favourites extends Fake implements FavouriteRepository {}

class _FakeLoad {
  _FakeLoad(this.url);
  final String url;
  final done = Completer<void>();
  bool get pending => !done.isCompleted;
}

/// Behaves like just_audio on Android: a load that has not finished is
/// aborted (PlayerInterruptedException) when the player is stopped or another
/// load starts; play() on a live stream never completes.
class _FakePlayer implements StationPlayer {
  final events = StreamController<PlaybackEvent>.broadcast(sync: true);
  final loads = <_FakeLoad>[];
  int plays = 0;
  int stops = 0;
  bool interruptsOnStop = true;
  @override
  bool playing = false;

  _FakeLoad get last => loads.last;

  void _interruptPending() {
    for (final l in loads) {
      if (l.pending) {
        l.done.completeError(PlayerInterruptedException('Loading interrupted'));
      }
    }
  }

  @override
  Future<void> load(String url, {Map<String, String>? headers}) {
    if (interruptsOnStop) _interruptPending();
    final l = _FakeLoad(url);
    loads.add(l);
    return l.done.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    playing = false;
    if (interruptsOnStop) _interruptPending();
  }

  @override
  Future<void> play() {
    plays++;
    if (playing) return Future.value();
    playing = true;
    events.add(PlaybackEvent(processingState: ProcessingState.ready));
    return Completer<void>().future; // live stream: never completes
  }

  @override
  Stream<PlaybackEvent> get playbackEventStream => events.stream;
  @override
  Duration get position => Duration.zero;
  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  double get speed => 1.0;
  @override
  Future<void> dispose() async => events.close();
}

const _dead = 'http://dead.example.com/live';
const _good = 'http://good.example.com/live';
const _good2 = 'http://good2.example.com/live';

Future<void> settle([int ms = 25]) =>
    Future.delayed(Duration(milliseconds: ms));

void main() {
  late _FakePlayer player;
  late RadioAudioHandler handler;
  late int errors;
  var online = true;

  RadioAudioHandler build(Duration deadline) => RadioAudioHandler(
        repository: _Stations(),
        favouriteRepository: _Favourites(),
        player: player,
        isOnline: () async => online,
        loadDeadline: deadline,
        configureAudioSession: false,
      );

  void start({Duration deadline = const Duration(seconds: 30)}) {
    handler = build(deadline);
    handler.playbackState.listen((s) {
      if (s.processingState == AudioProcessingState.error) errors++;
    });
  }

  setUp(() {
    player = _FakePlayer();
    errors = 0;
    online = true;
  });

  tearDown(() async => handler.dispose());

  group('a dead station must not hold up the next tap', () {
    test(
        'a good station tapped while a dead one is still loading starts at once',
        () async {
      start(); // 30 s deadline: only the abort can unblock the second tap
      final deadTap = handler.playUrl(_dead);
      await settle();
      expect(player.loads.length, 1);
      expect(player.last.pending, isTrue);

      final goodTap = handler.playUrl(_good);
      await settle();

      expect(player.loads.length, 2,
          reason: 'second load must not queue behind the first');
      expect(player.loads[1].url, _good);
      expect(player.stops, 1, reason: 'the unfinished load is aborted first');

      player.last.done.complete();
      await goodTap;
      await deadTap; // the aborted tap finishes quietly
      expect(player.plays, 1);
      expect(errors, 0, reason: 'an aborted load is not a failure');
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('rapid taps A, B, C: only C is played', () async {
      start();
      final taps = [
        handler.playUrl('a'),
        handler.playUrl('b'),
        handler.playUrl('c')
      ];
      await settle();
      expect(player.loads.last.url, 'c');
      player.last.done.complete();
      await Future.wait(taps);
      expect(player.plays, 1);
      expect(errors, 0);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'an aborted load that only fails later, with a real error, is still ignored',
        () async {
      start();
      player.interruptsOnStop = false; // stubborn native side
      final first = handler.playUrl(_dead);
      await settle();
      final second = handler.playUrl(_good);
      await settle();
      player.loads[0].done
          .completeError(PlayerException(0, 'connection failed'));
      player.loads[1].done.complete();
      await Future.wait([first, second]);
      expect(errors, 0);
      expect(player.plays, 1);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'switching between working stations does not call stop() (behaviour unchanged)',
        () async {
      start();
      final a = handler.playUrl(_good);
      await settle();
      player.last.done.complete();
      await a;
      final b = handler.playUrl(_good2);
      await settle();
      player.last.done.complete();
      await b;
      expect(player.stops, 0);
      expect(player.plays, 2);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('stop() while loading cancels the start', () async {
      start();
      final tap = handler.playUrl(_good);
      await settle();
      await handler.stop();
      await tap;
      expect(player.plays, 0);
      expect(errors, 0);
    }, timeout: const Timeout(Duration(seconds: 5)));
  });

  group('load deadline', () {
    test('an old connectivity check cannot stop a replacement station',
        () async {
      final check = Completer<bool>();
      handler = RadioAudioHandler(
        repository: _Stations(),
        favouriteRepository: _Favourites(),
        player: player,
        isOnline: () => check.future,
        loadDeadline: const Duration(milliseconds: 40),
        configureAudioSession: false,
      );
      final first = handler.playUrl(_dead);
      await settle(80);
      final second = handler.playUrl(_good);
      await settle(10);
      player.last.done.complete();
      await second;
      check.complete(true);
      await settle(60);
      await first;
      expect(player.playing, isTrue);
      expect(player.stops, 1,
          reason: 'only the user switch should stop a load');
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.ready);
    });

    test('duplicate native error and idle events do not clear a timeout error',
        () async {
      start(deadline: const Duration(milliseconds: 40));
      await handler.playUrl(_dead);
      player.events.addError(PlayerException(0, 'late error'));
      player.events.add(PlaybackEvent(processingState: ProcessingState.idle));
      await settle();
      expect(errors, 1);
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.error);
      expect(handler.playbackState.value.playing, isFalse);
    });

    test(
        'a dead station gives up at the deadline, aborts the load and reports one error',
        () async {
      start(deadline: const Duration(milliseconds: 60));
      await handler.playUrl(_dead);
      await settle();
      expect(player.stops, 1, reason: 'the native load is aborted');
      expect(errors, 1);
      expect(player.plays, 0);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('a station that loads in time is not reported as failed', () async {
      start(deadline: const Duration(milliseconds: 100));
      final tap = handler.playUrl(_good);
      await settle(20);
      player.last.done.complete();
      await tap;
      await settle(200); // well past the deadline
      expect(errors, 0);
      expect(player.stops, 0);
      expect(player.plays, 1);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('offline: does not give up, and plays when the load finally completes',
        () async {
      online = false;
      start(deadline: const Duration(milliseconds: 40));
      final tap = handler.playUrl(_good);
      await settle(200); // several deadlines pass
      expect(errors, 0);
      expect(player.stops, 0);
      expect(player.last.pending, isTrue);
      player.last.done.complete(); // network came back, Media3 got through
      await tap;
      expect(player.plays, 1);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('offline at first, online at a later deadline: gives up then',
        () async {
      online = false;
      start(deadline: const Duration(milliseconds: 40));
      final tap = handler.playUrl(_dead);
      await settle(100);
      expect(errors, 0);
      online = true;
      await tap;
      await settle();
      expect(errors, 1);
      expect(player.stops, 1);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('after a dead station failed, the next station plays normally',
        () async {
      start(deadline: const Duration(milliseconds: 50));
      await handler.playUrl(_dead);
      final tap = handler.playUrl(_good);
      await settle();
      player.last.done.complete();
      await tap;
      await settle();
      expect(errors, 1);
      expect(player.plays, 1);
    }, timeout: const Timeout(Duration(seconds: 5)));
  });

  group('existing behaviour that must survive', () {
    test(
        'switch from an already playing station publishes ready even when play is a no-op',
        () async {
      start();
      player.playing =
          true; // just_audio preserves playing across a source swap
      final tap = handler.playUrl(_good);
      await settle();
      player.events.add(PlaybackEvent(processingState: ProcessingState.ready));
      player.last.done.complete();
      await tap;
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.ready);
      expect(handler.playbackState.value.playing, isTrue);
    });

    test('stop publishes playing=false after a working station', () async {
      start();
      final tap = handler.playUrl(_good);
      await settle();
      player.last.done.complete();
      await tap;
      await handler.stop();
      expect(handler.playbackState.value.playing, isFalse);
      expect(handler.playbackState.value.processingState,
          AudioProcessingState.idle);
    });

    test('a load that fails outright reports exactly one error', () async {
      start();
      final tap = handler.playUrl(_dead);
      await settle();
      player.last.done.completeError(PlayerException(404, 'not found'));
      await tap;
      await settle();
      expect(errors, 1);
      expect(player.plays, 0);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('a new request clears the old ICY title', () async {
      start();
      handler.icyMetadataStream.add('Old Song');
      final tap = handler.playUrl(_good);
      expect(handler.icyMetadataStream.value, isNull);
      await settle();
      player.last.done.complete();
      await tap;
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('play() from the notification reconnects with a fresh load', () async {
      start();
      handler.updateNowPlaying(
          stationId: 1, streamUrl: _good, title: 'Good FM');
      final tap = handler.play();
      await settle();
      expect(player.last.url, _good);
      player.last.done.complete();
      await tap;
      expect(player.plays, 1);
    }, timeout: const Timeout(Duration(seconds: 5)));
  });
}
