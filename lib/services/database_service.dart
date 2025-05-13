import 'package:flutter/cupertino.dart';
import 'package:podsink2/models/played_history_item.dart';
import 'package:podsink2/models/podcast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

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