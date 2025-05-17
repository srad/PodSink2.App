import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:podsink2/core/audio_handler_implementation.dart';
import 'package:podsink2/domain/models/bookmarked_episode.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/domain/models/played_history_item.dart';
import 'package:podsink2/domain/models/podcast.dart';
import 'package:podsink2/domain/services/drift_db_service.dart';
import 'package:podsink2/domain/services/rss_parser_service.dart';

class AppState implements Disposable {
  final AudioPlayerHandlerImpl _audioHandler;
  final DriftDbService _dbService;

  final ValueNotifier<List<PodcastModel>> subscribedPodcastsNotifier = ValueNotifier([]);
  final ValueNotifier<EpisodeModel?> currentEpisodeNotifier = ValueNotifier(null);
  final ValueNotifier<List<EpisodeModel>> latestEpisodesNotifier = ValueNotifier([]);
  final ValueNotifier<List<BookmarkedEpisodeModel>> bookmarkedEpisodesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> isPlayingNotifier;
  final ValueNotifier<List<PlayedEpisodeHistoryItemModel>> playedHistoryNotifier = ValueNotifier([]);

  StreamSubscription? _mediaItemSubscription;
  StreamSubscription? _playbackStateSubscription;

  final RssParserService _rssService = RssParserService();

  MediaItem? _previousMediaItemForHistory;
  Duration _previousMediaItemLastPosition = Duration.zero;

  AppState(this._audioHandler, this._dbService) : isPlayingNotifier = ValueNotifier(_audioHandler.playbackState.value.playing) {
    _initializeState();
  }

  void _initializeState() {
    _mediaItemSubscription = _audioHandler.mediaItem.listen((mediaItem) {
      _updateCurrentEpisodeNotifier(mediaItem);
      _handleMediaItemChangeForHistory(mediaItem, _audioHandler.playbackState.value);
    });

    _playbackStateSubscription = _audioHandler.playbackState.listen((playbackState) {
      _updateIsPlayingNotifier(playbackState);
      _updateHistoryForCurrentEpisode(playbackState);
      if (playbackState.updatePosition.inSeconds % 10 == 0) {
        final mediaItem = _audioHandler.mediaItem.value;
        if (mediaItem != null) {
          _handleMediaItemChangeForHistory(mediaItem, playbackState);
        }
      }
    });

    // Initial update for current episode
    _updateCurrentEpisodeNotifier(_audioHandler.mediaItem.value);
  }

  void _updateIsPlayingNotifier(PlaybackState playbackState) {
    final newIsPlaying = playbackState.playing && playbackState.processingState != AudioProcessingState.completed && playbackState.processingState != AudioProcessingState.idle;
    if (isPlayingNotifier.value != newIsPlaying) {
      isPlayingNotifier.value = newIsPlaying;
    }
  }

  Future<void> loadPlayedHistory() async {
    final history = await _dbService.getHistory();
    playedHistoryNotifier.value = history;
  }

  Future<void> addEpisodeToHistory(PlayedEpisodeHistoryItemModel historyItem) async {
    if (historyItem.lastPositionMs > 5000 || (historyItem.totalDurationMs != null && historyItem.lastPositionMs >= historyItem.totalDurationMs! - 5000)) {
      // Assuming dbService handles the actual add/update persistently
      await _dbService.addOrUpdateHistoryItem(historyItem);

      final currentHistory = List<PlayedEpisodeHistoryItemModel>.from(playedHistoryNotifier.value);
      final index = currentHistory.indexWhere((item) => item.guid == historyItem.guid);
      if (index != -1) {
        currentHistory[index] = historyItem;
      } else {
        currentHistory.add(historyItem);
      }
      currentHistory.sort((a, b) => b.lastPlayedDate.compareTo(a.lastPlayedDate));
      playedHistoryNotifier.value = currentHistory;
    }
  }

  Future<void> removeEpisodeFromHistory(String guid) async {
    await _dbService.removeEpisodeFromHistory(guid);
    playedHistoryNotifier.value.removeWhere((item) => item.guid == guid);
  }

  void _updateCurrentEpisodeNotifier(MediaItem? mediaItem) {
    if (mediaItem == null) {
      currentEpisodeNotifier.value = null;
    } else {
      currentEpisodeNotifier.value = _episodeFromMediaItem(mediaItem);
    }
  }

  EpisodeModel? _episodeFromMediaItem(MediaItem mediaItem) {
    // Find in subscribed podcasts first
    for (var podcast in subscribedPodcastsNotifier.value) {
      // Use internal _subscribedPodcasts
      final episode = podcast.episodes.firstWhere((ep) => (mediaItem.extras?['guid'] != null && ep.guid == mediaItem.extras!['guid']) || ep.audioUrl == mediaItem.id);
      if (episode.guid.isNotEmpty) {
        // Check if a valid episode was found
        return EpisodeModel(guid: episode.guid, podcastTitle: episode.podcastTitle, title: episode.title, description: episode.description, audioUrl: episode.audioUrl, pubDate: episode.pubDate, artworkUrl: episode.artworkUrl, duration: episode.duration);
      }
    }

    // Fallback if not found in subscribed list or for partial data
    if (mediaItem.id.isEmpty) return null; // Cannot create an episode without an ID

    return EpisodeModel(
      guid: mediaItem.extras?['guid'] as String? ?? mediaItem.id,
      podcastTitle: mediaItem.album ?? mediaItem.extras?['podcastTitle'] as String? ?? 'Unknown Podcast',
      title: mediaItem.title,
      description: mediaItem.extras?['description'] as String? ?? 'Description not available.',
      audioUrl: mediaItem.id,
      artworkUrl: mediaItem.artUri?.toString() ?? mediaItem.extras?['artworkUrl'] as String?,
      duration: mediaItem.duration,
      pubDate: mediaItem.extras?['pubDate'] != null ? DateTime.tryParse(mediaItem.extras!['pubDate']) : null, //
    );
  }

  Future<void> subscribeToPodcast(PodcastModel podcast) async {
    final insertedPodcast = await _dbService.subscribePodcast(podcast);
    if (insertedPodcast != null) {
      subscribedPodcastsNotifier.value = [...subscribedPodcastsNotifier.value, insertedPodcast];
    }
  }

  Future<void> unsubscribeFromPodcast(PodcastModel podcast) async {
    await _dbService.unsubscribeFromPodcast(podcast.id);

    subscribedPodcastsNotifier.value =
        subscribedPodcastsNotifier.value
            .where((p) => p.id != podcast.id) //
            .toList();
  }

  Future<void> loadSubscribedPodcasts() async {
    final podcastsFromDb = await _dbService.getSubscribedPodcasts();
    subscribedPodcastsNotifier.value = podcastsFromDb;
  }

  Future<void> addEpisodeBookmark(BookmarkedEpisodeModel episode) async {
    await _dbService.addOrReplaceBookmarkedEpisode(episode);
    final index = bookmarkedEpisodesNotifier.value.indexWhere((item) => item.guid == episode.guid);

    if (index != -1) {
      // Replace
      final copy = List<BookmarkedEpisodeModel>.from(bookmarkedEpisodesNotifier.value);
      copy[index] = episode;
      bookmarkedEpisodesNotifier.value = copy;
    } else {
      // Add new
      bookmarkedEpisodesNotifier.value = [...bookmarkedEpisodesNotifier.value, episode];
    }
  }

  Future<void> removeEpisodeBookmark(String guid) async {
    await _dbService.removeBookmark(guid);

    bookmarkedEpisodesNotifier.value = bookmarkedEpisodesNotifier.value.where((item) => item.guid != guid).toList();
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
  }

  Future<void> swapPodcastsSortOrder(int oldIndex, int newIndex) async {
    // 1. Validate indices
    if (oldIndex < 0 || oldIndex >= subscribedPodcastsNotifier.value.length || newIndex < 0 || newIndex >= subscribedPodcastsNotifier.value.length) {
      debugPrint("Error: Invalid indices. Old: $oldIndex, New: $newIndex, Length: ${subscribedPodcastsNotifier.value.length}");
      // For invalid arguments, throwing an ArgumentError here is appropriate
      // as it's a precondition violation, not a runtime failure of an external system.
      throw ArgumentError("Invalid indices provided for swapping podcasts.");
    }

    final String podcastIdAtOldIndex = subscribedPodcastsNotifier.value[oldIndex].id;
    final String podcastIdAtNewIndex = subscribedPodcastsNotifier.value[newIndex].id;

    // 2. Attempt to persist the swap in the database.
    //    If _dbService.swapPodcastSortOrder throws an exception, it will propagate up.
    await _dbService.swapPodcastSortOrder(podcastIdAtOldIndex, podcastIdAtNewIndex);

    // 3. If DB was successful, update the notifier.
    final currentPodcasts = List<PodcastModel>.from(subscribedPodcastsNotifier.value);
    final PodcastModel podcastToMove = currentPodcasts.removeAt(oldIndex);
    int actualInsertionIndex = (oldIndex < newIndex) ? newIndex - 1 : newIndex;
    currentPodcasts.insert(actualInsertionIndex, podcastToMove);
    subscribedPodcastsNotifier.value = currentPodcasts;
  }

  // Load from all feeds the first entry. This is rather slow, because for each podcast the entire feed is fetched.
  Future<void> loadLatestEpisodes() async {
    final podcasts = await _dbService.getSubscribedPodcasts();
    List<EpisodeModel> episodes = [];

    for (final podcast in podcasts) {
      try {
        final fetchedEpisodes = await _rssService.fetchEpisodes(
          PodcastModel(
            id: podcast.id,
            artworkUrl: podcast.artworkUrl,
            sortOrder: podcast.sortOrder,
            artistName: podcast.artistName,
            title: podcast.title,
            feedUrl: podcast.feedUrl, //
          ),
        );

        final firstEpisode = fetchedEpisodes.firstOrNull;
        if (firstEpisode != null) {
          episodes.add(firstEpisode);
        }
      } catch (e) {
        debugPrint('$e');
      }
    }
    latestEpisodesNotifier.value = episodes;
  }

  Future<void> loadBookmarks() async {
    bookmarkedEpisodesNotifier.value = await _dbService.getBookmarkedEpisodes();
  }

  @override
  FutureOr onDispose() {
    if (_audioHandler.mediaItem.value != null && _audioHandler.playbackState.value.position > Duration.zero) {
      _updateHistoryForCurrentEpisode(_audioHandler.playbackState.value);
    }
    _mediaItemSubscription?.cancel();
    _playbackStateSubscription?.cancel();

    // Dispose ValueNotifiers
    subscribedPodcastsNotifier.dispose();
    currentEpisodeNotifier.dispose();
    bookmarkedEpisodesNotifier.dispose();
    playedHistoryNotifier.dispose();
    isPlayingNotifier.dispose();
  }

  Future<bool> isEpisodeBookmarked(EpisodeModel episode) async => await _dbService.isEpisodeBookmarked(episode.guid);
}
