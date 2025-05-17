import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:podsink2/core/app_state.dart';
import 'package:podsink2/domain/models/played_history_item.dart';
import 'package:podsink2/main.dart';
import 'package:get_it/get_it.dart';

class PlayingHistoryScreen extends StatelessWidget {
  const PlayingHistoryScreen({super.key});

  String _formatDuration(Duration? d) {
    if (d == null || d.inMilliseconds <= 0) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return [if (hours > 0) hours.toString(), minutes, seconds].join(':');
  }

  @override
  Widget build(BuildContext context) {
    // Get AppState instance once for actions and to access the notifier
    final AppState appState = GetIt.I<AppState>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: kAppGradientBackground,
        child: ValueListenableBuilder<List<PlayedEpisodeHistoryItemModel>?>( // <--- REPLACE Consumer
          valueListenable: appState.playedHistoryNotifier,                 // <--- LISTEN to notifier
          builder: (context, playedHistoryItems, child) {                 // <--- GET items from notifier
            if (playedHistoryItems == null) {
              return const Center(child: Text('No playing history yet.', style: TextStyle(color: Colors.white70, fontSize: 16)));
            }
            return ListView.separated(
              separatorBuilder: (context, index) => Divider(color: Colors.transparent, height: 5),
              itemCount: playedHistoryItems.length, // Use items from ValueListenableBuilder
              itemBuilder: (context, index) {
                final item = playedHistoryItems[index]; // Use item from ValueListenableBuilder
                final totalDuration = item.totalDurationMs != null ? Duration(milliseconds: item.totalDurationMs!) : null;
                final lastPosition = Duration(milliseconds: item.lastPositionMs);

                double progress = 0.0;
                if (totalDuration != null && totalDuration.inMilliseconds > 0 && lastPosition.inMilliseconds > 0) {
                  progress = (lastPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
                }

                return Card(
                  color: Colors.black.withAlpha(51),
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: CachedNetworkImage(
                          imageUrl: item.artworkUrl ?? 'https://placehold.co/70x70/FFFFFF/000000?text=NoArt',
                          width: 50, height: 50, fit: BoxFit.cover,
                          placeholder: (c, u) => Container(width: 50, height: 50, color: Colors.white.withAlpha(26), child: Icon(Icons.music_note, color: Colors.white54)),
                          errorWidget: (c, u, e) => Container(width: 50, height: 50, color: Colors.white.withAlpha(26), child: Icon(Icons.broken_image, color: Colors.white54))
                      ),
                    ),
                    title: Text(item.episodeTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.podcastTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 12)),
                        const SizedBox(height: 4),
                        if (totalDuration != null && totalDuration != Duration.zero)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white.withAlpha(77),
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade100),
                                      minHeight: 3,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('${_formatDuration(lastPosition)} / ${_formatDuration(totalDuration)}', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(179))),
                                ],
                              ),
                            ],
                          )
                        else
                          Text('Listened: ${_formatDuration(lastPosition)}', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(179))),
                        Text('Last Played: ${DateFormat.yMd().format(item.lastPlayedDate.toLocal())}', style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(153))),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.play_circle_rounded, color: Colors.amber.shade200, size: 28),
                          tooltip: 'Resume',
                          onPressed: () {
                            // AppState instance for action already fetched as 'appState'
                            appState.resumeEpisodeFromHistory(item);
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(Icons.delete_rounded, color: Colors.red.shade300, size: 28),
                          tooltip: 'Remove from history',
                          onPressed: () {
                            // AppState instance for action already fetched as 'appState'
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