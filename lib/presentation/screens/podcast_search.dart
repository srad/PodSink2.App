import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/domain/models/podcast.dart';
import 'package:podsink2/domain/services/itunes_service.dart';
import 'package:podsink2/main.dart';
import 'package:podsink2/presentation/screens/podcast_detail.dart';
import 'package:podsink2/presentation/shared_widgets/mini_player.dart';

class PodcastSearchScreen extends StatefulWidget {
  const PodcastSearchScreen({super.key});

  @override
  State<PodcastSearchScreen> createState() => _PodcastSearchScreenState();
}

class _PodcastSearchScreenState extends State<PodcastSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ItunesService _itunesService = ItunesService();
  List<PodcastModel> _searchResults = [];
  bool _isLoading = false;
  String _message = 'Search iTunes for podcasts.';

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _message = 'Please enter a search term.';
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _message = '';
      _searchResults = [];
    });
    try {
      final results = await _itunesService.searchPodcasts(_searchController.text.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          if (results.isEmpty) _message = 'No podcasts found for "${_searchController.text.trim()}".';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _message = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = GetIt.I<AppState>(); // Fetch once

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
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search podcasts ...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                        suffixIcon:
                            _searchController.text.isNotEmpty
                                ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.white.withValues(alpha: 0.7)),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _message = 'Search for podcasts on iTunes.';
                                    });
                                  },
                                )
                                : null,
                      ),
                      onSubmitted: (_) => _performSearch(),
                      textInputAction: TextInputAction.search,
                    ),
                  ),
                  if (_isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: Colors.white)))
                  else if (_message.isNotEmpty && _searchResults.isEmpty)
                    Expanded(child: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)))))
                  else
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final podcast = _searchResults[index];
                          final size = 65.0;

                          return Card(
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6.0),
                                child: CachedNetworkImage(
                                  imageUrl: podcast.artworkUrl,
                                  width: size,
                                  height: size,
                                  fit: BoxFit.cover,
                                  //
                                  placeholder:
                                      (c, u) => Container(
                                        width: size,
                                        height: size,
                                        color: Colors.white.withValues(alpha: 0.1), //
                                        child: const Icon(Icons.image_search, color: Colors.white54),
                                      ),
                                  errorWidget:
                                      (c, u, e) => Container(
                                        width: size,
                                        height: size,
                                        color: Colors.white.withValues(alpha: 0.1),
                                        child: const Icon(Icons.broken_image, color: Colors.white54), //
                                      ),
                                ),
                              ),
                              title: Text(podcast.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
                              subtitle: Text(podcast.artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.8))),
                              // MODIFIED SECTION for the trailing IconButton
                              trailing: ValueListenableBuilder<List<PodcastModel>>(
                                valueListenable: appState.subscribedPodcastsNotifier,
                                builder: (context, subscribedPodcastsValue, child) {
                                  final isSubscribed = subscribedPodcastsValue.any((p) => p.id == podcast.id);

                                  return IconButton(
                                    icon: Icon(isSubscribed ? Icons.check_circle : Icons.add_circle_outline, color: isSubscribed ? Colors.greenAccent : Colors.white70, size: 28),
                                    tooltip: isSubscribed ? 'Subscribed' : 'Subscribe',
                                    onPressed: () {
                                      // Get AppState for actions (can be the same instance as above or fetched again)
                                      if (!isSubscribed)
                                        appState.subscribeToPodcast(podcast);
                                      else
                                        appState.unsubscribeFromPodcast(podcast);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${isSubscribed ? "Unsubscribed from" : "Subscribed to"} ${podcast.title}'),
                                          // ... other SnackBar properties
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PodcastDetailScreen(podcast: podcast, isFromSearch: true))), // Use context from itemBuilder
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            ValueListenableBuilder<EpisodeModel?>(
              valueListenable: GetIt.I<AppState>().currentEpisodeNotifier,
              builder: (context, currentEpisodeValue, child) {
                return currentEpisodeValue != null ? MiniPlayer(currentEpisode: currentEpisodeValue) : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
