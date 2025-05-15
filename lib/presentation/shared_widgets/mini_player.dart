import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/presentation/screens/fullscreen_player.dart';
import 'package:provider/provider.dart';

class MiniPlayer extends StatelessWidget {
  final EpisodeModel currentEpisode;

  const MiniPlayer({super.key, required this.currentEpisode});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final audioHandler = Provider.of<AudioHandler>(context, listen: false);

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenPlayerScreen(episode: currentEpisode)));
      },
      child: Material(
        elevation: 0,
        color: Colors.black.withValues(alpha: 0.5), // Themed MiniPlayer background
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          height: 80,
          // color: Colors.grey[50], // Old color
          decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2), width: 0.5))),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: CachedNetworkImage(
                  imageUrl: currentEpisode.artworkUrl ?? 'https://placehold.co/60x60/E0E0E0/B0B0B0?text=Art',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(width: 50, height: 50, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.music_note, color: Colors.white54)),
                  errorWidget: (c, u, e) => Container(width: 50, height: 50, color: Colors.white.withValues(alpha: 0.1), child: const Icon(Icons.broken_image, color: Colors.white54)), //
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      currentEpisode.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white), //
                    ),
                    //const SizedBox(height: 2),
                    //Text(currentEpisode.podcastTitle, style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.8)), overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
              StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final ps = snapshot.data;
                  final isPlaying = ps?.playing ?? false;
                  final procState = ps?.processingState ?? AudioProcessingState.idle;
                  if (procState == AudioProcessingState.loading || procState == AudioProcessingState.buffering) {
                    return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white));
                  }
                  return IconButton(
                    padding: EdgeInsets.all(0),
                    icon: Icon(isPlaying ? Icons.pause_circle_filled_outlined : Icons.play_circle_fill_outlined, size: 36, color: Colors.white),
                    tooltip: isPlaying ? 'Pause' : 'Play',
                    onPressed: appState.togglePlayPause, //
                  );
                },
              ),
              IconButton(
                padding: EdgeInsets.all(0),
                icon: Icon(Icons.stop_circle_rounded, size: 36, color: Colors.white.withValues(alpha: 0.7)),
                tooltip: 'Stop',
                onPressed: appState.stopPlayback, //
              ),
            ],
          ),
        ),
      ),
    );
  }
}
