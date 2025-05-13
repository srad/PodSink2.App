import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsink2/app_state.dart';
import 'package:podsink2/main.dart';
import 'package:podsink2/models/episode.dart';
import 'package:podsink2/models/podcast.dart';
import 'package:podsink2/screens/podcast_detail.dart';
import 'package:podsink2/screens/podcast_search.dart';
import 'package:podsink2/widgets/app_drawer.dart';
import 'package:podsink2/widgets/confirm_dialog.dart';
import 'package:podsink2/widgets/mini_player.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController(text: "");
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

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
                      : AnimatedList(
                    key: _listKey,
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8), // Adjust top padding for AppBar
                    initialItemCount: subscribedPodcasts.length,
                    itemBuilder: (context, index, animation) {
                      final podcast = subscribedPodcasts[index];
                      return _buildPodcastItem(podcast, appState, index, animation);
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

  Widget _buildPodcastItem(final Podcast podcast, final AppState appState, final int index, final Animation<double> animation) {
    return SizeTransition(
        sizeFactor: animation,
        child: Card( // Card styling will be picked from theme
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
            //
            subtitle: Text(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                podcast.artistName, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PodcastDetailScreen(podcast: podcast))),
            trailing: IconButton(onPressed: () => _performRemovePodcast(podcast, appState, index),
                icon: Icon(Icons.remove_circle_rounded)), //
          ),
        ));
  }

  void _performRemovePodcast(final Podcast podcast, final AppState appState, final int index) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Confirm',
        content: 'Unsubscribe from "${podcast.title}" podcast?',
        onConfirm: () {
          appState.unsubscribeFromPodcast(podcast);
          _listKey.currentState!.removeItem(index, (context, animation) => _buildPodcastItem(podcast, appState, index, animation),
            duration: Duration(milliseconds: 300),
          );
        },
      ),
    );
  }
}
