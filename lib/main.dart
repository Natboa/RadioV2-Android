import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/audio/audio_service_handler.dart';
import 'core/providers.dart';
import 'core/database/app_database.dart';
import 'core/data/datasource/database_initializer.dart';
import 'core/data/repository/station_repository_impl.dart';
import 'core/data/repository/favourite_repository_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // After an app update this swaps in the new bundled DB and has already
  // restored the user's favourites by the time it returns.
  final dbFile = await DatabaseInitializer.getOrCopyDatabase();
  final db = AppDatabase(dbFile);

  final stationRepo = StationRepositoryImpl(db);
  final favouriteRepo = FavouriteRepositoryImpl(db);

  final results = await Future.wait([
    AudioService.init(
      builder: () => RadioAudioHandler(
        repository: stationRepo,
        favouriteRepository: favouriteRepo,
      ),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.radiov2.radiov2_android.audio',
        androidNotificationChannelName: 'RadioV2 Playback',
        androidStopForegroundOnPause: true,
      ),
    ),
    SharedPreferences.getInstance(),
  ]);

  final audioHandler = results[0] as RadioAudioHandler;
  final prefs = results[1] as SharedPreferences;

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        audioHandlerProvider.overrideWithValue(audioHandler),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const RadioV2App(),
    ),
  );
}
