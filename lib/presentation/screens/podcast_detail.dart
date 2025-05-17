import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/core/url_utils.dart';
import 'package:podsink2/domain/enums/loading_state.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/domain/models/podcast.dart';
import 'package:podsink2/domain/services/drift_db_service.dart';
import 'package:podsink2/domain/services/rss_parser_service.dart';
import 'package:podsink2/main.dart'; // kAppGradientBackground
import 'package:podsink2/presentation/shared_widgets/episode_item.dart';
import 'package:podsink2/presentation/shared_widgets/mini_player.dart';
import 'package:share_plus/share_plus.dart';

class PodcastDetailScreen extends StatefulWidget {
  final PodcastModel podcast;
  final bool isFromSearch;

  const PodcastDetailScreen({super.key, required this.podcast, this.isFromSearch = false});

  @override
  State<PodcastDetailScreen> createState() => _PodcastDetailScreenState();
}

class _PodcastDetailScreenState extends State<PodcastDetailScreen> {
  final ValueNotifier<PodcastModel?> _podcast = ValueNotifier(null);
  final _loadingState = ValueNotifier(LoadingState.idle);

  final _errorMessage = ValueNotifier('');
  final RssParserService _rssService = RssParserService();

  // Get AppState instance once
  late final AppState _appState;
  late final DriftDbService _dbService;

  @override
  void initState() {
    super.initState();
    _appState = GetIt.I<AppState>();
    _dbService = GetIt.I<DriftDbService>();
    _fetchPodcastEpisodes();
  }

  Future<void> _fetchPodcastEpisodes() async {
    if (!mounted) return;

    _loadingState.value = LoadingState.loading;
    _errorMessage.value = '';

    try {
      // Get the stored episodes.
      final subscribedPodcast = _appState.subscribedPodcastsNotifier.value.firstWhere((p) => p.id == widget.podcast.id, orElse: () => widget.podcast);

      if (!widget.isFromSearch) {
        // Update when this podcast has been viewed.
        final bumpedDateTime = await _dbService.bumpPodcastLastViewed(subscribedPodcast.id);
        subscribedPodcast.lastViewed = bumpedDateTime;
      }

      // Were this podcast's episodes already loaded in memory previously?
      if (subscribedPodcast.episodes.isNotEmpty) {
        _podcast.value = subscribedPodcast;
      } else {
        // Store in memory if not already fetched.
        final fetchedEpisodes = await _rssService.fetchEpisodes(widget.podcast);
        subscribedPodcast.episodes = fetchedEpisodes;
        subscribedPodcast.episodes = fetchedEpisodes;
        _podcast.value = subscribedPodcast;
      }
      _loadingState.value = LoadingState.loaded;
    } catch (e) {
      _errorMessage.value = 'Failed to load episodes: $e';
      _loadingState.value = LoadingState.failed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.podcast.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          ValueListenableBuilder(
            valueListenable: _appState.subscribedPodcastsNotifier, // Listen to the specific notifier
            builder: (context, subscribedPodcasts, child) {
              final isSubscribed = subscribedPodcasts.any((p) => p.id == widget.podcast.id);
              if (widget.isFromSearch && !isSubscribed) {
                return TextButton(
                  onPressed: () {
                    _appState.subscribeToPodcast(widget.podcast); // Use method from AppState
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Subscribed to ${widget.podcast.title}'), backgroundColor: Colors.deepPurple.shade900, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(10)), //
                    );
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
            ListTile(
              leading: CachedNetworkImage(
                imageUrl: widget.podcast.artworkUrl,
                fit: BoxFit.fill,
                placeholder:
                    (context, url) => Container(
                      color: Colors.white.withAlpha(25), // Adjusted for better contrast if kAppGradientBackground is dark
                      child: const Icon(Icons.music_note, size: 100, color: Colors.white54),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.white.withAlpha(25), // Adjusted
                      child: const Icon(Icons.broken_image, size: 100, color: Colors.white54),
                    ),
              ),
              title: Text(widget.podcast.title),
              subtitle: Container(
                margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                child: Row(
                  children: [
                    // --- Unsubscribe Button Logic ---
                    // This button's visibility should also react to subscription state
                    ValueListenableBuilder(
                      valueListenable: _appState.subscribedPodcastsNotifier,
                      builder: (context, podcast, child) {
                        final isSubscribed = _appState.subscribedPodcastsNotifier.value.any((p) => p.id == widget.podcast.id);

                        final subscribeButton = switch (isSubscribed) {
                          true => TextButton.icon(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                            label: const Text('Unsubscribe', style: TextStyle(fontSize: 14)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.red.withAlpha(230),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap, //
                            ),
                            onPressed: () {
                              _appState.unsubscribeFromPodcast(widget.podcast); // Assuming this method exists
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Unsubscribed from ${widget.podcast.title}'), backgroundColor: Colors.red.shade600, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(10)), //
                              );
                            },
                          ),
                          false => TextButton.icon(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                            label: const Text('Subscribe', style: TextStyle(fontSize: 14)),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.green.withAlpha(230),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap, //
                            ),
                            onPressed: () {
                              _appState.subscribeToPodcast(widget.podcast); // Assuming this method exists
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Subscribed to ${widget.podcast.title}'), backgroundColor: Colors.green.shade900, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(10)), //
                              );
                            },
                          ),
                        };

                        final shareButton = TextButton.icon(
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Share', style: TextStyle(fontSize: 14)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.purple.withAlpha(230),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap, //
                          ),
                          onPressed: () {
                            if (_podcast.value?.podcastUrl != null) {
                              SharePlus.instance.share(ShareParams(title: _podcast.value!.title, uri: Uri.parse(_podcast.value!.podcastUrl!)));
                            }
                          },
                        );

                        return Row(children: [subscribeButton, SizedBox(width: 10), shareButton]);
                      },
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: Colors.black.withAlpha(50), thickness: 2), // from Colors.black.withValues(alpha: 0.2)
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _loadingState,
                builder: (context, value, child) {
                  switch (value) {
                    case LoadingState.loading:
                      return const Center(child: CircularProgressIndicator());
                    case LoadingState.loaded:
                      if (_podcast.value == null) return const SizedBox.shrink();
                      if (_podcast.value!.episodes.isEmpty) {
                        return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('No episodes found for this podcast.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70))));
                      }
                      return _buildEpisodes(_podcast.value!.episodes);
                    case LoadingState.failed:
                      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage.value, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orangeAccent))));
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
            ValueListenableBuilder<EpisodeModel?>(
              valueListenable: _appState.currentEpisodeNotifier, // Assuming currentEpisodeNotifier or similar holds the current episode for MiniPlayer
              builder: (context, currentEpisode, child) {
                return currentEpisode != null ? MiniPlayer(currentEpisode: currentEpisode) : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodes(List<EpisodeModel> episodes) {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(color: Colors.transparent, height: 4),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 6.0),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];

        return ValueListenableBuilder<EpisodeModel?>(
          valueListenable: _appState.currentEpisodeNotifier,
          builder: (context, notifyEpisode, child) {
            return ValueListenableBuilder<bool>(
              valueListenable: _appState.isPlayingNotifier,
              builder: (context, isPlayingAudioService, child) {
                final currentEpisode = notifyEpisode ?? episode;
                final isCurrent = currentEpisode.guid == episode.guid || currentEpisode.audioUrl == episode.audioUrl;
                final isPlaying = isCurrent && isPlayingAudioService;
                episode.artworkUrl ??= widget.podcast.artworkUrl;

                return EpisodeItem(episode: episode, isCurrent: isCurrent, isPlaying: isPlaying);
              },
            );
          },
        );
      },
    );
  }
}
