import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsink2/app_state.dart';
import 'package:podsink2/main.dart';
import 'package:podsink2/models/episode.dart';
import 'package:podsink2/models/podcast.dart';
import 'package:podsink2/screens/podcast_detail.dart';
import 'package:podsink2/services/itunes_service.dart';
import 'package:podsink2/widgets/mini_player.dart';
import 'package:provider/provider.dart';

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
                        hintText: 'Search podcasts ...',
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
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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

