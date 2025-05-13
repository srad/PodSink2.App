import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:podsink2/app_state.dart';
import 'package:podsink2/main.dart';
import 'package:podsink2/models/episode.dart';
import 'package:podsink2/models/podcast.dart';
import 'package:podsink2/services/rss_parser_service.dart';
import 'package:podsink2/widgets/mini_player.dart';
import 'package:provider/provider.dart';

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
                      title: Text(episode.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
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
