import 'package:flutter/cupertino.dart';
import 'package:podsink2/data/datasources/app_database.dart';
import 'package:podsink2/domain/models/episode.dart';

class PodcastModel {
  final String id;
  final String title;
  final String artistName;
  final String artworkUrl;
  final String feedUrl;
  final String? podcastUrl;
  final int? sortOrder;
  DateTime? lastViewed;
  List<EpisodeModel> episodes;

  PodcastModel({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artworkUrl,
    required this.feedUrl,
    required this.sortOrder,
    this.podcastUrl,
    this.lastViewed,
    this.episodes = const [], //
  });

  factory PodcastModel.fromPodcast(Podcast podcast) => PodcastModel(
    id: podcast.id,
    title: podcast.title,
    artistName: podcast.artistName,
    artworkUrl: podcast.artworkUrl,
    feedUrl: podcast.feedUrl,
    podcastUrl: podcast.podcastUrl,
    sortOrder: podcast.sortOrder, //
  );

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    return PodcastModel(
      id: json['collectionId']?.toString() ?? json['feedUrl'] ?? UniqueKey().toString(),
      title: json['collectionName'] ?? json['trackName'] ?? 'Unknown Title',
      artistName: json['artistName'] ?? 'Unknown Artist',
      artworkUrl: json['artworkUrl600'] ?? json['artworkUrl100'] ?? 'https://placehold.co/600x600/E0E0E0/B0B0B0?text=No+Art',
      feedUrl: json['feedUrl'] ?? '',
      podcastUrl: json['collectionViewUrl'],
      sortOrder: json['sortOrder'] ?? 0, //
    );
  }
}
