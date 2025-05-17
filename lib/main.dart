import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/core/audio_handler_implementation.dart';
import 'package:podsink2/data/datasources/app_database.dart';
import 'package:podsink2/domain/services/drift_db_service.dart';
import 'package:podsink2/domain/services/itunes_service.dart';
import 'package:podsink2/domain/services/rss_parser_service.dart';
import 'package:podsink2/extensions/color_material_color.dart';
import 'package:podsink2/presentation/shared_widgets/podsink2.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async';

// --- Global GetIt instance ---
final GetIt getIt = GetIt.instance;

// --- Global Constants ---
BoxDecoration kAppGradientBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.amber.shade900.toMaterialColor(),
      Colors.amber.shade800.toMaterialColor(),
      Colors.amber.shade600.toMaterialColor(), //
    ],
    stops: [0.0, 0.7, 1.0],
  ),
);

Future<void> setupLocator() async {
  getIt.registerSingleton<AppDatabase>(AppDatabase());
  getIt.registerSingleton<DriftDbService>(DriftDbService());

  // Initialize and register AudioHandler
  // We need to make this async because AudioService.init is async
  final audioHandler = await AudioService.init<AudioPlayerHandlerImpl>(
    builder: () => AudioPlayerHandlerImpl(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
      androidNotificationChannelName: 'Podcast playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  getIt.registerSingleton<AudioHandler>(audioHandler);
  getIt.registerSingleton<AudioPlayerHandlerImpl>(audioHandler);

  // Register AppState - it depends on AudioHandler (and potentially DbService)
  // Ensure dependencies are registered before AppState
  getIt.registerSingleton<AppState>(
    AppState(
      getIt<AudioPlayerHandlerImpl>(),
      getIt<DriftDbService>(),
    ),
  );

  getIt.registerLazySingleton<RssParserService>(() => RssParserService());
  getIt.registerLazySingleton<ItunesService>(() => ItunesService());

  debugPrint("GetIt setup complete.");
}

// --- Entry Point ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetIt locator
  try {
    await setupLocator();
    debugPrint("main: GetIt setupLocator() completed.");
  } catch (e, s) {
    debugPrint("Error during GetIt setup or AudioService.init: $e");
    debugPrint("Stack trace: $s");
    // Fallback or error handling if GetIt setup fails critically
    // For example, if AudioService.init fails, you might not want to proceed
    // or provide a dummy AudioHandler.
    if (!getIt.isRegistered<AudioHandler>()) {
      // A very basic fallback if audio handler registration failed.
      // This is a simplified example; your actual fallback might differ.
      getIt.registerSingleton<AudioHandler>(AudioPlayerHandlerImpl());
      getIt.registerSingleton<AudioPlayerHandlerImpl>(getIt<AudioHandler>() as AudioPlayerHandlerImpl);
      debugPrint("CRITICAL: AudioService.init() failed during setup. Registered a basic AudioPlayerHandlerImpl.");
      // Re-register AppState with the potentially fallback audio handler
      if (getIt.isRegistered<AppState>()) {
        getIt.unregister<AppState>();
      }
      getIt.registerSingleton<AppState>(
        AppState(
          getIt<AudioPlayerHandlerImpl>(),
          getIt<DriftDbService>(), // Pass the DbService instance
        ),
      );
    }
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light, //
    ),
  );

  runApp(const PodSink2());
}
