import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get_it/get_it.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/domain/enums/loading_state.dart';
import 'package:podsink2/domain/models/bookmarked_episode.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/domain/models/played_history_item.dart';
import 'package:podsink2/domain/models/podcast.dart';
import 'package:podsink2/main.dart';
import 'package:podsink2/presentation/screens/podcast_detail.dart';
import 'package:podsink2/presentation/screens/podcast_search.dart';
import 'package:podsink2/presentation/shared_widgets/app_drawer.dart';
import 'package:podsink2/presentation/shared_widgets/confirm_dialog.dart';
import 'package:podsink2/presentation/shared_widgets/episode_item.dart';
import 'package:podsink2/presentation/shared_widgets/mini_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController(text: "");
  late TabController _tabController;

  // Access AppState via GetIt (or your chosen DI method)
  late final AppState _appState;

  // Local loading states can remain as they are specific to this screen's view logic
  final _historyLoadingState = ValueNotifier(LoadingState.idle);
  final _latestEpisodesLoadingState = ValueNotifier(LoadingState.idle);
  final _bookmarkedEpisodesLoadingState = ValueNotifier(LoadingState.idle);
  final _subscribedPodcastsLoadingState = ValueNotifier(LoadingState.idle);

  final _errorMessage = ValueNotifier('');

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
    _appState.swapPodcastsSortOrder(oldIndex, newIndex);
  }

  @override
  void initState() {
    super.initState();
    _appState = GetIt.I<AppState>(); // Initialize AppState from GetIt

    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(() {
      setState(() {}); // Rebuild to filter subscription list - This can remain for local search filtering
    });

    _loadLatestEpisodes();

    _tabController.addListener(() {
      setState(() {
        // Keep setState for TabController related UI changes if necessary
        if (!_tabController.indexIsChanging) {
          int currentIndex = _tabController.index;
          switch (currentIndex) {
            case 0:
              // Load only if not already loaded/loading or if data is considered stale
              if (_latestEpisodesLoadingState.value == LoadingState.idle) {
                _loadLatestEpisodes();
              }
              break;
            case 1:
              if (_subscribedPodcastsLoadingState.value == LoadingState.idle) {
                _loadSubscriptions();
              }
              break;
            case 2:
              if (_historyLoadingState.value == LoadingState.idle) {
                _loadHistoryData();
              }
              break;
            case 3:
              if (_bookmarkedEpisodesLoadingState.value == LoadingState.idle) {
                _loadBookmarkedData();
              }
              break;
          }
        }
      });
    });
  }

  Future<void> _loadLatestEpisodes() async {
    if (!mounted) return;

    _latestEpisodesLoadingState.value = LoadingState.loading;
    try {
      await _appState.loadLatestEpisodes();
      _latestEpisodesLoadingState.value = LoadingState.loaded;
    } catch (e) {
      _errorMessage.value = 'Error: $e';
      _latestEpisodesLoadingState.value = LoadingState.failed;
    }
  }

  Future<void> _loadSubscriptions() async {
    if (!mounted) return;

    _subscribedPodcastsLoadingState.value = LoadingState.loading;
    try {
      await _appState.loadSubscribedPodcasts();
      _subscribedPodcastsLoadingState.value = LoadingState.loaded;
    } catch (e) {
      _errorMessage.value = 'Error: $e';
      _latestEpisodesLoadingState.value = LoadingState.failed;
    }
  }

  Future<void> _loadHistoryData() async {
    if (!mounted) return;

    _historyLoadingState.value = LoadingState.loading;
    try {
      await _appState.loadPlayedHistory();
      _historyLoadingState.value = LoadingState.loaded;
    } catch (e) {
      _errorMessage.value = 'Error: $e';
      _latestEpisodesLoadingState.value = LoadingState.failed;
    }
  }

  Future<void> _loadBookmarkedData() async {
    if (!mounted) return;

    _bookmarkedEpisodesLoadingState.value = LoadingState.loading;
    try {
      await _appState.loadBookmarks();
      _bookmarkedEpisodesLoadingState.value = LoadingState.loaded;
    } catch (e) {
      _errorMessage.value = 'Error: $e';
      _latestEpisodesLoadingState.value = LoadingState.failed;
    }
  }

  @override
  Widget build(BuildContext context) {
    // _appState is already available as a member variable

    return Stack(
      children: [
        Positioned.fill(child: Container(decoration: kAppGradientBackground)),
        Scaffold(
          appBar: AppBar(
            title: const Text('PodSink'),
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
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [Tab(text: 'Latest'), Tab(text: 'Subs'), Tab(text: 'History'), Tab(text: 'Bookmarked')], //
            ), //
          ),
          drawer: const AppDrawer(),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // --- Tab 0: Latest Episodes ---
                    ValueListenableBuilder(
                      valueListenable: _appState.latestEpisodesNotifier,
                      builder: (context, latestEpisodes, child) {
                        return RefreshIndicator(
                          onRefresh: _loadLatestEpisodes,
                          child: ValueListenableBuilder<LoadingState>(
                            valueListenable: _latestEpisodesLoadingState,
                            builder: (context, loadingState, _) {
                              if (loadingState == LoadingState.failed) {
                                return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Failed to load subscriptions: ${_errorMessage.value}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orangeAccent))));
                              }

                              if (loadingState == LoadingState.loading) {
                                return Center(child: CircularProgressIndicator());
                              }

                              if (loadingState == LoadingState.loaded && latestEpisodes.isEmpty) {
                                return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('No episodes found', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70))));
                              }

                              return ListView.separated(
                                separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 3),
                                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                                itemCount: latestEpisodes.length,
                                itemBuilder: (context, index) {
                                  final episode = latestEpisodes[index];
                                  // Listen to currentEpisode and isPlaying separately for EpisodeItem updates
                                  return ValueListenableBuilder(
                                    valueListenable: _appState.currentEpisodeNotifier, // Assuming this exists
                                    builder: (context, currentEpisode, _) {
                                      return ValueListenableBuilder(
                                        valueListenable: _appState.isPlayingNotifier, // Assuming this exists
                                        builder: (context, isPlayingAudio, _) {
                                          final isCurrent = currentEpisode?.guid == episode.guid || currentEpisode?.audioUrl == episode.audioUrl;
                                          final isPlaying = isCurrent && isPlayingAudio;
                                          return EpisodeItem(episode: episode, isCurrent: isCurrent, isPlaying: isPlaying);
                                        },
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),

                    // --- Tab 1: Subscriptions ---
                    ValueListenableBuilder(
                      valueListenable: _appState.subscribedPodcastsNotifier,
                      builder: (context, allSubscribedPodcasts, child) {
                        switch (_subscribedPodcastsLoadingState.value) {
                          case LoadingState.failed:
                            return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Failed to load subscriptions: ${_errorMessage.value}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.orangeAccent))));
                          case LoadingState.idle:
                          case LoadingState.loading:
                            return const Center(child: CircularProgressIndicator());
                          case LoadingState.loaded:
                            List<PodcastModel> subscribedPodcasts = [];

                            if (_searchController.text.trim().isNotEmpty) {
                              subscribedPodcasts = allSubscribedPodcasts.where((p) => p.title.toLowerCase().contains(_searchController.text.toLowerCase()) || p.artistName.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
                            } else {
                              subscribedPodcasts = allSubscribedPodcasts;
                            }

                            return _buildSubscribedPodcasts(subscribedPodcasts);
                        }
                      },
                    ),

                    // --- Tab 2: History ---
                    // Wrap with ValueListenableBuilder if playing history is from AppState notifier
                    ValueListenableBuilder<List<PlayedEpisodeHistoryItemModel>>(
                      // Assuming EpisodeModel for history items
                      valueListenable: _appState.playedHistoryNotifier, // Assuming this notifier exists
                      builder: (context, historyEpisodes, child) {
                        return ValueListenableBuilder<LoadingState>(
                          valueListenable: _historyLoadingState,
                          builder: (context, loadingState, _) {
                            if (loadingState == LoadingState.loading || loadingState == LoadingState.idle) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (historyEpisodes.isEmpty) {
                              return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('No playing history yet.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70))));
                            }
                            // Replace PlayingHistoryScreen() with your actual list rendering
                            // For example:
                            return ListView.separated(
                              separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 3),
                              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                              itemCount: historyEpisodes.length,
                              itemBuilder: (context, index) {
                                final episode = historyEpisodes[index];
                                return EpisodeItem(episode: EpisodeModel.fromHistoryItem(episode), isCurrent: false, isPlaying: false); // Adjust isCurrent/isPlaying as needed
                              },
                            );
                            // return PlayingHistoryScreen(); // Or use your existing screen if it's self-contained or also uses ValueListenableBuilder
                          },
                        );
                      },
                    ),

                    // --- Tab 3: Bookmarked ---
                    ValueListenableBuilder(
                      // Assuming EpisodeModel for bookmarked items
                      valueListenable: _appState.bookmarkedEpisodesNotifier, // Assuming this notifier exists
                      builder: (context, bookmarkedEpisodes, child) {
                        return ValueListenableBuilder<LoadingState>(
                          valueListenable: _bookmarkedEpisodesLoadingState,
                          builder: (context, loadingState, _) {
                            if (loadingState == LoadingState.loading) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (loadingState == LoadingState.loaded && bookmarkedEpisodes.isEmpty) {
                              return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('No bookmarks yet.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70))));
                            }
                            // Replace with your actual list rendering
                            return ListView.separated(
                              separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 3),
                              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                              itemCount: bookmarkedEpisodes.length,
                              itemBuilder: (context, index) {
                                final episode = bookmarkedEpisodes[index];
                                return EpisodeItem(episode: EpisodeModel.fromBookmarkedEpisode(episode), isCurrent: false, isPlaying: false); // Adjust as needed
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Use ValueListenableBuilder for the MiniPlayer based on AppState's currentEpisodeNotifier
              ValueListenableBuilder<EpisodeModel?>(
                valueListenable: _appState.currentEpisodeNotifier, // Assuming this notifier name
                builder: (context, currentEpisode, child) {
                  return currentEpisode != null ? MiniPlayer(currentEpisode: currentEpisode) : const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Removed AppState from here as _appState instance is available
  Widget _buildPodcastItem(final PodcastModel podcast, final int index) {
    final double size = 55;

    return Card(
      key: Key(podcast.id),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 0),
      color: Colors.black.withValues(alpha: 0.2),
      // Use withOpacity
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
        leading: SizedBox(
          width: size, // Explicitly set the width
          height: size, // Explicitly set the desired height
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: podcast.artworkUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              //
              placeholder: (c, u) => Container(width: size, height: size, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.podcasts, color: Colors.white54, size: 30)),
              //
              errorWidget: (c, u, e) => Container(width: size, height: size, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.broken_image, color: Colors.white54, size: 30)), //
            ),
          ),
        ),
        title: Text(maxLines: 1, overflow: TextOverflow.ellipsis, podcast.title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15)),
        subtitle: Text(maxLines: 1, overflow: TextOverflow.ellipsis, podcast.artistName, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PodcastDetailScreen(podcast: podcast))),
        trailing:
            _isReordering
                ? ReorderableDragStartListener(
                  index: index, // Use the passed index
                  child: const Icon(Icons.drag_handle),
                )
                : IconButton(
                  onPressed: () => _performRemovePodcast(podcast), // AppState not needed here
                  icon: Icon(Icons.remove_circle_rounded),
                ),
      ),
    );
  }

  // Removed AppState from here
  void _performRemovePodcast(final PodcastModel podcast) {
    showDialog(
      context: context,
      builder:
          (context) => ConfirmDialog(
            title: 'Confirm',
            content: 'Unsubscribe from "${podcast.title}" podcast?',
            onConfirm: () {
              _appState.unsubscribeFromPodcast(podcast); // Call method on _appState instance
            },
          ),
    );
  }

  Widget _buildSubscribedPodcasts(List<PodcastModel> subscribedPodcasts) {
    return RefreshIndicator(
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
                      // Use withOpacity
                      prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: Icon(Icons.close_rounded, color: Colors.white),
                              )
                              : null,
                    ),
                    autofocus: false,
                    autocorrect: false,
                    onChanged: (value) => setState(() {}), // To trigger rebuild for filtering
                  ),
                ),
                IconButton(icon: Icon(_isReordering ? Icons.check : Icons.reorder_rounded, size: 30), tooltip: _isReordering ? 'Done reordering' : 'Reorder list', onPressed: _toggleReorder),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _subscribedPodcastsLoadingState,
              builder: (context, loadingState, _) {
                if ((loadingState == LoadingState.loading || loadingState == LoadingState.idle) && subscribedPodcasts == null && _searchController.text.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }
                if (loadingState == LoadingState.loaded && subscribedPodcasts.isEmpty) {
                  return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_searchController.text.isEmpty ? 'No podcasts subscribed yet.\nTap "+" to add.' : 'No podcasts found for "${_searchController.text}".', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70))));
                }

                if (_isReordering) {
                  return ReorderableListView.builder(
                    itemCount: subscribedPodcasts.length,
                    padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    proxyDecorator: (child, i, animation) {
                      return Material(
                        elevation: 4.0,
                        color: Colors.black.withValues(alpha: 0.5), // Use withOpacity
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: child,
                      );
                    },
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      return _buildPodcastItem(subscribedPodcasts[index], index); // Pass index for ReorderableDragStartListener
                    },
                  );
                }

                return ImplicitlyAnimatedList<PodcastModel>(
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  items: subscribedPodcasts,
                  areItemsTheSame: (a, b) => a.feedUrl == b.feedUrl,
                  itemBuilder: (context, animation, item, i) {
                    return SizeFadeTransition(
                      sizeFraction: 0.7,
                      curve: Curves.easeInOut,
                      animation: animation,
                      child: _buildPodcastItem(item, i), // Pass index for potential reorder context if needed indirectly
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
