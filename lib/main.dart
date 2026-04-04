import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/audio/audio_service_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AudioService.init is fast (~ms) — safe to await before runApp
  final audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.radiov2.radiov2_android.audio',
      androidNotificationChannelName: 'RadioV2 Playback',
      androidStopForegroundOnPause: false,
    ),
  );

  // runApp immediately — DB copy happens lazily via FutureProvider
  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const RadioV2App(),
    ),
  );
}
