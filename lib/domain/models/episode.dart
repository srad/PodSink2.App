import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';

class EpisodeModel {
  final String guid;
  final String podcastTitle;
  final String title;
  final String description;
  final String audioUrl;
  final DateTime? pubDate;
  String? artworkUrl;
  final Duration? duration;

  EpisodeModel({
    required this.guid,
    required this.podcastTitle,
    required this.title,
    required this.description,
    required this.audioUrl,
    this.pubDate,
    this.artworkUrl,
    this.duration,
  });

  factory EpisodeModel.fromRssItem(dynamic item, String podcastTitleFromFeed, String podcastArtworkFromFeed) {
    String? extractedAudioUrl;
    if (item.enclosure?.url != null) {
      extractedAudioUrl = item.enclosure!.url!;
    } else if (item.media?.contents != null && item.media!.contents!.isNotEmpty) {
      extractedAudioUrl = item.media!.contents!
          .firstWhere((content) => content.type?.startsWith('audio/') ?? false, orElse: () => null)
          ?.url;
    }

    return EpisodeModel(
      guid: item.guid ?? UniqueKey().toString(),
      podcastTitle: podcastTitleFromFeed,
      title: item.title ?? 'Unknown Episode',
      description: item.description ?? item.itunes?.summary ?? 'No description available.',
      audioUrl: extractedAudioUrl ?? '',
      pubDate: item.pubDate,
      artworkUrl: item.itunes?.image?.href ?? podcastArtworkFromFeed,
      duration: item.itunes?.duration,
    );
  }

  static Duration? _parseDuration(String? s) {
    if (s == null) return null;
    try {
      final parts = s.split(':').map(int.parse).toList();
      if (parts.length == 3) return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
      if (parts.length == 2) return Duration(minutes: parts[0], seconds: parts[1]);
      if (parts.length == 1) return Duration(seconds: parts[0]);
    } catch (e) {
      debugPrint("Error parsing duration string '$s': $e");
    }
    return null;
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: audioUrl,
      album: podcastTitle,
      title: title,
      artist: podcastTitle,
      duration: duration,
      artUri: artworkUrl != null && artworkUrl!.isNotEmpty ? Uri.tryParse(artworkUrl!) : null,
      extras: {'guid': guid, 'description': description, 'podcastTitle': podcastTitle, 'artworkUrl': artworkUrl},
    );
  }
}