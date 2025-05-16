import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/domain/models/episode.dart';
import 'package:provider/provider.dart';

class EpisodeItem extends StatelessWidget {
  final EpisodeModel episode;
  final bool isCurrent;
  final bool isPlaying;

  const EpisodeItem({
    super.key,
    required this.episode,
    required this.isCurrent,
    required this.isPlaying,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 2),
      color: Colors.black.withValues(alpha: 0.2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: CachedNetworkImage(
            imageUrl: episode.artworkUrl?? '',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(
              width: 60,
              height: 60,
              color: Colors.white.withAlpha(25), // Adjusted withAlpha for clarity
              child: const Icon(Icons.mic_none, color: Colors.white54, size: 30),
            ),
            errorWidget: (c, u, e) => Container(
              width: 60,
              height: 60,
              color: Colors.white.withAlpha(25), // Adjusted withAlpha for clarity
              child: const Icon(Icons.broken_image, color: Colors.white54, size: 30),
            ),
          ),
        ),
        title: Text(
          episode.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.podcastTitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (episode.pubDate != null) ...[
                  Row(children: [
                    const Icon(Icons.date_range_rounded, size: 12, color: Colors.white60), // Added color for consistency
                    const SizedBox(width: 5),
                    Text(
                      DateFormat.yMMMd().format(episode.pubDate!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                  ]),
                  const SizedBox(width: 10),
                ],
                if (episode.duration != null)
                  Row(children: [
                    const Icon(Icons.av_timer_rounded, size: 12, color: Colors.white60), // Added color for consistency
                    const SizedBox(width: 5),
                    Text(
                      overflow: TextOverflow.ellipsis,
                      _formatDuration(episode.duration!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                  ]),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: Colors.white,
            size: 32,
          ),
          tooltip: isPlaying ? 'Pause' : 'Play',
          onPressed: () => isCurrent ? appState.togglePlayPause() : appState.playEpisode(episode),
        ),
        onTap: () => isCurrent ? appState.togglePlayPause() : appState.playEpisode(episode),
      ),
    );
  }
}