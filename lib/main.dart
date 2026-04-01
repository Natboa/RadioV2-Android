import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/data/datasource/database_initializer.dart';
import 'core/database/app_database.dart';
import 'core/providers.dart';
import 'core/audio/audio_service_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase 1: init database
  final dbFile = await DatabaseInitializer.getOrCopyDatabase();
  final appDatabase = AppDatabase(dbFile);

  // Phase 2: init audio service
  final audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.radiov2.radiov2_android.audio',
      androidNotificationChannelName: 'RadioV2 Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(appDatabase),
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const RadioV2App(),
    ),
  );
}
