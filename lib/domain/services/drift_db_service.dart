import 'dart:async';

import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';
import 'package:podsink2/data/datasources/app_database.dart';
import 'package:podsink2/data/datasources/dao/bookmarked_episodes_dao.dart';
import 'package:podsink2/data/datasources/dao/episodes_dao.dart';
import 'package:podsink2/data/datasources/dao/played_history_episode_dao.dart';
import 'package:podsink2/data/datasources/dao/podcasts_dao.dart';
import 'package:podsink2/domain/models/bookmarked_episode.dart';
import 'package:podsink2/domain/models/played_history_item.dart';
import 'package:podsink2/domain/models/podcast.dart';

// Translation from DBO to domain model mostly and other business logic.
class DriftDbService {
  static final AppDatabase _db = GetIt.I.get<AppDatabase>();

  static PodcastsDao get podcastsDao => _db.podcastsDao;
  static PlayedHistoryEpisodesDao get playedHistoryDao => _db.playedHistoryEpisodesDao;
  static EpisodesDao get episodesDao => _db.episodesDao;
  static BookmarkedEpisodesDao get bookmarkedEpisodesDao => _db.bookmarkedEpisodesDao;

  Future<PodcastModel?> subscribePodcast(PodcastModel podcast) async {
    final isSubscribed = await podcastsDao.isSubscribed(podcast.id);
    if (!isSubscribed) {
      final companion = PodcastsCompanion.insert(
        id: podcast.id,
        title: podcast.title,
        artistName: podcast.artistName,
        artworkUrl: podcast.artworkUrl,
        feedUrl: podcast.feedUrl,
        podcastUrl: Value(podcast.podcastUrl),
        lastViewed: Value(podcast.lastViewed),
        sortOrder: 0, // will be inserted by the dao.
      );
      final newPodcast = await podcastsDao.subscribePodcast(companion);
      return PodcastModel.fromPodcast(newPodcast);
    }
    return null;
  }

  Future<List<PodcastModel>> getSubscribedPodcasts() async {
    final podcasts = await podcastsDao.getSubscribedPodcasts();
    return podcasts.map((podcast) => PodcastModel.fromPodcast(podcast)).toList();
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
        description: Value(item.description),
        totalDurationMs: Value(item.totalDurationMs),
        lastPositionMs: item.lastPositionMs,
        lastPlayedDate: item.lastPlayedDate,//
    );

    return playedHistoryDao.addOrUpdateHistoryItem(companion);
  }

  Future<List<PlayedEpisodeHistoryItemModel>> getHistoryItems({int limit = 50, int offset = 0}) async {
    final dboList = await playedHistoryDao.getHistoryItems(limit: limit, offset: offset);
    return dboList
        .map(
          (dbo) => PlayedEpisodeHistoryItemModel(
            guid: dbo.guid,
            podcastTitle: dbo.podcastTitle,
            episodeTitle: dbo.episodeTitle,
            audioUrl: dbo.audioUrl,
            artworkUrl: dbo.artworkUrl,
            description: dbo.description,
            totalDurationMs: dbo.totalDurationMs,
            lastPositionMs: dbo.lastPositionMs,
            lastPlayedDate: dbo.lastPlayedDate, //
          ),
        )
        .toList();
  }

  Future<int> deleteHistoryItem(String guid) => playedHistoryDao.deleteHistoryItem(guid);

  Future<int> clearAllHistory() => playedHistoryDao.clearAllHistory();

  Future<void> subscribeToPodcast(PodcastModel podcast) async {
    final isAlreadySubscribed = await podcastsDao.isSubscribed(podcast.id);
    if (!isAlreadySubscribed) {
      await podcastsDao.subscribePodcast(
        PodcastsCompanion(
          id: Value(podcast.id),
          sortOrder: Value.absentIfNull(podcast.sortOrder),
          feedUrl: Value(podcast.feedUrl),
          title: Value(podcast.title),
          lastViewed: Value(podcast.lastViewed),
          podcastUrl: Value(podcast.podcastUrl),
          artistName: Value(podcast.artistName),
          artworkUrl: Value(podcast.artworkUrl), //
        ),
      );
    }
  }

  Future<DateTime?> bumpPodcastLastViewed(String id) async => await podcastsDao.bumpLastViewed(id);

  Future<void> unsubscribeFromPodcast(String id) async => await podcastsDao.unsubscribePodcast(id);

  Future<List<PodcastModel>> getPodcasts() async {
    final podcasts = await podcastsDao.getSubscribedPodcasts();
    return podcasts.map((podcast) => PodcastModel(id: podcast.id, title: podcast.title, sortOrder: podcast.sortOrder, artistName: podcast.artistName, artworkUrl: podcast.artworkUrl, feedUrl: podcast.feedUrl)).toList();
  }

  // --- History Methods ---
  Future<List<PlayedEpisodeHistoryItemModel>> getHistory() async {
    final history = await playedHistoryDao.getHistoryItems();

    return history
        .map(
          (item) => PlayedEpisodeHistoryItemModel(
            audioUrl: item.audioUrl,
            episodeTitle: item.episodeTitle,
            lastPlayedDate: item.lastPlayedDate,
            lastPositionMs: item.lastPositionMs,
            podcastTitle: item.podcastTitle,
            guid: item.guid,
            artworkUrl: item.artworkUrl,
            description: item.description,
            totalDurationMs: item.totalDurationMs, //
          ),
        )
        .toList();
  }

  Future<void> addEpisodeToHistory(PlayedEpisodeHistoryItemModel historyItem) async {
    // Only add/update if significant playback happened (e.g., > 5 seconds or not at the very beginning)
    if (historyItem.lastPositionMs > 5000 || (historyItem.totalDurationMs != null && historyItem.lastPositionMs >= historyItem.totalDurationMs! - 5000)) {
      await playedHistoryDao.addOrUpdateHistoryItem(
        PlayedHistoryEpisodesCompanion(
          guid: Value(historyItem.guid),
          totalDurationMs: Value(historyItem.totalDurationMs),
          podcastTitle: Value(historyItem.podcastTitle),
          lastPositionMs: Value(historyItem.lastPositionMs),
          lastPlayedDate: Value(historyItem.lastPlayedDate),
          episodeTitle: Value(historyItem.episodeTitle),
          audioUrl: Value(historyItem.audioUrl),
          artworkUrl: Value(historyItem.artworkUrl),
          description: Value(historyItem.description), //
        ),
      );
    }
  }

  Future<void> removeEpisodeFromHistory(String guid) async => await playedHistoryDao.deleteHistoryItem(guid);

  Future<void> clearAllPlayedHistory() async => await playedHistoryDao.clearAllHistory();

  Future<void> close() async => await _db.close();

  Future<void> swapPodcastSortOrder(String podcastIdA, String podcastIdB) async {
    await podcastsDao.swapPodcastSortOrder(podcastIdA, podcastIdB);
  }

  Future<List<BookmarkedEpisodeModel>> getBookmarkedEpisodes({int limit = 50, int offset = 0}) async {
    final dboList = await bookmarkedEpisodesDao.getEpisodes(limit: limit, offset: offset);
    return dboList
        .map(
          (dbo) => BookmarkedEpisodeModel(
            guid: dbo.guid,
            podcastTitle: dbo.podcastTitle,
            episodeTitle: dbo.episodeTitle,
            audioUrl: dbo.audioUrl,
            artworkUrl: dbo.artworkUrl,
            totalDurationMs: dbo.totalDurationMs,
            lastPositionMs: dbo.lastPositionMs,
            lastPlayedDate: dbo.lastPlayedDate,
            description: dbo.description,//
          ),
        )
        .toList();
  }

  Future<void> removeBookmark(String guid) async {
    await bookmarkedEpisodesDao.removeBookmark(guid);
  }

  Future<void> addOrReplaceBookmarkedEpisode(BookmarkedEpisodeModel episode) async {
    final companion = BookmarkedEpisodesCompanion.insert(
      guid: episode.guid,
      podcastTitle: episode.podcastTitle,
      episodeTitle: episode.episodeTitle,
      audioUrl: episode.audioUrl,
      lastPlayedDate: episode.lastPlayedDate,
      lastPositionMs: episode.lastPositionMs,
      artworkUrl: Value(episode.artworkUrl),
      description: Value(episode.description),
      totalDurationMs: Value(episode.totalDurationMs),//
    );
    await bookmarkedEpisodesDao.addOrReplaceBookmarkEpisode(companion);
  }

  Future<bool> isEpisodeBookmarked(String guid) async {
    return await bookmarkedEpisodesDao.isEpisodeBookmarked(guid);
  }
}
