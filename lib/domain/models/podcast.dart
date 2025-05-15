import 'package:flutter/cupertino.dart';
import 'package:podsink2/domain/models/episode.dart';

class PodcastModel {
  final String id;
  final String title;
  final String artistName;
  final String artworkUrl;
  final String feedUrl;
  final int? sortOrder;
  List<EpisodeModel> episodes;

  PodcastModel({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artworkUrl,
    required this.feedUrl,
    required this.sortOrder,
    this.episodes = const [], //
  });

  factory PodcastModel.fromJson(Map<String, dynamic> json) {
    return PodcastModel(
      id: json['collectionId']?.toString() ?? json['feedUrl'] ?? UniqueKey().toString(),
      title: json['collectionName'] ?? json['trackName'] ?? 'Unknown Title',
      artistName: json['artistName'] ?? 'Unknown Artist',
      artworkUrl: json['artworkUrl600'] ?? json['artworkUrl100'] ?? 'https://placehold.co/600x600/E0E0E0/B0B0B0?text=No+Art',
      feedUrl: json['feedUrl'] ?? '',
      sortOrder: json['sortOrder'] ?? 0, //
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'title': title, 'artistName': artistName, 'artworkUrl': artworkUrl, 'feedUrl': feedUrl};

  factory PodcastModel.fromMap(Map<String, dynamic> map) {
    return PodcastModel(
      id: map['id'] as String,
      title: map['title'] as String,
      artistName: map['artistName'] as String,
      artworkUrl: map['artworkUrl'] as String,
      feedUrl: map['feedUrl'] as String,
      sortOrder: map['sortOrder'] as int, //
    );
  }
}
