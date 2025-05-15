import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/main.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class PlayerScreenData {
  final MediaItem? mediaItem;
  final PlaybackState? playbackState; // Make PlaybackState nullable initially

  PlayerScreenData(this.mediaItem, this.playbackState);
}

class FullScreenPlayerScreen extends StatefulWidget {
  final EpisodeModel episode;

  const FullScreenPlayerScreen({super.key, required this.episode});

  @override
  State<FullScreenPlayerScreen> createState() => _FullScreenPlayerScreen();
}

class _FullScreenPlayerScreen extends State<FullScreenPlayerScreen> {
  int _selectedIndex = 0;
  late final Stream<PlayerScreenData> _combinedPlayerDataStream;

  @override
  void initState() {
    // It's important that audioHandler is initialized before this stream is created.
    // If audioHandler comes from Provider and might not be ready immediately,
    // ensure this stream is created when audioHandler is available.
    // However, audioHandler streams themselves handle late listening.
    final audioHandler = Provider.of<AudioHandler>(context, listen: false);
    _combinedPlayerDataStream = CombineLatestStream.combine2(
      audioHandler.mediaItem, // Stream<MediaItem?>
      audioHandler.playbackState, // Stream<PlaybackState> - this stream emits an initial value
      (mediaItemData, playbackStateData) => PlayerScreenData(mediaItemData, playbackStateData),
    );
    super.initState();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (hours > 0) hours.toString(), minutes, seconds].join(':');
  }

  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioHandler>(context, listen: false);

    return Scaffold(
      extendBodyBehindAppBar: true, // Let gradient go behind AppBar
      appBar: AppBar(title: Text(widget.episode.podcastTitle, style: const TextStyle(fontSize: 16)), elevation: 0),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: kAppGradientBackground, // Use the global gradient
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top), // Space for AppBar and StatusBar
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.4,
              child: CarouselSlider(
                items: [
                  // Podcast Artwork
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: CachedNetworkImage(
                        imageUrl: widget.episode.artworkUrl ?? 'https://placehold.co/300x300/E0E0E0/B0B0B0?text=No+Art',
                        fit: BoxFit.fill,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(Icons.music_note, size: 100, color: Colors.white54), //
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(Icons.broken_image, size: 100, color: Colors.white54), //
                            ), //
                      ),
                    ),
                  ),
                  // Episode Description (Scrollable)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2), // Slightly darker for readability
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: SingleChildScrollView(child: Text(widget.episode.description.isNotEmpty ? widget.episode.description : "No description available.", style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.5))),
                    ),
                  ),
                ],
                options: CarouselOptions(
                  height: 300,
                  aspectRatio: 4 / 3,
                  viewportFraction: 1,
                  initialPage: 0,
                  enableInfiniteScroll: false,
                  reverse: false,
                  autoPlay: false,
                  autoPlayInterval: Duration(seconds: 3),
                  autoPlayAnimationDuration: Duration(milliseconds: 800),
                  autoPlayCurve: Curves.fastOutSlowIn,
                  enlargeCenterPage: true,
                  enlargeFactor: 0.3,
                  onPageChanged: (index, reason) => setState(() => _selectedIndex = index),
                  scrollDirection: Axis.horizontal, //
                ),
              ),
            ),

            SizedBox(height: 10),
            DotsIndicator(
              dotsCount: 2,
              position: _selectedIndex.toDouble(),
              decorator: DotsDecorator(
                color: Colors.black87, // Inactive color
                activeColor: Colors.redAccent, //
              ),
            ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Podcast Title (Artist)
                  Text(widget.episode.podcastTitle, style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)), textAlign: TextAlign.center),

                  const SizedBox(height: 16),

                  // Episode Title
                  Text(
                    widget.episode.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allow more lines for episode title
                    overflow: TextOverflow.ellipsis, //
                  ),
                ],
              ),
            ),

            Spacer(),

            // Seek Bar and Time Labels
            StreamBuilder<PlayerScreenData>(
              stream: _combinedPlayerDataStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint('CombinedStream Error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                }

                if (!snapshot.hasData) {
                  debugPrint('CombinedStream: No data yet or waiting...');
                  // Return a loading indicator or your initial placeholder UI
                  // This state will be brief as PlaybackState usually has an initial value.
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                // Data is available
                final PlayerScreenData data = snapshot.data!;
                final MediaItem? currentMediaItem = data.mediaItem;
                final PlaybackState? playbackState = data.playbackState; // Can be null if stream emits null initially

                // Handle case where playbackState might still be null if its stream hasn't emitted
                // or if CombineLatestStream emits before both streams have values (though typically it waits for both to emit at least once).
                // audio_service's playbackState is a BehaviorSubject, so it has an initial value.
                if (playbackState == null) {
                  debugPrint('CombinedStream: PlaybackState is null in data.');
                  return const Center(child: CircularProgressIndicator(color: Colors.white)); // Or other placeholder
                }

                final position = playbackState?.updatePosition ?? playbackState?.position ?? Duration.zero;
                final bufferedPosition = playbackState?.bufferedPosition ?? Duration.zero;
                final totalDuration = currentMediaItem?.duration ?? widget.episode.duration ?? Duration.zero;

                return Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withAlpha(0x29),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                        trackHeight: 6.0, //
                      ),
                      child: Slider(
                        min: 0.0,
                        max: totalDuration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                        // Ensure max is at least 1.0
                        value: position.inMilliseconds.toDouble().clamp(0.0, totalDuration.inMilliseconds.toDouble()),
                        secondaryTrackValue: bufferedPosition.inMilliseconds.toDouble().clamp(0.0, totalDuration.inMilliseconds.toDouble()),
                        onChanged:
                            (totalDuration.inMilliseconds > 0)
                                ? (value) {
                                  audioHandler.seek(Duration(milliseconds: value.round()));
                                }
                                : null,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position), style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
                          Text(_formatDuration(totalDuration), style: TextStyle(color: Colors.white.withValues(alpha: 0.8))), //
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 0),

            // Playback Controls
            StreamBuilder<PlaybackState>(
              stream: audioHandler.playbackState,
              builder: (context, snapshot) {
                final playing = snapshot.data?.playing ?? false;
                final processingState = snapshot.data?.processingState ?? AudioProcessingState.idle;
                final position = snapshot.data?.updatePosition ?? Duration.zero; // <<< CORRECTED line

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(onPressed: () => {}, icon: Icon(Icons.bookmark_add_rounded, size: 40)),
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 40),
                      onPressed: () {
                        audioHandler.seek(position - const Duration(seconds: 10));
                      },
                    ),
                    //IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40), onPressed: audioHandler.skipToPrevious),

                    // Loading
                    if (processingState == AudioProcessingState.loading || processingState == AudioProcessingState.buffering)
                      Container(
                        margin: const EdgeInsets.all(12),
                        width: 62.0,
                        height: 62.0, //
                        child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                      )
                    else
                      IconButton(icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled, color: Colors.white, size: 72.0), onPressed: playing ? audioHandler.pause : audioHandler.play),

                    //IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 40), onPressed: audioHandler.skipToNext),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 40),
                      onPressed: () {
                        final totalDuration = audioHandler.mediaItem.value?.duration ?? Duration.zero;
                        final newPosition = position + const Duration(seconds: 10);
                        audioHandler.seek(newPosition > totalDuration ? totalDuration : newPosition);
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
