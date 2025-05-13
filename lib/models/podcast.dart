import 'package:flutter/cupertino.dart';
import 'package:podsink2/models/episode.dart';

class Podcast {
  final String id;
  final String title;
  final String artistName;
  final String artworkUrl;
  final String feedUrl;
  List<Episode> episodes;

  Podcast({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artworkUrl,
    required this.feedUrl,
    this.episodes = const [],
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['collectionId']?.toString() ?? json['feedUrl'] ?? UniqueKey().toString(),
      title: json['collectionName'] ?? json['trackName'] ?? 'Unknown Title',
      artistName: json['artistName'] ?? 'Unknown Artist',
      artworkUrl: json['artworkUrl600'] ?? json['artworkUrl100'] ?? 'https://placehold.co/600x600/E0E0E0/B0B0B0?text=No+Art',
      feedUrl: json['feedUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'artistName': artistName,
    'artworkUrl': artworkUrl,
    'feedUrl': feedUrl,
  };

  factory Podcast.fromMap(Map<String, dynamic> map) {
    return Podcast(
      id: map['id'] as String,
      title: map['title'] as String,
      artistName: map['artistName'] as String,
      artworkUrl: map['artworkUrl'] as String,
      feedUrl: map['feedUrl'] as String,
    );
  }
}