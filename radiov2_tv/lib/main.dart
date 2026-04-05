import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/audio/audio_service_handler.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape on TV
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final results = await Future.wait([
    AudioService.init(
      builder: () => RadioAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.radiov2.radiov2_tv.audio',
        androidNotificationChannelName: 'RadioV2 TV Playback',
        androidStopForegroundOnPause: false,
      ),
    ),
    SharedPreferences.getInstance(),
  ]);

  final audioHandler = results[0] as RadioAudioHandler;
  final prefs = results[1] as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const RadioV2TvApp(),
    ),
  );
}
