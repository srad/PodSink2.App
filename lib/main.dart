import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webfeed_plus/webfeed_plus.dart';
import 'package:just_audio/just_audio.dart' as ja; // Aliased just_audio
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' as Foundation;

import 'package:flutter/material.dart';

extension ColorToMaterialColorExtension on Color {
  /// Converts a [Color] to a [MaterialColor] by generating a swatch of 10 shades.
  ///
  /// The original color is used as the [500] shade. Lighter shades are generated
  /// by tinting towards white, and darker shades by shading towards black.
  ///
  /// ```dart
  /// final MaterialColor myCustomSwatch = Colors.blue.toMaterialColor();
  ///
  /// // Then use it in your theme:
  /// ThemeData(  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  ///   primarySwatch: myCustomSwatch,
  /// )
  /// ```
  MaterialColor toMaterialColor() {
    final int r = red;
    final int g = green;
    final int b = blue;

    final Map<int, Color> swatch = {
      50: _tintColor(this, 0.9),  // Lightest
      100: _tintColor(this, 0.8),
      200: _tintColor(this, 0.6),
      300: _tintColor(this, 0.4),
      400: _tintColor(this, 0.2),
      500: this, // The original color
      600: _shadeColor(this, 0.1),
      700: _shadeColor(this, 0.2),
      800: _shadeColor(this, 0.3),
      900: _shadeColor(this, 0.4), // Darkest
    };

    // The `MaterialColor` constructor expects an `int` for its primary value.
    // `this.value` (the 32-bit ARGB integer representation of the color) is suitable here.
    //
    // Deprecation notes for `Color.value` (as of early 2025):
    // There were significant discussions and deprecations around `Color` properties
    // (like `Color.value`, `Color.red`, `Color.alpha`, etc.) around Flutter 3.27
    // in late 2024, primarily related to the introduction of wide gamut color support
    // and a shift towards floating-point components (e.g., `Color.r`, `Color.g`, `Color.b`, `Color.a`).
    //
    // However, the `MaterialColor(int primary, Map<int, Color> swatch)` constructor
    // still requires an `int` for the `primary` argument. The documentation for this
    // constructor explicitly states: "The primary argument should be the 32 bit ARGB value of
    // one of the values in the swatch, as would be passed to the Color.new constructor
    // for that same color, and as is exposed by value."
    //
    // As of the latest API docs checked (simulated for May 2025), `Color.value` (the getter)
    // is not marked as deprecated, and is the direct way to get this integer.
    // The integer component getters like `this.red`, `this.green`, `this.blue` also remain.
    //
    // If `Color.value` were to become definitively deprecated and removed without a direct
    // replacement integer getter suitable for `MaterialColor`, you would need to reconstruct it:
    // `int primaryValue = (alpha << 24) | (red << 16) | (green << 8) | blue;`
    // But for now, `this.value` is the correct and intended property.

    return MaterialColor(value, swatch);
  }

  /// Tints the given [color] towards white by the [factor].
  /// A [factor] of 0.0 means no change, 1.0 means full white.
  Color _tintColor(Color color, double factor) {
    assert(factor >= 0.0 && factor <= 1.0);
    final int r = color.red + ((255 - color.red) * factor).round();
    final int g = color.green + ((255 - color.green) * factor).round();
    final int b = color.blue + ((255 - color.blue) * factor).round();
    return Color.fromRGBO(
      r.clamp(0, 255), // Ensure values are within 0-255 range
      g.clamp(0, 255),
      b.clamp(0, 255),
      1.0, // Opacity is always 1.0 for swatch colors
    );
  }

  /// Shades the given [color] towards black by the [factor].
  /// A [factor] of 0.0 means no change, 1.0 means full black.
  Color _shadeColor(Color color, double factor) {
    assert(factor >= 0.0 && factor <= 1.0);
    final int r = color.red - (color.red * factor).round();
    final int g = color.green - (color.green * factor).round();
    final int b = color.blue - (color.blue * factor).round();
    return Color.fromRGBO(
      r.clamp(0, 255), // Ensure values are within 0-255 range
      g.clamp(0, 255),
      b.clamp(0, 255),
      1.0, // Opacity is always 1.0 for swatch colors
    );
  }
}

// Alternative popular shading algorithm (often found in gists/StackOverflow)
// This algorithm is also widely used and provides a good set of shades.
// It ensures the 500 shade is exactly the input color.
extension AlternativeMaterialColorGenerator on Color {
  MaterialColor toMaterialColorAlt() {
    final double r = red.toDouble();
    final double g = green.toDouble();
    final double b = blue.toDouble();

    final Map<int, Color> swatch = {};
    final List<double> strengths = <double>[.05]; // For shade 50

    // Add strengths for shades 100 through 900
    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }

    for (final double strength in strengths) {
      final double ds = 0.5 - strength; // Strength relative to 500 (0.5)
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        (r + (ds < 0 ? r : (255 - r)) * ds).round().clamp(0, 255),
        (g + (ds < 0 ? g : (255 - g)) * ds).round().clamp(0, 255),
        (b + (ds < 0 ? b : (255 - b)) * ds).round().clamp(0, 255),
        1.0,
      );
    }
    // Ensure the 500 shade is exactly the original color,
    // in case of any floating point inaccuracies from the calculation.
    swatch[500] = this;
    return MaterialColor(value, swatch);
  }
}

// --- Global Constants ---
BoxDecoration kAppGradientBackground = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      // Colors.deepPurple.shade800,
      // Colors.deepPurple.shade700,
      // Colors.deepPurple.shade500,
      Colors.amber.shade900.toMaterialColor(),
      Colors.amber.shade800.toMaterialColor(),
      Colors.amber.shade600.toMaterialColor(),
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
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    // kReleaseMode check is unusual here, typically init is for all modes.
    // Keeping as per user's last provided code.
    if (Foundation.kReleaseMode) {
      debugPrint("main: Calling JustAudioBackground.init()...");
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.mycompany.myapp.channel.audio',
        androidNotificationChannelName: 'Podcast playback',
        androidNotificationOngoing: true,
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
        androidStopForegroundOnPause: true,
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

  await DatabaseHelper.instance.database;
  debugPrint("main: Database initialized.");


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState(_audioHandlerSingleton)),
        Provider<AudioHandler>.value(value: _audioHandlerSingleton),
      ],
      child: const MyApp(),
    ),
  );
}

// --- Database Helper ---
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('podcasts_app.db'); // Renamed DB file for clarity
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = p.join(dbPath.path, filePath);
    debugPrint("Database path: $path");
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgradeDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';
    const intType = 'INTEGER';
    const intTypeNotNull = 'INTEGER NOT NULL';


    await db.execute('''
CREATE TABLE podcasts ( 
  id $idType, 
  title $textType,
  artistName $textType,
  artworkUrl $textType,
  feedUrl $textType
  )
''');
    debugPrint("Podcasts table created.");

    await db.execute('''
CREATE TABLE played_history (
  guid $idType, 
  podcastTitle $textType,
  episodeTitle $textType,
  audioUrl $textType,
  artworkUrl $textTypeNullable,
  totalDurationMs $intType,
  lastPositionMs $intTypeNotNull,
  lastPlayedDate $textType 
)
''');
    debugPrint("Played_history table created.");
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration logic if needed, e.g., adding played_history table if upgrading from version 1
      const idType = 'TEXT PRIMARY KEY NOT NULL';
      const textType = 'TEXT NOT NULL';
      const textTypeNullable = 'TEXT';
      const intType = 'INTEGER';
      const intTypeNotNull = 'INTEGER NOT NULL';

      await db.execute('''
CREATE TABLE IF NOT EXISTS played_history (
  guid $idType, 
  podcastTitle $textType,
  episodeTitle $textType,
  audioUrl $textType,
  artworkUrl $textTypeNullable,
  totalDurationMs $intType,
  lastPositionMs $intTypeNotNull,
  lastPlayedDate $textType 
)
''');
      debugPrint("Played_history table created during upgrade.");
    }
  }


  Future<int> subscribePodcast(Podcast podcast) async {
    final db = await instance.database;
    try {
      return await db.insert('podcasts', podcast.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint("Error inserting podcast into DB: $e");
      if (e is DatabaseException && e.isUniqueConstraintError()) {
        debugPrint("Podcast already exists in DB (ID: ${podcast.id})");
        return 0;
      }
      rethrow;
    }
  }

  Future<List<Podcast>> getSubscribedPodcasts() async {
    final db = await instance.database;
    final result = await db.query('podcasts', orderBy: 'title ASC');
    return result.map((json) => Podcast.fromMap(json)).toList();
  }

  Future<int> unsubscribePodcast(String id) async {
    final db = await instance.database;
    return await db.delete(
      'podcasts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isSubscribed(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'podcasts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // --- History DB Methods ---
  Future<int> addOrUpdateHistoryItem(PlayedEpisodeHistoryItem item) async {
    final db = await instance.database;
    return await db.insert(
      'played_history',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if guid already exists
    );
  }

  Future<List<PlayedEpisodeHistoryItem>> getHistoryItems({int limit = 50, int offset = 0}) async {
    final db = await instance.database;
    final result = await db.query(
      'played_history',
      orderBy: 'lastPlayedDate DESC',
      limit: limit,
      offset: offset,
    );
    return result.map((json) => PlayedEpisodeHistoryItem.fromMap(json)).toList();
  }

  Future<int> deleteHistoryItem(String guid) async {
    final db = await instance.database;
    return await db.delete(
      'played_history',
      where: 'guid = ?',
      whereArgs: [guid],
    );
  }

  Future<int> clearAllHistory() async {
    final db = await instance.database;
    return await db.delete('played_history');
  }


  Future close() async {
    final db = await instance.database;
    db.close();
    _database = null; // Reset database instance on close
  }
}


// --- Main Application Widget ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Podcast App',
      theme: ThemeData(
          primarySwatch: Colors.amber,
          scaffoldBackgroundColor: Colors.transparent, // For gradient to show through
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Inter',
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.white, // Default text color for gradient background
            displayColor: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent, // Make AppBar transparent
            foregroundColor: Colors.white, // For title and icons
            elevation: 0, // No shadow
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.black54,
            foregroundColor: Colors.white,
          ),
          listTileTheme: ListTileThemeData(
            iconColor: Colors.white70,
            textColor: Colors.white,
            selectedTileColor: Colors.amber.shade300.withValues(alpha: 0.3),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            hintStyle: TextStyle(color: Colors.white70),
            prefixIconColor: Colors.white70,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: const BorderSide(color: Colors.white, width: 1.5),
            ),
            border: OutlineInputBorder( // Default border
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
          cardTheme: CardTheme(
            color: Colors.white.withValues(alpha: 0.15),
            elevation: 0, // Remove shadow if using transparent background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              // side: BorderSide(color: Colors.white.withValues(alpha: 0.2)), // Optional border
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white70),
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.white)
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white
              )
          )
      ),
      home: const HomeScreen(),
    );
  }
}

// --- MODELS ---

/// Data model for a podcast.
class Podcast {
  final String id;
  final String title;
  final String artistName;
  final String artworkUrl;
  final String feedUrl;
  List<Episode> episodes;

  Podcast({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artworkUrl,
    required this.feedUrl,
    this.episodes = const [],
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['collectionId']?.toString() ?? json['feedUrl'] ?? UniqueKey().toString(),
      title: json['collectionName'] ?? json['trackName'] ?? 'Unknown Title',
      artistName: json['artistName'] ?? 'Unknown Artist',
      artworkUrl: json['artworkUrl600'] ?? json['artworkUrl100'] ?? 'https://placehold.co/600x600/E0E0E0/B0B0B0?text=No+Art',
      feedUrl: json['feedUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artistName': artistName,
    'artworkUrl': artworkUrl,
    'feedUrl': feedUrl,
  };

  factory Podcast.fromMap(Map<String, dynamic> map) {
    return Podcast(
      id: map['id'] as String,
      title: map['title'] as String,
      artistName: map['artistName'] as String,
      artworkUrl: map['artworkUrl'] as String,
      feedUrl: map['feedUrl'] as String,
    );
  }
}

/// Data model for a podcast episode.
class Episode {
  final String guid;
  final String podcastTitle;
  final String title;
  final String description;
  final String audioUrl;
  final DateTime? pubDate;
  final String? artworkUrl;
  final Duration? duration;

  Episode({
    required this.guid,
    required this.podcastTitle,
    required this.title,
    required this.description,
    required this.audioUrl,
    this.pubDate,
    this.artworkUrl,
    this.duration,
  });

  factory Episode.fromRssItem(dynamic item, String podcastTitleFromFeed, String podcastArtworkFromFeed) {
    String? extractedAudioUrl;
    if (item.enclosure?.url != null) {
      extractedAudioUrl = item.enclosure!.url!;
    } else if (item.media?.contents != null && item.media!.contents!.isNotEmpty) {
      extractedAudioUrl = item.media!.contents!
          .firstWhere((content) => content.type?.startsWith('audio/') ?? false, orElse: () => null)
          ?.url;
    }

    return Episode(
      guid: item.guid ?? UniqueKey().toString(),
      podcastTitle: podcastTitleFromFeed,
      title: item.title ?? 'Unknown Episode',
      description: item.description ?? item.itunes?.summary ?? 'No description available.',
      audioUrl: extractedAudioUrl ?? '',
      pubDate: item.pubDate,
      artworkUrl: item.itunes?.image?.href ?? podcastArtworkFromFeed,
      duration: _parseDuration(item.itunes?.duration?.toString()),
    );
  }

  static Duration? _parseDuration(String? s) {
    if (s == null) return null;
    try {
      final parts = s.split(':').map(int.parse).toList();
      if (parts.length == 3) return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
      if (parts.length == 2) return Duration(minutes: parts[0], seconds: parts[1]);
      if (parts.length == 1) return Duration(seconds: parts[0]);
    } catch (e) {
      debugPrint("Error parsing duration string '$s': $e");
    }
    return null;
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: audioUrl,
      album: podcastTitle,
      title: title,
      artist: podcastTitle,
      duration: duration,
      artUri: artworkUrl != null && artworkUrl!.isNotEmpty ? Uri.tryParse(artworkUrl!) : null,
      extras: {'guid': guid, 'description': description, 'podcastTitle': podcastTitle, 'artworkUrl': artworkUrl},
    );
  }
}

/// Data model for a played episode history item.
class PlayedEpisodeHistoryItem {
  final String guid; // Episode GUID, primary key
  final String podcastTitle;
  final String episodeTitle;
  final String audioUrl; // To re-initiate playback if needed
  final String? artworkUrl;
  final int? totalDurationMs; // Store as int (milliseconds)
  int lastPositionMs; // Store as int (milliseconds)
  DateTime lastPlayedDate;

  PlayedEpisodeHistoryItem({
    required this.guid,
    required this.podcastTitle,
    required this.episodeTitle,
    required this.audioUrl,
    this.artworkUrl,
    this.totalDurationMs,
    required this.lastPositionMs,
    required this.lastPlayedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'guid': guid,
      'podcastTitle': podcastTitle,
      'episodeTitle': episodeTitle,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'totalDurationMs': totalDurationMs,
      'lastPositionMs': lastPositionMs,
      'lastPlayedDate': lastPlayedDate.toIso8601String(), // Store date as ISO8601 string
    };
  }

  factory PlayedEpisodeHistoryItem.fromMap(Map<String, dynamic> map) {
    return PlayedEpisodeHistoryItem(
      guid: map['guid'] as String,
      podcastTitle: map['podcastTitle'] as String,
      episodeTitle: map['episodeTitle'] as String,
      audioUrl: map['audioUrl'] as String,
      artworkUrl: map['artworkUrl'] as String?,
      totalDurationMs: map['totalDurationMs'] as int?,
      lastPositionMs: map['lastPositionMs'] as int,
      lastPlayedDate: DateTime.parse(map['lastPlayedDate'] as String),
    );
  }
}


// --- STATE MANAGEMENT (using Provider) ---

/// Manages the application's state.
class AppState extends ChangeNotifier {
  final AudioPlayerHandlerImpl _audioHandler;
  List<Podcast> _subscribedPodcasts = [];
  List<PlayedEpisodeHistoryItem> _playedHistory = [];

  StreamSubscription? _mediaItemSubscription;
  StreamSubscription? _playbackStateSubscription;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  MediaItem? _previousMediaItemForHistory;
  Duration _previousMediaItemLastPosition = Duration.zero;


  Episode? get currentEpisodeFromAudioService {
    final mediaItem = _audioHandler.mediaItem.value;
    if (mediaItem == null) return null;
    return _episodeFromMediaItem(mediaItem);
  }

  bool get isPlayingFromAudioService => _audioHandler.playbackState.value.playing;
  List<Podcast> get subscribedPodcasts => _subscribedPodcasts;
  List<PlayedEpisodeHistoryItem> get playedHistory => _playedHistory;


  AppState(this._audioHandler) {
    _initializeState();
  }

  Future<void> _initializeState() async {
    await loadSubscribedPodcasts();
    await loadPlayedHistory();

    _mediaItemSubscription = _audioHandler.mediaItem.listen((mediaItem) {
      _handleMediaItemChangeForHistory(mediaItem, _audioHandler.playbackState.value);
      notifyListeners();
    });
    _playbackStateSubscription = _audioHandler.playbackState.listen((playbackState) {
      _updateHistoryForCurrentEpisode(playbackState);
      notifyListeners();
    });
  }


  Episode? _episodeFromMediaItem(MediaItem mediaItem) {
    for (var podcast in _subscribedPodcasts) {
      if (podcast.episodes.isNotEmpty) {
        for (var episode in podcast.episodes) {
          if ((mediaItem.extras?['guid'] != null && episode.guid == mediaItem.extras!['guid']) ||
              episode.audioUrl == mediaItem.id) {
            return Episode(
              guid: episode.guid,
              podcastTitle: episode.podcastTitle,
              title: episode.title,
              description: mediaItem.extras?['description'] ?? episode.description,
              audioUrl: episode.audioUrl,
              pubDate: episode.pubDate,
              artworkUrl: episode.artworkUrl,
              duration: episode.duration,
            );
          }
        }
      }
    }
    // Fallback if episode not in subscribed list (e.g. played from search before full details fetched)
    return Episode(
      guid: mediaItem.extras?['guid'] as String? ?? mediaItem.id,
      podcastTitle: mediaItem.album ?? mediaItem.extras?['podcastTitle'] ?? 'Unknown Podcast',
      title: mediaItem.title ?? 'Unknown Title',
      description: mediaItem.extras?['description'] as String? ?? 'Description not available.',
      audioUrl: mediaItem.id,
      artworkUrl: mediaItem.artUri?.toString() ?? mediaItem.extras?['artworkUrl'],
      duration: mediaItem.duration,
    );
  }

  Future<void> subscribeToPodcast(Podcast podcast) async {
    final isAlreadySubscribed = await _dbHelper.isSubscribed(podcast.id);
    if (!isAlreadySubscribed) {
      await _dbHelper.subscribePodcast(podcast);
      _subscribedPodcasts.add(podcast);
      _subscribedPodcasts.sort((a, b) => a.title.compareTo(b.title));
      notifyListeners();
    } else {
      debugPrint("Podcast ${podcast.title} is already subscribed.");
    }
  }

  Future<void> unsubscribeFromPodcast(Podcast podcast) async {
    await _dbHelper.unsubscribePodcast(podcast.id);
    _subscribedPodcasts.removeWhere((p) => p.id == podcast.id);
    notifyListeners();
  }

  Future<void> loadSubscribedPodcasts() async {
    _subscribedPodcasts = await _dbHelper.getSubscribedPodcasts();
    notifyListeners();
    debugPrint("Loaded ${_subscribedPodcasts.length} subscribed podcasts from DB.");
  }

  // --- History Methods ---
  Future<void> loadPlayedHistory() async {
    _playedHistory = await _dbHelper.getHistoryItems();
    notifyListeners();
    debugPrint("Loaded ${_playedHistory.length} history items from DB.");
  }

  Future<void> addEpisodeToHistory(PlayedEpisodeHistoryItem historyItem) async {
    // Only add/update if significant playback happened (e.g., > 5 seconds or not at the very beginning)
    if (historyItem.lastPositionMs > 5000 || (historyItem.totalDurationMs != null && historyItem.lastPositionMs >= historyItem.totalDurationMs! - 5000)) {
      await _dbHelper.addOrUpdateHistoryItem(historyItem);
      // Update in-memory list
      final index = _playedHistory.indexWhere((item) => item.guid == historyItem.guid);
      if (index != -1) {
        _playedHistory[index] = historyItem;
      } else {
        _playedHistory.add(historyItem);
      }
      _playedHistory.sort((a, b) => b.lastPlayedDate.compareTo(a.lastPlayedDate)); // Sort by most recent
      notifyListeners();
    }
  }


  Future<void> removeEpisodeFromHistory(String guid) async {
    await _dbHelper.deleteHistoryItem(guid);
    _playedHistory.removeWhere((item) => item.guid == guid);
    notifyListeners();
  }

  Future<void> clearAllPlayedHistory() async {
    await _dbHelper.clearAllHistory();
    _playedHistory.clear();
    notifyListeners();
    debugPrint("Cleared all played history.");
  }


  void _handleMediaItemChangeForHistory(MediaItem? newMediaItem, PlaybackState currentPlaybackState) {
    if (_previousMediaItemForHistory != null) {
      // Save history for the episode that just finished or was changed
      final previousEpisode = _episodeFromMediaItem(_previousMediaItemForHistory!);
      if (previousEpisode != null) {
        final historyItem = PlayedEpisodeHistoryItem(
          guid: previousEpisode.guid,
          podcastTitle: previousEpisode.podcastTitle,
          episodeTitle: previousEpisode.title,
          audioUrl: previousEpisode.audioUrl,
          artworkUrl: previousEpisode.artworkUrl,
          totalDurationMs: _previousMediaItemForHistory!.duration?.inMilliseconds,
          lastPositionMs: _previousMediaItemLastPosition.inMilliseconds,
          lastPlayedDate: DateTime.now(),
        );
        addEpisodeToHistory(historyItem);
      }
    }

    _previousMediaItemForHistory = newMediaItem;
    _previousMediaItemLastPosition = newMediaItem != null ? currentPlaybackState.position : Duration.zero;
  }

  void _updateHistoryForCurrentEpisode(PlaybackState playbackState) {
    final currentMediaItem = _audioHandler.mediaItem.value;
    if (currentMediaItem != null) {
      _previousMediaItemLastPosition = playbackState.position; // Keep track of current position

      // Save on pause or completion if played for a bit
      if ((!playbackState.playing && playbackState.position > const Duration(seconds: 5)) ||
          playbackState.processingState == AudioProcessingState.completed) {
        final episode = _episodeFromMediaItem(currentMediaItem);
        if (episode != null) {
          final historyItem = PlayedEpisodeHistoryItem(
            guid: episode.guid,
            podcastTitle: episode.podcastTitle,
            episodeTitle: episode.title,
            audioUrl: episode.audioUrl,
            artworkUrl: episode.artworkUrl,
            totalDurationMs: currentMediaItem.duration?.inMilliseconds,
            lastPositionMs: playbackState.position.inMilliseconds,
            lastPlayedDate: DateTime.now(),
          );
          addEpisodeToHistory(historyItem);
        }
      }
    }
  }


  Future<void> playEpisode(Episode episode) async {
    // When a new episode starts, log the previous one if it was playing
    final currentMedia = _audioHandler.mediaItem.value;
    if (currentMedia != null && currentMedia.id != episode.audioUrl) {
      final prevEpisode = _episodeFromMediaItem(currentMedia);
      if (prevEpisode != null) {
        addEpisodeToHistory(PlayedEpisodeHistoryItem(
            guid: prevEpisode.guid,
            podcastTitle: prevEpisode.podcastTitle,
            episodeTitle: prevEpisode.title,
            audioUrl: prevEpisode.audioUrl,
            artworkUrl: prevEpisode.artworkUrl,
            totalDurationMs: currentMedia.duration?.inMilliseconds,
            lastPositionMs: _audioHandler.playbackState.value.position.inMilliseconds,
            lastPlayedDate: DateTime.now()
        ));
      }
    }

    await _audioHandler.setQueue([episode.toMediaItem()]);
    await _audioHandler.play();
    // Also log this episode as starting (or update it)
    addEpisodeToHistory(PlayedEpisodeHistoryItem(
        guid: episode.guid,
        podcastTitle: episode.podcastTitle,
        episodeTitle: episode.title,
        audioUrl: episode.audioUrl,
        artworkUrl: episode.artworkUrl,
        totalDurationMs: episode.duration?.inMilliseconds,
        lastPositionMs: 0, // Starts at 0
        lastPlayedDate: DateTime.now()
    ));
  }

  Future<void> resumeEpisodeFromHistory(PlayedEpisodeHistoryItem historyItem) async {
    // Reconstruct a minimal Episode object or find it if already loaded
    final episodeToPlay = Episode(
      guid: historyItem.guid,
      podcastTitle: historyItem.podcastTitle,
      title: historyItem.episodeTitle,
      description: '', // Description not crucial for resuming, but could be fetched
      audioUrl: historyItem.audioUrl,
      artworkUrl: historyItem.artworkUrl,
      duration: historyItem.totalDurationMs != null ? Duration(milliseconds: historyItem.totalDurationMs!) : null,
    );
    await _audioHandler.setQueue([episodeToPlay.toMediaItem()]);
    await _audioHandler.seek(Duration(milliseconds: historyItem.lastPositionMs));
    await _audioHandler.play();
  }


  Future<void> togglePlayPause() async {
    if (_audioHandler.playbackState.value.playing) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
    // Update history on pause
    _updateHistoryForCurrentEpisode(_audioHandler.playbackState.value);

  }

  Future<void> stopPlayback() async {
    _updateHistoryForCurrentEpisode(_audioHandler.playbackState.value); // Save position before stopping
    await _audioHandler.stop();
  }
  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
    // Optionally update history on seek, or wait for pause/stop
  }


  @override
  void dispose() {
    // Before disposing, ensure the current episode's final position is logged
    if (_audioHandler.mediaItem.value != null && _audioHandler.playbackState.value.position > Duration.zero) {
      _updateHistoryForCurrentEpisode(_audioHandler.playbackState.value);
    }

    _mediaItemSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _dbHelper.close();
    super.dispose();
  }
}

// --- SERVICES ---

/// Service to fetch podcast data from the iTunes API.
class ItunesService {
  final String _baseUrl = 'https://itunes.apple.com/search';

  Future<List<Podcast>> searchPodcasts(String term) async {
    try {
      final encodedTerm = Uri.encodeComponent(term);
      final url = Uri.parse('$_baseUrl?term=$encodedTerm&media=podcast&entity=podcast');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((json) => Podcast.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load podcasts from iTunes (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect to iTunes service: $e');
    }
  }
}

/// Service to fetch and parse RSS feeds for podcast episodes.
class RssParserService {
  Future<List<Episode>> fetchEpisodes(Podcast podcast) async {
    if (podcast.feedUrl.isEmpty) return [];
    try {
      final response = await http.get(Uri.parse(podcast.feedUrl));
      if (response.statusCode == 200) {
        try {
          var rssFeed = RssFeed.parse(response.body);
          if (rssFeed.items == null || rssFeed.items!.isEmpty) {
            return _parseAtomFeed(response.body, podcast);
          }
          return rssFeed.items!.map((item) => Episode.fromRssItem(item, rssFeed.title ?? podcast.title, rssFeed.image?.url ?? podcast.artworkUrl)).toList();
        } catch (e) {
          return _parseAtomFeed(response.body, podcast);
        }
      } else {
        throw Exception('Failed to load RSS feed (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching/parsing feed: $e');
    }
  }

  List<Episode> _parseAtomFeed(String xmlString, Podcast podcast) {
    try {
      var atomFeed = AtomFeed.parse(xmlString);
      if (atomFeed.items == null || atomFeed.items!.isEmpty) return [];
      return atomFeed.items!.map((item) {
        String? audioUrl = item.links?.firstWhere((link) => link.rel == 'enclosure' && (link.type?.startsWith('audio/') ?? false))?.href;
        return Episode(
          guid: item.id ?? UniqueKey().toString(),
          podcastTitle: atomFeed.title ?? podcast.title,
          title: item.title ?? 'Unknown Episode',
          description: item.summary ?? item.content ?? 'No description.',
          audioUrl: audioUrl ?? '',
          pubDate: item.updated ?? (item.published != null ? DateTime.tryParse(item.published!) : null),
          artworkUrl: atomFeed.logo ?? atomFeed.icon ?? podcast.artworkUrl,
          duration: null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Feed format not recognized or Atom parsing error: $e');
    }
  }
}

/// AudioHandler implementation using just_audio.
class AudioPlayerHandlerImpl extends BaseAudioHandler with SeekHandler {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  List<MediaItem> _queue = [];
  // Callback to notify AppState about playback progression for history
  // This is one way; another is for AppState to actively listen and decide when to save.
  // For simplicity, we'll let AppState manage history updates by observing playbackState and mediaItem.
  // Function(MediaItem mediaItem, Duration position)? onProgressUpdateForHistory;


  AudioPlayerHandlerImpl() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    _player.currentIndexStream.listen((index) {
      if (index != null && _queue.isNotEmpty && index < _queue.length) {
        mediaItem.add(_queue[index]);
      }
    });

    _player.durationStream.listen((duration) {
      final currentMediaItem = mediaItem.value;
      if (currentMediaItem != null && currentMediaItem.duration != duration) {
        final newCopy = currentMediaItem.copyWith(duration: duration);
        mediaItem.add(newCopy);
      }
    });

  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    await _player.setShuffleModeEnabled(shuffleMode != AudioServiceShuffleMode.none);
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    ja.LoopMode mode = ja.LoopMode.off;
    if(repeatMode == AudioServiceRepeatMode.one) mode = ja.LoopMode.one;
    if(repeatMode == AudioServiceRepeatMode.all || repeatMode == AudioServiceRepeatMode.group) mode = ja.LoopMode.all;
    await _player.setLoopMode(mode);
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    _queue = newQueue;
    queue.add(_queue);
  }

  Future<void> setQueue(List<MediaItem> newQueue) async {
    _queue = newQueue;
    queue.add(_queue);
    if (_queue.isNotEmpty) {
      final audioSources = _queue.map((item) {
        Uri? artUri;
        if (item.artUri != null && item.artUri.toString().isNotEmpty) {
          try { artUri = Uri.parse(item.artUri.toString()); } catch (e) { debugPrint("Invalid artUri for ${item.title}: ${item.artUri} - $e");}
        }
        return ja.AudioSource.uri(Uri.parse(item.id), tag: item.copyWith(artUri: artUri));
      }).toList();
      try {
        await _player.setAudioSource(ja.ConcatenatingAudioSource(children: audioSources), initialIndex: 0, preload: true);
      } catch (e) {
        debugPrint("Error setting audio source: $e");
        mediaItem.add(null);
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorMessage: e.toString(),
          errorCode: (e is ja.PlayerException) ? e.code : null,
        ));
      }
    } else {
      await _player.stop();
      mediaItem.add(null);
    }
  }

  @override
  Future<void> addQueueItem(MediaItem item) async {
    _queue.add(item);
    queue.add(_queue);
    if (_player.audioSource is ja.ConcatenatingAudioSource) {
      Uri? artUri;
      if (item.artUri != null && item.artUri.toString().isNotEmpty) {
        try { artUri = Uri.parse(item.artUri.toString()); } catch (e) { debugPrint("Invalid artUri for ${item.title}: ${item.artUri} - $e");}
      }
      await (_player.audioSource as ja.ConcatenatingAudioSource).add(ja.AudioSource.uri(Uri.parse(item.id), tag: item.copyWith(artUri: artUri)));
    } else {
      await setQueue([item]);
    }
  }

  @override
  Future<void> play() async {
    if (_player.audioSource != null) {
      try {
        await _player.play();
      } catch (e) {
        debugPrint("Error on play: $e");
        playbackState.add(playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
          playing: false,
          errorMessage: e.toString(),
          errorCode: (e is ja.PlayerException) ? e.code : null,
        ));
      }
    } else if (_queue.isNotEmpty) {
      await setQueue(_queue);
      if (_player.audioSource != null && playbackState.value.processingState != AudioProcessingState.error) {
        try {
          await _player.play();
        } catch (e) {
          debugPrint("Error on play after setQueue: $e");
          playbackState.add(playbackState.value.copyWith(
            processingState: AudioProcessingState.error,
            playing: false,
            errorMessage: e.toString(),
            errorCode: (e is ja.PlayerException) ? e.code : null,
          ));
        }
      }
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    // AppState will listen to playbackState change and log history if needed
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    if (playbackState.value.playing && !_player.playing) await _player.play().catchError((e) => debugPrint("Error playing next: $e"));
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    if (playbackState.value.playing && !_player.playing) await _player.play().catchError((e) => debugPrint("Error playing previous: $e"));
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await _player.seek(Duration.zero, index: index);
    if (playbackState.value.playing && !_player.playing) await _player.play().catchError((e) => debugPrint("Error playing item $index: $e"));
  }

  @override
  Future<void> stop() async {
    // AppState will listen to playbackState change (going to idle/stopped) and log history
    await _player.stop();
    mediaItem.add(null);
  }

  PlaybackState _transformEvent(ja.PlaybackEvent event) {
    final audioProcessingState = const {
      ja.ProcessingState.idle: AudioProcessingState.idle,
      ja.ProcessingState.loading: AudioProcessingState.loading,
      ja.ProcessingState.buffering: AudioProcessingState.buffering,
      ja.ProcessingState.ready: AudioProcessingState.ready,
      ja.ProcessingState.completed: AudioProcessingState.completed,
    }[event.processingState] ?? AudioProcessingState.idle;

    String? effectiveErrorMessage = playbackState.value.errorMessage;
    int? effectiveErrorCode = playbackState.value.errorCode;

    if (audioProcessingState != AudioProcessingState.error) {
      effectiveErrorMessage = null;
      effectiveErrorCode = null;
    }

    // When processingState becomes completed, ensure current mediaItem & position are logged to history by AppState
    // AppState's listener for playbackState handles this.

    return PlaybackState(
      controls: [
        _player.hasPrevious ? MediaControl.skipToPrevious : MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        _player.hasNext ? MediaControl.skipToNext : MediaControl.fastForward,
      ],
      systemActions: const {
        MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward,
        MediaAction.setShuffleMode, MediaAction.setRepeatMode,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: audioProcessingState,
      playing: _player.playing,
      updatePosition: event.updatePosition,
      bufferedPosition: event.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
      repeatMode: const {
        ja.LoopMode.off: AudioServiceRepeatMode.none,
        ja.LoopMode.one: AudioServiceRepeatMode.one,
        ja.LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode] ?? AudioServiceRepeatMode.none,
      shuffleMode: _player.shuffleModeEnabled
          ? AudioServiceShuffleMode.all
          : AudioServiceShuffleMode.none,
      errorMessage: effectiveErrorMessage,
      errorCode: effectiveErrorCode,
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'dispose') {
      await _player.dispose();
      super.customAction(name, extras);
    }
  }
}

// --- SCREENS ---

/// Home screen displaying subscribed podcasts.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Provider.of<AppState>(context, listen: false).loadSubscribedPodcasts();
        Provider.of<AppState>(context, listen: false).loadPlayedHistory(); // Load history
      } catch (e) {
        debugPrint("Error in HomeScreen initState accessing AppState: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final subscribedPodcasts = appState.subscribedPodcasts.where((p) =>
    p.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        p.artistName.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Stack(
      children: [
      // Gradient background covering the whole screen
        Positioned.fill(
          child: Container(
            decoration: kAppGradientBackground,
          ),
        ),

    // Your Scaffold on top

    Scaffold(
      appBar: AppBar(
        title: const Text('My Podcasts'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      drawer: const AppDrawer(), // Add the drawer

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white), // Text input color
                  decoration: InputDecoration(
                    hintText: 'Search subscribed...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                    suffixIcon: _searchController.text.isNotEmpty ?  IconButton(onPressed: () => setState(() => _searchController.text = ''), icon: Icon(Icons.close_rounded, color: Colors.white)): null,
                    // Borders are themed globally
                  ),
                  onChanged: (value) => setState(() => _searchController.text = value),
                ),
              ),
            Expanded(
              child: subscribedPodcasts.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _searchController.text.isEmpty ? 'No podcasts subscribed yet.\nTap "+" to add.' : 'No podcasts found for "${_searchController.text}".',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8), // Adjust top padding for AppBar
                itemCount: subscribedPodcasts.length,
                itemBuilder: (context, index) {
                  final podcast = subscribedPodcasts[index];
                  return Card( // Card styling will be picked from theme
                    // color: Colors.white.withValues(alpha: 0.15), // Example explicit styling if theme is not enough
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: podcast.artworkUrl, width: 50, height: 50, fit: BoxFit.cover,
                          placeholder: (c, u) => Container(width: 50, height: 50, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.podcasts, color: Colors.white54, size: 30)),
                          errorWidget: (c, u, e) => Container(width: 50, height: 50, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.broken_image, color: Colors.white54, size: 30)),
                        ),
                      ),
                      title: Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          podcast.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                      subtitle: Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          podcast.artistName, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PodcastDetailScreen(podcast: podcast))),
                      trailing: IconButton(onPressed: () => {}, icon: Icon(Icons.remove_circle_rounded)),
                    ),
                  );
                },
              ),
            ),
            Selector<AppState, Episode?>(
              selector: (_, appStateWatch) => appStateWatch.currentEpisodeFromAudioService,
              builder: (context, currentEpisode, child) => currentEpisode != null ? MiniPlayer(currentEpisode: currentEpisode) : const SizedBox.shrink(),
            ),
          ],
      ),
      floatingActionButton: FloatingActionButton(
        shape: CircleBorder(),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PodcastSearchScreen())),
        tooltip: 'Add Podcast',
        child: const Icon(Icons.add), // FAB icon color defaults to theme's foreground for FAB
      ),
    )]);
  }
}

/// Screen to search for new podcasts.
class PodcastSearchScreen extends StatefulWidget {
  const PodcastSearchScreen({super.key});
  @override
  State<PodcastSearchScreen> createState() => _PodcastSearchScreenState();
}

class _PodcastSearchScreenState extends State<PodcastSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ItunesService _itunesService = ItunesService();
  List<Podcast> _searchResults = [];
  bool _isLoading = false;
  String _message = 'Search iTunes for podcasts.';

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() { _message = 'Please enter a search term.'; _searchResults = []; });
      return;
    }
    setState(() { _isLoading = true; _message = ''; _searchResults = []; });
    try {
      final results = await _itunesService.searchPodcasts(_searchController.text.trim());
      if(mounted) {
        setState(() {
          _searchResults = results;
          if (results.isEmpty) _message = 'No podcasts found for "${_searchController.text.trim()}".';
        });
      }
    } catch (e) {
      if(mounted) setState(() => _message = 'Error: ${e.toString()}');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appStateForAction = Provider.of<AppState>(context, listen: false);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Discover Podcasts')),
      body: Container(
        decoration: kAppGradientBackground,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight), // Adjust for status bar and AppBar
        child: Column(
          children: [
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController, autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search iTunes...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.7)), onPressed: () {
                          _searchController.clear();
                          setState(() { _searchResults = []; _message = 'Search for podcasts on iTunes.'; });
                        }) : null,
                      ),
                      onSubmitted: (_) => _performSearch(), textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_isLoading) const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
                  else if (_message.isNotEmpty && _searchResults.isEmpty)
                    Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)))))
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final podcast = _searchResults[index];
                          return Builder(
                              builder: (BuildContext innerContext) {
                                final isSubscribed = innerContext.select<AppState, bool>(
                                        (appStateWatch) => appStateWatch.subscribedPodcasts.any((p) => p.id == podcast.id)
                                );
                                return Card( // Uses themed Card
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(6.0),
                                      child: CachedNetworkImage(
                                        imageUrl: podcast.artworkUrl, width: 50, height: 50, fit: BoxFit.cover,
                                        placeholder: (c,u) => Container(width:50, height:50, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.image_search, color: Colors.white54)),
                                        errorWidget: (c,u,e) => Container(width:50, height:50, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.broken_image, color: Colors.white54)),
                                      ),
                                    ),
                                    title: Text(podcast.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                                    subtitle: Text(podcast.artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                                    trailing: IconButton(
                                      icon: Icon(isSubscribed ? Icons.check_circle : Icons.add_circle_outline, color: isSubscribed ? Colors.greenAccent : Colors.white70, size: 28),
                                      tooltip: isSubscribed ? 'Subscribed' : 'Subscribe',
                                      onPressed: () {
                                        if (!isSubscribed) appStateForAction.subscribeToPodcast(podcast);
                                        else appStateForAction.unsubscribeFromPodcast(podcast);
                                        ScaffoldMessenger.of(innerContext).showSnackBar(SnackBar(
                                            content: Text('${isSubscribed ? "Unsubscribed from" : "Subscribed to"} ${podcast.title}'),
                                            backgroundColor: Colors.deepPurple.shade900,
                                            behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(10)));
                                      },
                                    ),
                                    onTap: () => Navigator.push(innerContext, MaterialPageRoute(builder: (context) => PodcastDetailScreen(podcast: podcast, isFromSearch: true))),
                                  ),
                                );
                              }
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            Selector<AppState, Episode?>(
              selector: (_, appStateWatch) => appStateWatch.currentEpisodeFromAudioService,
              builder: (context, currentEpisode, child) => currentEpisode != null ? MiniPlayer(currentEpisode: currentEpisode) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen displaying episodes for a selected podcast.
class PodcastDetailScreen extends StatefulWidget {
  final Podcast podcast;
  final bool isFromSearch;
  const PodcastDetailScreen({super.key, required this.podcast, this.isFromSearch = false});
  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  List<Episode> _episodes = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final RssParserService _rssService = RssParserService();

  @override
  void initState() {
    super.initState();
    _fetchPodcastEpisodes();
  }

  Future<void> _fetchPodcastEpisodes() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final subscribedPodcast = appState.subscribedPodcasts.firstWhere((p) => p.id == widget.podcast.id, orElse: () => widget.podcast);

      if (subscribedPodcast.episodes.isNotEmpty) {
        _episodes = subscribedPodcast.episodes;
      } else {
        final fetchedEpisodes = await _rssService.fetchEpisodes(widget.podcast);
        if (appState.subscribedPodcasts.any((p) => p.id == widget.podcast.id)) {
          appState.subscribedPodcasts.firstWhere((p) => p.id == widget.podcast.id).episodes = fetchedEpisodes;
        }
        _episodes = fetchedEpisodes;
        widget.podcast.episodes = fetchedEpisodes;
      }
      if (_episodes.isEmpty && widget.podcast.feedUrl.isNotEmpty) _errorMessage = 'No episodes found.';
    } catch (e) {
      if(mounted) _errorMessage = 'Failed to load episodes. Check connection.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.podcast.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          Selector<AppState, bool>(
            selector: (_, app) => app.subscribedPodcasts.any((p) => p.id == widget.podcast.id),
            builder: (context, isSubscribed, child) {
              if (widget.isFromSearch && !isSubscribed) {
                return TextButton(
                  onPressed: () {
                    Provider.of<AppState>(context, listen: false).subscribeToPodcast(widget.podcast);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subscribed to ${widget.podcast.title}'), backgroundColor: Colors.deepPurple.shade900, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(10)));
                  },
                  child: const Text('SUBSCRIBE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Container(
        decoration: kAppGradientBackground,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + kToolbarHeight),
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : _errorMessage.isNotEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orangeAccent))))
                  : _episodes.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('No episodes found for this podcast.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70))))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                itemCount: _episodes.length,
                itemBuilder: (context, index) {
                  final episode = _episodes[index];
                  final isCurrent = appState.currentEpisodeFromAudioService?.guid == episode.guid || appState.currentEpisodeFromAudioService?.audioUrl == episode.audioUrl;
                  final isPlaying = isCurrent && appState.isPlayingFromAudioService;
                  return Card( // Uses themed Card
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: episode.artworkUrl ?? widget.podcast.artworkUrl, width: 60, height: 60, fit: BoxFit.cover,
                          placeholder: (c,u) => Container(width:60, height:60, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.mic_none, color: Colors.white54, size: 30)),
                          errorWidget: (c,u,e) => Container(width:60, height:60, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.broken_image, color: Colors.white54, size: 30)),
                        ),
                      ),
                      title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(episode.podcastTitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (episode.pubDate != null) Text('Published: ${DateFormat.yMMMd().format(episode.pubDate!)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
                          if (episode.duration != null) Text('Duration: ${_formatDuration(episode.duration!)}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 36),
                        tooltip: isPlaying ? 'Pause' : 'Play',
                        onPressed: () => isCurrent ? appState.togglePlayPause() : appState.playEpisode(episode),
                      ),
                      onTap: () => isCurrent ? appState.togglePlayPause() : appState.playEpisode(episode),
                    ),
                  );
                },
              ),
            ),
            Selector<AppState, Episode?>(
              selector: (_, appStateWatch) => appStateWatch.currentEpisodeFromAudioService,
              builder: (context, currentEpisode, child) => currentEpisode != null ? MiniPlayer(currentEpisode: currentEpisode) : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    var s = d.inSeconds;
    final h = s ~/ 3600; s %= 3600;
    final m = s ~/ 60; s %= 60;
    List<String> parts = [];
    if (h > 0) parts.add('${h}h');
    if (m > 0) parts.add('${m}m');
    if (s > 0 || parts.isEmpty) parts.add('${s}s');
    return parts.join(' ');
  }
}

// --- WIDGETS ---

/// App Drawer Widget
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black45.withValues(alpha: 0.95),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
                gradient: LinearGradient( // Using a similar gradient for drawer header
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.amber.shade900, Colors.amber.shade700],
                )
            ),
            child: const Text(
              'Podsink2',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.white70),
            title: const Text('Playing History', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayingHistoryScreen()));
            },
          ),
          // Add other drawer items here if needed
        ],
      ),
    );
  }
}


/// Screen to display Playing History
class PlayingHistoryScreen extends StatelessWidget {
  const PlayingHistoryScreen({super.key});

  String _formatDuration(Duration? d) {
    if (d == null || d.inMilliseconds <= 0) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return [
      if (hours > 0) hours.toString(),
      minutes,
      seconds,
    ].join(':');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Playing History'),
      ),
      body: Container(
        decoration: kAppGradientBackground,
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.playedHistory.isEmpty) {
              return const Center(
                child: Text('No playing history yet.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              );
            }
            return ListView.builder(
              itemCount: appState.playedHistory.length,
              itemBuilder: (context, index) {
                final item = appState.playedHistory[index];
                final totalDuration = item.totalDurationMs != null ? Duration(milliseconds: item.totalDurationMs!) : null;
                final lastPosition = Duration(milliseconds: item.lastPositionMs);

                double progress = 0.0;
                if (totalDuration != null && totalDuration.inMilliseconds > 0 && lastPosition.inMilliseconds > 0) {
                  progress = (lastPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
                }


                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: CachedNetworkImage(
                        imageUrl: item.artworkUrl ?? 'https://placehold.co/70x70/FFFFFF/000000?text=NoArt',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (c,u) => Container(width:50, height:50, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.music_note, color: Colors.white54)),
                        errorWidget: (c,u,e) => Container(width:50, height:50, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.broken_image, color: Colors.white54)),
                      ),
                    ),
                    title: Text(item.episodeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.podcastTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        const SizedBox(height: 4),
                        if (totalDuration != null && totalDuration != Duration.zero)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade100),
                                minHeight: 3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Listened: ${_formatDuration(lastPosition)} / ${_formatDuration(totalDuration)}',
                                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Listened: ${_formatDuration(lastPosition)}',
                            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        Text('Last Played: ${DateFormat.yMd().add_jm().format(item.lastPlayedDate.toLocal())}', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_arrow_rounded, color: Colors.greenAccent.shade100),
                          tooltip: 'Resume',
                          onPressed: () {
                            appState.resumeEpisodeFromHistory(item);
                            if (Navigator.canPop(context)) { // If full screen player is not main, pop to show mini player
                              Navigator.pop(context); // Pop history screen
                            }
                            // Consider navigating to FullScreenPlayer if desired
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.redAccent.shade100),
                          tooltip: 'Remove from history',
                          onPressed: () {
                            appState.removeEpisodeFromHistory(item.guid);
                          },
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}


/// Mini player widget displayed at the bottom.
class MiniPlayer extends StatelessWidget {
  final Episode currentEpisode;
  const MiniPlayer({super.key, required this.currentEpisode});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final audioHandler = Provider.of<AudioHandler>(context, listen: false);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenPlayerScreen(episode: currentEpisode),
          ),
        );
      },
      child: Material(
        elevation: 10.0,
        color: Colors.black.withValues(alpha: 0.3), // Themed MiniPlayer background
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          height: 70,
          // color: Colors.grey[50], // Old color
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 0.5)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: CachedNetworkImage(
                  imageUrl: currentEpisode.artworkUrl ?? 'https://placehold.co/60x60/E0E0E0/B0B0B0?text=Art', width: 50, height: 50, fit: BoxFit.cover,
                  placeholder: (c,u) => Container(width:50, height:50, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.music_note, color: Colors.white54)),
                  errorWidget: (c,u,e) => Container(width:50, height:50, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.broken_image, color: Colors.white54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        currentEpisode.title,
                        style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white)
                    ),
                    //const SizedBox(height: 2),
                    //Text(currentEpisode.podcastTitle, style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8)), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
              StreamBuilder<PlaybackState>(
                  stream: audioHandler.playbackState,
                  builder: (context, snapshot) {
                    final ps = snapshot.data;
                    final isPlaying = ps?.playing ?? false;
                    final procState = ps?.processingState ?? AudioProcessingState.idle;
                    if (procState == AudioProcessingState.loading || procState == AudioProcessingState.buffering) {
                      return const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white));
                    }
                    return IconButton(
                      icon: Icon(isPlaying ? Icons.pause_circle_filled_outlined : Icons.play_circle_fill_outlined, size: 36, color: Colors.white),
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: appState.togglePlayPause,
                    );
                  }
              ),
              IconButton(
                icon: Icon(Icons.stop_circle_outlined, size: 32, color: Colors.white.withValues(alpha: 0.7)),
                tooltip: 'Stop', onPressed: appState.stopPlayback,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full Screen Player
class FullScreenPlayerScreen extends StatefulWidget {
  final Episode episode;

  const FullScreenPlayerScreen({super.key, required this.episode});

  @override
  State<FullScreenPlayerScreen> createState() => _FullScreenPlayerScreen();
}

class _FullScreenPlayerScreen extends State<FullScreenPlayerScreen> {
  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [
      if (hours > 0) hours.toString(),
      minutes,
      seconds,
    ].join(':');
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioHandler>(context, listen: false);
    final widthScale = 0.6;

    return Scaffold(
      extendBodyBehindAppBar: true, // Let gradient go behind AppBar
      appBar: AppBar(
        title: Text(widget.episode.podcastTitle, style: const TextStyle(fontSize: 16)),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: kAppGradientBackground, // Use the global gradient
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top), // Space for AppBar and StatusBar
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.4, child:
            CarouselView.weighted(
              consumeMaxWeight: true,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
              backgroundColor: Colors.black.withValues(alpha: 0.3),
              scrollDirection: Axis.horizontal,
              flexWeights: [4,1],
              itemSnapping: true,
              children: [
                // Podcast Artwork
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: CachedNetworkImage(
                    imageUrl: widget.episode.artworkUrl ?? 'https://placehold.co/300x300/E0E0E0/B0B0B0?text=No+Art',
                    width: MediaQuery.of(context).size.width * widthScale,
                    height: MediaQuery.of(context).size.width * widthScale,
                    fit: BoxFit.fill,
                    placeholder: (context, url) => Container(
                      width: MediaQuery.of(context).size.width * widthScale,
                      height: MediaQuery.of(context).size.width * widthScale,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: MediaQuery.of(context).size.width * widthScale,
                      height: MediaQuery.of(context).size.width * widthScale,
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Icon(Icons.broken_image, size: 100, color: Colors.white54),
                    ),
                  ),
                ),
                // Episode Description (Scrollable)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2), // Slightly darker for readability
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.episode.description.isNotEmpty ? widget.episode.description : "No description available.",
                        style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5),
                      ),
                    ),
                  ),
                ),
              ],
            )),

            Container(margin: EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  const SizedBox(height: 24),
                  // Podcast Title (Artist)
                  Text(
                    widget.episode.podcastTitle,
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Episode Title
                  Text(
                    widget.episode.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                    maxLines: 3, // Allow more lines for episode title
                    overflow: TextOverflow.ellipsis,
                  ),
                ])),

            Spacer(),

            // Seek Bar and Time Labels
            StreamBuilder<MediaItem?>(
                stream: audioHandler.mediaItem,
                builder: (context, mediaItemSnapshot) {
                  final currentMediaItem = mediaItemSnapshot.data;
                  return StreamBuilder<PlaybackState>(
                    stream: audioHandler.playbackState,
                    builder: (context, playbackStateSnapshot) {
                      final playbackState = playbackStateSnapshot.data;
                      final position = playbackState?.position ?? Duration.zero;
                      final bufferedPosition = playbackState?.bufferedPosition ?? Duration.zero;
                      final totalDuration = currentMediaItem?.duration ?? widget.episode.duration ?? Duration.zero;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withAlpha(0x29),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                              trackHeight: 2.0,
                            ),
                            child: Slider(
                              min: 0.0,
                              max: totalDuration.inMilliseconds.toDouble().clamp(1.0, double.infinity), // Ensure max is at least 1.0
                              value: position.inMilliseconds.toDouble().clamp(0.0, totalDuration.inMilliseconds.toDouble()),
                              secondaryTrackValue: bufferedPosition.inMilliseconds.toDouble().clamp(0.0, totalDuration.inMilliseconds.toDouble()),
                              onChanged: (totalDuration.inMilliseconds > 0) ? (value) {
                                audioHandler.seek(Duration(milliseconds: value.round()));
                              } : null,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(position), style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                                Text(_formatDuration(totalDuration), style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                }
            ),
            const SizedBox(height: 16),

            // Playback Controls
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                final processingState = snapshot.data?.processingState ?? AudioProcessingState.idle;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                      onPressed: () {
                        final currentPosition = audioHandler.playbackState.value.position;
                        audioHandler.seek(currentPosition - const Duration(seconds: 10));
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                      onPressed: audioHandler.skipToPrevious,
                    ),
                    if (processingState == AudioProcessingState.loading || processingState == AudioProcessingState.buffering)
                      Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 64.0,
                        height: 64.0,
                        child: const CircularProgressIndicator(color: Colors.white),
                      )
                    else
                      IconButton(
                        icon: Icon(
                          playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 72.0,
                        ),
                        onPressed: playing ? audioHandler.pause : audioHandler.play,
                      ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                      onPressed: audioHandler.skipToNext,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                      onPressed: () {
                        final currentPosition = audioHandler.playbackState.value.position;
                        final totalDuration = audioHandler.mediaItem.value?.duration ?? Duration.zero;
                        final newPosition = currentPosition + const Duration(seconds: 10);
                        audioHandler.seek(newPosition > totalDuration ? totalDuration : newPosition);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// --- pubspec.yaml dependencies (ensure these are in your project) ---
/*
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2 # Check for latest
  http: ^1.2.1     # Check for latest
  cached_network_image: ^3.3.1 # Check for latest
  just_audio: ^0.9.38 # Check for latest
  audio_service: ^0.18.12 # Check for latest
  just_audio_background: ^0.0.1-beta.11 # Helper for just_audio with audio_service
  webfeed_plus: ^1.0.2 # For parsing RSS/Atom feeds
  # shared_preferences: ^2.2.3 # No longer needed for podcast storage
  intl: ^0.19.0 # For date formatting
  sqflite: ^2.3.0 # Check for latest
  path_provider: ^2.0.0 # Check for latest
  path: ^1.8.0 # Check for latest


dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0 # Check for latest
*/

// --- Platform Specific Setup Notes ---
// ANDROID:
// 1. Update `android/app/src/main/AndroidManifest.xml`:
//    - Add permissions:
//      <uses-permission android:name="android.permission.WAKE_LOCK"/>
//      <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
//      <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/> (for Android 13+)
//    - Inside <application> tag, register the service and receiver (if using just_audio_background, it handles this):
//      <service android:name="com.ryanheise.just_audio_background.AudioService"
//          android:foregroundServiceType="mediaPlayback"
//          android:exported="true">
//        <intent-filter>
//          <action android:name="android.media.browse.MediaBrowserService"/>
//        </intent-filter>
//      </service>
//      <receiver android:name="com.ryanheise.just_audio_background.MediaButtonReceiver"
//          android:exported="true">
//        <intent-filter>
//          <action android:name="android.intent.action.MEDIA_BUTTON"/>
//        </intent-filter>
//      </receiver>
// 2. Ensure `compileSdkVersion` and `targetSdkVersion` in `android/app/build.gradle` are appropriate (e.g., 33 or higher).

// iOS:
// 1. Update `ios/Runner/Info.plist`:
//    - Add "Required background modes":
//      <key>UIBackgroundModes</key>
//      <array>
//        <string>audio</string>
//      </array>
