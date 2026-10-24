import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

/// Opt-in profile instrumentation, tree-shaken from ordinary builds.
class PerformanceProbe {
  static final _clock = Stopwatch();
  static Timer? _flush;
  static final _frames = <FrameTiming>[];

  static void install() {
    _clock.start();
    SchedulerBinding.instance.addTimingsCallback((frames) {
      _frames.addAll(frames);
      _flush?.cancel();
      _flush = Timer(const Duration(milliseconds: 600), _report);
    });
    SchedulerBinding.instance.addPostFrameCallback((_) {
      debugPrint('RV2PERF ${jsonEncode({
            'firstFrameMs': _clock.elapsedMilliseconds
          })}');
    });
  }

  static void _report() {
    final cache = PaintingBinding.instance.imageCache;
    debugPrint('RV2PERF ${jsonEncode({
          'elapsedMs': _clock.elapsedMilliseconds,
          'cacheBytes': cache.currentSizeBytes,
          'cacheImages': cache.currentSize,
          'pendingImages': cache.pendingImageCount,
          'liveImages': cache.liveImageCount,
        })}');
    for (var i = 0; i < _frames.length; i += 30) {
      debugPrint('RV2PERF ${jsonEncode({
            'frames': _frames
                .skip(i)
                .take(30)
                .map((f) => [
                      f.buildDuration.inMicroseconds,
                      f.rasterDuration.inMicroseconds
                    ])
                .toList()
          })}');
    }
    _frames.clear();
  }
}
