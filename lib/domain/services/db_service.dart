import 'package:drift/drift.dart';
import 'package:podsink2/data/datasources/app_database.dart';
import 'package:podsink2/data/datasources/dao/episodes_dao.dart';
import 'package:podsink2/data/datasources/dao/played_history_episode_dao.dart';
import 'package:podsink2/data/datasources/dao/podcasts_dao.dart';
import 'package:podsink2/domain/models/played_history_item.dart';
import 'package:podsink2/domain/models/podcast.dart';

class DriftDatabaseService {
  static final AppDatabase _db = AppDatabase(); // Drift database instance

  // DAOs
  static PodcastsDao get podcastsDao => _db.podcastsDao;
  static PlayedHistoryEpisodesDao get playedHistoryDao => _db.playedHistoryEpisodesDao;
  static EpisodesDao get episodesDao => _db.episodesDao;

  // Example: Subscribing a podcast (mapping domain model to Drift companion)
  Future<int> subscribePodcast(Podcast podcast) {
    final companion = PodcastsCompanion.insert(
      id: podcast.id,
      title: podcast.title,
      artistName: podcast.artistName,
      artworkUrl: podcast.artworkUrl,
      feedUrl: podcast.feedUrl,
      sortOrder: Value(podcast.sortOrder), // Use Value() for optional/defaulted fields
    );
    return podcastsDao.subscribePodcast(companion);
  }

  // Example: Getting podcasts (mapping DBO to domain model)
  Future<List<PodcastModel>> getSubscribedPodcasts() async {
    final dboList = await podcastsDao.getSubscribedPodcasts();
    return dboList.map((dbo) => PodcastModel(
      id: dbo.id,
      title: dbo.title,
      artistName: dbo.artistName,
      artworkUrl: dbo.artworkUrl,
      feedUrl: dbo.feedUrl,
      sortOrder: dbo.sortOrder,
    )).toList();
  }

  // --- Other podcast methods would follow a similar pattern ---
  Future<int> unsubscribePodcast(String id) => podcastsDao.unsubscribePodcast(id);
  Future<bool> isSubscribed(String id) => podcastsDao.isSubscribed(id);

  // --- History methods ---
  Future<int> addOrUpdateHistoryItem(PlayedEpisodeHistoryItemModel item) {
    final companion = PlayedHistoryEpisodesCompanion.insert(
      guid: item.guid,
      podcastTitle: item.podcastTitle,
      episodeTitle: item.episodeTitle,
      audioUrl: item.audioUrl,
      artworkUrl: Value(item.artworkUrl),
      totalDurationMs: Value(item.totalDurationMs),
      lastPositionMs: item.lastPositionMs,
      lastPlayedDate: item.lastPlayedDate,
    );
    return playedHistoryDao.addOrUpdateHistoryItem(companion);
  }

  Future<List<PlayedEpisodeHistoryItemModel>> getHistoryItems({int limit = 50, int offset = 0}) async {
    final dboList = await playedHistoryDao.getHistoryItems(limit: limit, offset: offset);
    return dboList.map((dbo) => PlayedEpisodeHistoryItemModel(
      guid: dbo.guid,
      podcastTitle: dbo.podcastTitle,
      episodeTitle: dbo.episodeTitle,
      audioUrl: dbo.audioUrl,
      artworkUrl: dbo.artworkUrl,
      totalDurationMs: dbo.totalDurationMs,
      lastPositionMs: dbo.lastPositionMs,
      lastPlayedDate: dbo.lastPlayedDate,
    )).toList();
  }

  Future<int> deleteHistoryItem(String guid) => playedHistoryDao.deleteHistoryItem(guid);
  Future<int> clearAllHistory() => playedHistoryDao.clearAllHistory();


  Future<void> close() async {
    await _db.close();
  }
}