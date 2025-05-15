import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/core/audio_handler_implementation.dart';
import 'package:podsink2/extensions/color_material_color.dart';
import 'package:podsink2/presentation/shared_widgets/podsink2.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' as Foundation;

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

// --- Global Variables & Constants ---
late AudioPlayerHandlerImpl _audioHandlerSingleton;

// --- Entry Point ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light, //
    ),
  );

  try {
    // kReleaseMode check is unusual here, typically init is for all modes.
    // Keeping as per user's last provided code.
    if (Foundation.kReleaseMode && false) {
      debugPrint("main: Calling JustAudioBackground.init()...");
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
        androidNotificationChannelName: 'Podcast playback',
        androidNotificationOngoing: true, //
        // androidNotificationIcon: 'mipmap/ic_notification', // Optional: Custom notification icon
      );
      debugPrint("main: JustAudioBackground.init() completed.");
    }

    debugPrint("main: Calling AudioService.init()...");
    _audioHandlerSingleton = await AudioService.init<AudioPlayerHandlerImpl>(
      builder: () => AudioPlayerHandlerImpl(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
        androidNotificationChannelName: 'Podcast playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true, //
        // artDownscaleWidth: 128, // Optional: For notification artwork
        // artDownscaleHeight: 128, // Optional
      ),
    );
    debugPrint("main: AudioService.init() completed.");
  } catch (e, s) {
    debugPrint("Error during initialization: $e");
    debugPrint("Stack trace: $s");
    if (e.toString().contains("_cacheManager == null': is not true")) {
      debugPrint("CRITICAL: AudioService.init() failed due to _cacheManager assertion. This is likely a plugin initialization conflict.");
    }
    _audioHandlerSingleton ??= AudioPlayerHandlerImpl();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(_audioHandlerSingleton)),
        Provider<AudioHandler>.value(value: _audioHandlerSingleton), //
      ],
      child: const PodSink2(),
    ),
  );
}
