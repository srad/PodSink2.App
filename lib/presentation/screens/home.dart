import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/domain/enums/loading_state.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/domain/models/podcast.dart';
import 'package:podsink2/main.dart';
import 'package:podsink2/presentation/screens/playing_history.dart';
import 'package:podsink2/presentation/screens/podcast_detail.dart';
import 'package:podsink2/presentation/screens/podcast_search.dart';
import 'package:podsink2/presentation/shared_widgets/app_drawer.dart';
import 'package:podsink2/presentation/shared_widgets/confirm_dialog.dart';
import 'package:podsink2/presentation/shared_widgets/episode_item.dart';
import 'package:podsink2/presentation/shared_widgets/mini_player.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController(text: "");
  late TabController _tabController;

  final ValueNotifier<LoadingState> _historyLoadingState = ValueNotifier(LoadingState.idle);
  final ValueNotifier<LoadingState> _latestEpisodesLoadingState = ValueNotifier(LoadingState.idle);
  final ValueNotifier<LoadingState> _bookmarkedEpisodesLoadingState = ValueNotifier(LoadingState.idle);
  final ValueNotifier<LoadingState> _subscribedPodcastsLoadingState = ValueNotifier(LoadingState.idle);

  // State variable to toggle reordering mode
  bool _isReordering = false;

  void _toggleReorder() {
    setState(() {
      _isReordering = !_isReordering;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isReordering ? 'Reordering enabled' : 'Reordering disabled'), duration: const Duration(seconds: 2)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      // This adjustment is needed if the item is moved downwards
      // in the list, because removing it first shifts the indices.
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      Provider.of<AppState>(context, listen: false).reorderSubscribedPodcasts(oldIndex, newIndex);
      //final String item = _podcasts.removeAt(oldIndex);
      //_podcasts.insert(newIndex, item);
    });
  }

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {}); // Rebuild to filter subscription list
    });

    _loadLatestEpisodes();

    _tabController.addListener(() {
      // Call setState to rebuild AppBar actions (e.g., show/hide reorder button)
      // and to trigger loading for newly selected tabs.
      setState(() {
        if (!_tabController.indexIsChanging) {
          // Ensure action is taken when tab selection is settled
          int currentIndex = _tabController.index;

          switch (currentIndex) {
            case 0:
              if (_latestEpisodesLoadingState.value == LoadingState.idle) {
                _loadLatestEpisodes();
              }
            case 1:
              if (_subscribedPodcastsLoadingState.value == LoadingState.idle) {
                _loadSubscriptions();
              }
            case 2:
              if (_historyLoadingState.value == LoadingState.idle) {
                _loadHistoryData();
              }
            case 3:
              if (_bookmarkedEpisodesLoadingState.value == LoadingState.idle) {
                _loadBookmarkedData();
              }
          }
        }
      });
    });
  }

  Future _loadLatestEpisodes() async {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);
    _latestEpisodesLoadingState.value = LoadingState.loading;
    await appState.loadLatestEpisodes();
    _latestEpisodesLoadingState.value = LoadingState.loaded;
  }

  Future _loadSubscriptions() async {
    if (!mounted) return;

    _subscribedPodcastsLoadingState.value = LoadingState.loading;
    final appState = Provider.of<AppState>(context, listen: false);
    appState.loadSubscribedPodcasts();
    _subscribedPodcastsLoadingState.value = LoadingState.loaded;
  }

  Future<void> _loadHistoryData() async {
    if (!mounted) return;
    _historyLoadingState.value = LoadingState.loading;

    if (!mounted) return;

    // Replace with actual data fetching logic
    final appState = Provider.of<AppState>(context, listen: false);
    await appState.loadPlayedHistory();
    _historyLoadingState.value = LoadingState.loaded;
  }

  Future<void> _loadBookmarkedData() async {
    if (!mounted) return;
    _bookmarkedEpisodesLoadingState.value = LoadingState.loading;

    final appState = Provider.of<AppState>(context, listen: false);
    await appState.loadBookmarks();
    _bookmarkedEpisodesLoadingState.value = LoadingState.loaded;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final subscribedPodcasts = appState.subscribedPodcasts.where((p) => p.title.toLowerCase().contains(_searchController.text.toLowerCase()) || p.artistName.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    final List<EpisodeModel> latestEpisodes = appState.latestEpisodes.toList();

    return Stack(
      children: [
        // Gradient background covering the whole screen
        Positioned.fill(child: Container(decoration: kAppGradientBackground)),

        // Your Scaffold on top
        Scaffold(
          appBar: AppBar(
            title: Row(children: [const Text('PodSink'), Spacer(), Image(height: 40, width: 40, image: AssetImage('assets/icons/podsink.png'))]),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add new podcast',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PodcastSearchScreen())), //
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              // Color of the selection indicator
              labelColor: Colors.white,
              // Color of the selected tab label
              unselectedLabelColor: Colors.white70,
              // Color of unselected tab labels
              tabs: const [Tab(text: 'Latest'), Tab(text: 'Subs'), Tab(text: 'History'), Tab(text: 'Bookmarked')],
            ),
          ),
          drawer: const AppDrawer(), // Add the drawer

          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- Tab 0: Subscriptions ---
                    RefreshIndicator(
                      onRefresh: _loadLatestEpisodes,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ValueListenableBuilder<LoadingState>(
                              valueListenable: _latestEpisodesLoadingState,
                              builder: (context, value, child) {
                                if (value == LoadingState.loading || value == LoadingState.idle) {
                                  return Center(child: CircularProgressIndicator());
                                }

                                return latestEpisodes.isEmpty
                                    ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('No episodes found', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70))))
                                    : ListView.separated(
                                      separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 5),
                                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
                                      itemCount: latestEpisodes.length,
                                      itemBuilder: (context, index) {
                                        final episode = latestEpisodes[index];
                                        final isCurrent = appState.currentEpisodeFromAudioService?.guid == episode.guid || appState.currentEpisodeFromAudioService?.audioUrl == episode.audioUrl;
                                        final isPlaying = isCurrent && appState.isPlayingFromAudioService;
                                        return EpisodeItem(episode: episode, isCurrent: isCurrent, isPlaying: isPlaying);
                                      },
                                    );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Tab 1: Subscriptions ---
                    RefreshIndicator(
                      onRefresh: _loadSubscriptions,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      hintText: 'Search subs ...',
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                      prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                                      suffixIcon: _searchController.text.isNotEmpty ? IconButton(onPressed: () => setState(() => _searchController.text = ''), icon: Icon(Icons.close_rounded, color: Colors.white)) : null,
                                      // Borders are themed globally
                                    ),
                                    autofocus: false,
                                    autocorrect: false,
                                    onChanged: (value) => setState(() => _searchController.text = value), //
                                  ),
                                ),
                                // IconButton to toggle reordering mode
                                IconButton(
                                  // Change icon based on reordering state
                                  icon: Icon(_isReordering ? Icons.check : Icons.reorder_rounded, size: 30),
                                  tooltip: _isReordering ? 'Done reordering' : 'Reorder list',
                                  onPressed: _toggleReorder, // Call _toggleReorder when pressed
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ValueListenableBuilder(
                              valueListenable: _subscribedPodcastsLoadingState,
                              builder: (context, value, child) {
                                if (value == LoadingState.loading) {
                                  return Center(child: CircularProgressIndicator());
                                }

                                if (value == LoadingState.loaded && subscribedPodcasts.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        _searchController.text.isEmpty ? 'No podcasts subscribed yet.\nTap "+" to add.' : 'No podcasts found for "${_searchController.text}".',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70), //
                                      ),
                                    ),
                                  );
                                }

                                if (value == LoadingState.loaded && _isReordering) {
                                  return ReorderableListView.builder(
                                    itemCount: subscribedPodcasts.length,
                                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                    // Adjusted padding
                                    proxyDecorator: (child, i, animation) {
                                      // Your custom proxy decorator
                                      return Material(
                                        // Using Material for better effect control
                                        elevation: 4.0, // Slight lift
                                        color: Colors.black.withValues(alpha: 0.5), // From your snippet
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        child: child, //
                                      );
                                    },
                                    onReorder: _onReorder,
                                    itemBuilder: (context, index) {
                                      // Ensure _buildPodcastItem provides a Key
                                      return _buildPodcastItem(subscribedPodcasts[index], appState, index);
                                    },
                                  );
                                }

                                return ImplicitlyAnimatedList<PodcastModel>(
                                  separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 5),
                                  // Ensure PodcastModel is the correct type
                                  padding: const EdgeInsets.all(2),
                                  items: subscribedPodcasts,
                                  areItemsTheSame: (a, b) => a.feedUrl == b.feedUrl,
                                  itemBuilder: (context, animation, item, i) {
                                    return SizeFadeTransition(
                                      sizeFraction: 0.7,
                                      curve: Curves.easeInOut,
                                      animation: animation,
                                      child: _buildPodcastItem(item, appState, i), //
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- Tab 2: History (Placeholder) ---
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: PlayingHistoryScreen(), //
                    ),

                    // --- Tab 3: Bookmarked (Placeholder) ---
                    const Center(child: Text('Bookmarked Content Will Go Here', style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),
              Selector<AppState, EpisodeModel?>(selector: (_, appStateWatch) => appStateWatch.currentEpisodeFromAudioService, builder: (context, currentEpisode, child) => currentEpisode != null ? MiniPlayer(currentEpisode: currentEpisode) : const SizedBox.shrink()),
            ],
          ),
          // floatingActionButton: FloatingActionButton(
          //   shape: CircleBorder(),
          //   onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PodcastSearchScreen())),
          //   tooltip: 'Add Podcast',
          //   child: const Icon(Icons.add), // FAB icon color defaults to theme's foreground for FAB
          // ),
        ),
      ],
    );
  }

  Widget _buildPodcastItem(final PodcastModel podcast, final AppState appState, final int index) {
    return Card(
      key: Key(podcast.id),
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 2),
      color: Colors.black.withValues(alpha: 0.2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
        visualDensity: VisualDensity.compact,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(imageUrl: podcast.artworkUrl, width: 50, height: 50, fit: BoxFit.cover, placeholder: (c, u) => Container(width: 50, height: 50, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.podcasts, color: Colors.white54, size: 30)), errorWidget: (c, u, e) => Container(width: 50, height: 50, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.broken_image, color: Colors.white54, size: 30))),
        ),
        title: Text(maxLines: 1, overflow: TextOverflow.ellipsis, podcast.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
        //
        subtitle: Text(maxLines: 1, overflow: TextOverflow.ellipsis, podcast.artistName, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PodcastDetailScreen(podcast: podcast))),
        trailing:
            _isReordering
                ? ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle), //
                )
                : IconButton(
                  onPressed: () => _performRemovePodcast(podcast, appState, index),
                  icon: Icon(Icons.remove_circle_rounded), //
                ), //
      ),
    );
  }

  void _performRemovePodcast(final PodcastModel podcast, final AppState appState, final int index) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmDialog(
            title: 'Confirm',
            content: 'Unsubscribe from "${podcast.title}" podcast?',
            onConfirm: () {
              appState.unsubscribeFromPodcast(podcast);
            },
          ),
    );
  }
}
