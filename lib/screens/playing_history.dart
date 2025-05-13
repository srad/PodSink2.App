import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:podsink2/app_state.dart';
import 'package:podsink2/main.dart';
import 'package:provider/provider.dart';

class PlayingHistoryScreen extends StatelessWidget {
  const PlayingHistoryScreen({super.key});

  String _formatDuration(Duration? d) {
    if (d == null || d.inMilliseconds <= 0) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return [
      if (hours > 0) hours.toString(),
      minutes,
      seconds,
    ].join(':');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Playing History'),
      ),
      body: Container(
        decoration: kAppGradientBackground,
        child: Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.playedHistory.isEmpty) {
              return const Center(
                child: Text('No playing history yet.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              );
            }
            return ListView.builder(
              itemCount: appState.playedHistory.length,
              itemBuilder: (context, index) {
                final item = appState.playedHistory[index];
                final totalDuration = item.totalDurationMs != null ? Duration(milliseconds: item.totalDurationMs!) : null;
                final lastPosition = Duration(milliseconds: item.lastPositionMs);

                double progress = 0.0;
                if (totalDuration != null && totalDuration.inMilliseconds > 0 && lastPosition.inMilliseconds > 0) {
                  progress = (lastPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
                }


                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: CachedNetworkImage(
                        imageUrl: item.artworkUrl ?? 'https://placehold.co/70x70/FFFFFF/000000?text=NoArt',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (c,u) => Container(width:50, height:50, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.music_note, color: Colors.white54)),
                        errorWidget: (c,u,e) => Container(width:50, height:50, color: Colors.white.withValues(alpha: 0.1), child: Icon(Icons.broken_image, color: Colors.white54)),
                      ),
                    ),
                    title: Text(item.episodeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.podcastTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                        const SizedBox(height: 4),
                        if (totalDuration != null && totalDuration != Duration.zero)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade100),
                                minHeight: 3,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Listened: ${_formatDuration(lastPosition)} / ${_formatDuration(totalDuration)}',
                                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                              ),
                            ],
                          )
                        else
                          Text(
                            'Listened: ${_formatDuration(lastPosition)}',
                            style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7)),
                          ),
                        Text('Last Played: ${DateFormat.yMd().add_jm().format(item.lastPlayedDate.toLocal())}', style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6))),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_circle_rounded, color: Colors.black, size: 30),
                          tooltip: 'Resume',
                          onPressed: () {
                            appState.resumeEpisodeFromHistory(item);
                            if (Navigator.canPop(context)) { // If full screen player is not main, pop to show mini player
                              Navigator.pop(context); // Pop history screen
                            }
                            // Consider navigating to FullScreenPlayer if desired
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_rounded, color: Colors.red, size: 30),
                          tooltip: 'Remove from history',
                          onPressed: () {
                            appState.removeEpisodeFromHistory(item.guid);
                          },
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}