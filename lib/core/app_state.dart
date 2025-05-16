import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter/cupertino.dart';
import 'package:podsink2/core/audio_handler_implementation.dart';
import 'package:podsink2/data/datasources/app_database.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/domain/models/played_history_item.dart';
import 'package:podsink2/domain/models/podcast.dart';
import 'package:podsink2/domain/services/rss_parser_service.dart';

class AppState extends ChangeNotifier {
  final AudioPlayerHandlerImpl _audioHandler;
  List<PodcastModel> _subscribedPodcasts = [];
  List<PlayedEpisodeHistoryItemModel> _playedHistory = [];
  List<EpisodeModel> _latestEpisodes = [];
  List<EpisodeModel> _bookmarkedEpisodes = [];

  StreamSubscription? _mediaItemSubscription;
  StreamSubscription? _playbackStateSubscription;

  final _rssService = RssParserService();
  final _database = AppDatabase();

  MediaItem? _previousMediaItemForHistory;
  Duration _previousMediaItemLastPosition = Duration.zero;

  EpisodeModel? get currentEpisodeFromAudioService {
    final mediaItem = _audioHandler.mediaItem.value;
    if (mediaItem == null) return null;
    return _episodeFromMediaItem(mediaItem);
  }

  bool get isPlayingFromAudioService => _audioHandler.playbackState.value.playing;

  List<PodcastModel> get subscribedPodcasts => _subscribedPodcasts;

  List<PlayedEpisodeHistoryItemModel> get playedHistory => _playedHistory;

  List<EpisodeModel> get latestEpisodes => _latestEpisodes;

  List<EpisodeModel> get bookmarkedEpisodes => _bookmarkedEpisodes;

  AppState(this._audioHandler) {
    _initializeState();
  }

  Future<void> _initializeState() async {
    await loadSubscribedPodcasts();
    await loadPlayedHistory();

    _playbackStateSubscription = _audioHandler.playbackState.listen((playbackState) {
      _updateHistoryForCurrentEpisode(playbackState); // Handles specific events like 'completed'
      if (playbackState.updatePosition.inSeconds % 10 == 0) {
        final mediaItem = _audioHandler.mediaItem.value;
        if (mediaItem != null) {
          _handleMediaItemChangeForHistory(mediaItem, playbackState);
        }
      }
      notifyListeners();
    });
  }

  EpisodeModel? _episodeFromMediaItem(MediaItem mediaItem) {
    for (var podcast in _subscribedPodcasts) {
      if (podcast.episodes.isNotEmpty) {
        for (var episode in podcast.episodes) {
          if ((mediaItem.extras?['guid'] != null && episode.guid == mediaItem.extras!['guid']) || episode.audioUrl == mediaItem.id) {
            return EpisodeModel(
              guid: episode.guid,
              podcastTitle: episode.podcastTitle,
              title: episode.title,
              description: mediaItem.extras?['description'] ?? episode.description,
              audioUrl: episode.audioUrl,
              pubDate: episode.pubDate,
              artworkUrl: episode.artworkUrl,
              duration: episode.duration, //
            );
          }
        }
      }
    }
    // Fallback if episode not in subscribed list (e.g. played from search before full details fetched)
    return EpisodeModel(
      guid: mediaItem.extras?['guid'] as String? ?? mediaItem.id,
      podcastTitle: mediaItem.album ?? mediaItem.extras?['podcastTitle'] ?? 'Unknown Podcast',
      title: mediaItem.title ?? 'Unknown Title',
      description: mediaItem.extras?['description'] as String? ?? 'Description not available.',
      audioUrl: mediaItem.id,
      artworkUrl: mediaItem.artUri?.toString() ?? mediaItem.extras?['artworkUrl'],
      duration: mediaItem.duration, //
    );
  }

  Future<void> subscribeToPodcast(PodcastModel podcast) async {
    final isAlreadySubscribed = await _database.podcastsDao.isSubscribed(podcast.id);
    if (!isAlreadySubscribed) {
      await _database.podcastsDao.subscribePodcast(
        PodcastsCompanion(
          id: Value(podcast.id),
          sortOrder: Value.absentIfNull(podcast.sortOrder),
          feedUrl: Value(podcast.feedUrl),
          title: Value(podcast.title),
          artistName: Value(podcast.artistName),
          artworkUrl: Value(podcast.artworkUrl), //
        ),
      );
      _subscribedPodcasts.add(podcast);
      _subscribedPodcasts.sort((a, b) => a.title.compareTo(b.title));
      notifyListeners();
    } else {
      debugPrint("Podcast ${podcast.title} is already subscribed.");
    }
  }

  Future<void> unsubscribeFromPodcast(PodcastModel podcast) async {
    await _database.podcastsDao.unsubscribePodcast(podcast.id);
    _subscribedPodcasts.removeWhere((p) => p.id == podcast.id);
    notifyListeners();
  }

  Future<void> loadSubscribedPodcasts() async {
    final podcasts = await _database.podcastsDao.getSubscribedPodcasts();

    _subscribedPodcasts =
        podcasts
            .map(
              (podcast) => PodcastModel(id: podcast.id, title: podcast.title, sortOrder: podcast.sortOrder, artistName: podcast.artistName, artworkUrl: podcast.artworkUrl, feedUrl: podcast.feedUrl), //
            )
            .toList();

    notifyListeners();
    debugPrint("Loaded ${_subscribedPodcasts.length} subscribed podcasts from DB.");
  }

  // --- History Methods ---
  Future loadPlayedHistory() async {
    final history = await _database.playedHistoryEpisodesDao.getHistoryItems();
    _playedHistory =
        history
            .map(
              (item) => PlayedEpisodeHistoryItemModel(
                audioUrl: item.audioUrl,
                episodeTitle: item.episodeTitle,
                lastPlayedDate: item.lastPlayedDate,
                lastPositionMs: item.lastPositionMs,
                podcastTitle: item.podcastTitle,
                guid: item.guid,
                artworkUrl: item.artworkUrl,
                totalDurationMs: item.totalDurationMs, //
              ),
            )
            .toList();

    notifyListeners();
    debugPrint("Loaded ${_playedHistory.length} history items from DB.");
  }

  Future<void> addEpisodeToHistory(PlayedEpisodeHistoryItemModel historyItem) async {
    // Only add/update if significant playback happened (e.g., > 5 seconds or not at the very beginning)
    if (historyItem.lastPositionMs > 5000 || (historyItem.totalDurationMs != null && historyItem.lastPositionMs >= historyItem.totalDurationMs! - 5000)) {
      await _database.playedHistoryEpisodesDao.addOrUpdateHistoryItem(
        PlayedHistoryEpisodesCompanion(
          guid: Value(historyItem.guid),
          totalDurationMs: Value(historyItem.totalDurationMs),
          podcastTitle: Value(historyItem.podcastTitle),
          lastPositionMs: Value(historyItem.lastPositionMs),
          lastPlayedDate: Value(historyItem.lastPlayedDate),
          episodeTitle: Value(historyItem.episodeTitle),
          audioUrl: Value(historyItem.audioUrl),
          artworkUrl: Value(historyItem.artworkUrl), //
        ),
      );
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
    await _database.playedHistoryEpisodesDao.deleteHistoryItem(guid);
    _playedHistory.removeWhere((item) => item.guid == guid);
    notifyListeners();
  }

  Future<void> clearAllPlayedHistory() async {
    await _database.playedHistoryEpisodesDao.clearAllHistory();
    _playedHistory.clear();
    notifyListeners();
    debugPrint("Cleared all played history.");
  }

  void _handleMediaItemChangeForHistory(MediaItem? newMediaItem, PlaybackState currentPlaybackState) {
    if (_previousMediaItemForHistory != null) {
      // Save history for the episode that just finished or was changed
      final previousEpisode = _episodeFromMediaItem(_previousMediaItemForHistory!);
      if (previousEpisode != null) {
        final historyItem = PlayedEpisodeHistoryItemModel(
          guid: previousEpisode.guid,
          podcastTitle: previousEpisode.podcastTitle,
          episodeTitle: previousEpisode.title,
          audioUrl: previousEpisode.audioUrl,
          artworkUrl: previousEpisode.artworkUrl,
          totalDurationMs: _previousMediaItemForHistory!.duration?.inMilliseconds,
          lastPositionMs: _previousMediaItemLastPosition.inMilliseconds,
          lastPlayedDate: DateTime.now(), //
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
      if ((!playbackState.playing && playbackState.position > const Duration(seconds: 5)) || playbackState.processingState == AudioProcessingState.completed) {
        final episode = _episodeFromMediaItem(currentMediaItem);
        if (episode != null) {
          final historyItem = PlayedEpisodeHistoryItemModel(
            guid: episode.guid,
            podcastTitle: episode.podcastTitle,
            episodeTitle: episode.title,
            audioUrl: episode.audioUrl,
            artworkUrl: episode.artworkUrl,
            totalDurationMs: currentMediaItem.duration?.inMilliseconds,
            lastPositionMs: playbackState.position.inMilliseconds,
            lastPlayedDate: DateTime.now(), //
          );
          addEpisodeToHistory(historyItem);
        }
      }
    }
  }

  Future<void> playEpisode(EpisodeModel episode) async {
    // When a new episode starts, log the previous one if it was playing
    final currentMedia = _audioHandler.mediaItem.value;
    if (currentMedia != null && currentMedia.id != episode.audioUrl) {
      final prevEpisode = _episodeFromMediaItem(currentMedia);
      if (prevEpisode != null) {
        addEpisodeToHistory(
          PlayedEpisodeHistoryItemModel(
            guid: prevEpisode.guid,
            podcastTitle: prevEpisode.podcastTitle,
            episodeTitle: prevEpisode.title,
            audioUrl: prevEpisode.audioUrl,
            artworkUrl: prevEpisode.artworkUrl,
            totalDurationMs: currentMedia.duration?.inMilliseconds,
            lastPositionMs: _audioHandler.playbackState.value.position.inMilliseconds,
            lastPlayedDate: DateTime.now(), //
          ),
        );
      }
    }

    await _audioHandler.setQueue([episode.toMediaItem()]);
    await _audioHandler.play();
    // Also log this episode as starting (or update it)
    addEpisodeToHistory(
      PlayedEpisodeHistoryItemModel(
        guid: episode.guid,
        podcastTitle: episode.podcastTitle,
        episodeTitle: episode.title,
        audioUrl: episode.audioUrl,
        artworkUrl: episode.artworkUrl,
        totalDurationMs: episode.duration?.inMilliseconds,
        lastPositionMs: 0,
        // Starts at 0
        lastPlayedDate: DateTime.now(), //
      ),
    );
  }

  Future<void> resumeEpisodeFromHistory(PlayedEpisodeHistoryItemModel historyItem) async {
    // Reconstruct a minimal Episode object or find it if already loaded
    final episodeToPlay = EpisodeModel(
      guid: historyItem.guid,
      podcastTitle: historyItem.podcastTitle,
      title: historyItem.episodeTitle,
      description: '',
      // Description not crucial for resuming, but could be fetched
      audioUrl: historyItem.audioUrl,
      artworkUrl: historyItem.artworkUrl,
      duration: historyItem.totalDurationMs != null ? Duration(milliseconds: historyItem.totalDurationMs!) : null, //
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
    _database.close();
    super.dispose();
  }

  Future reorderSubscribedPodcasts(int oldIndex, int newIndex) async {
    throw UnimplementedError();
  }

  Future loadBookmarks() async {}

  Future loadLatestEpisodes() async {
    final podcasts = await _database.podcastsDao.getSubscribedPodcasts();
    _latestEpisodes.clear();

    for(final podcast in podcasts) {
      try {
        final fetchedEpisodes = await _rssService.fetchEpisodes(PodcastModel(
          id: podcast.id,
          artworkUrl: podcast.artworkUrl,
          sortOrder: podcast.sortOrder,
          artistName: podcast.artistName,
          title: podcast.title,
          feedUrl: podcast.feedUrl, //
        ));

        final firstEpisode = fetchedEpisodes.firstOrNull;
        if (firstEpisode != null) {
          _latestEpisodes.add(firstEpisode);
        }
      } catch(e) {
        debugPrint('$e');
      }
    }
  }
}
