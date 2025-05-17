import 'package:flutter/cupertino.dart';
import 'package:podsink2/domain/models/episode.dart';

class BookmarkedEpisodeModel {
  final String guid;
  final String podcastTitle;
  final String episodeTitle;
  final String audioUrl;
  final String? description;
  final String? artworkUrl;

  final int? totalDurationMs;
  final int lastPositionMs;
  final DateTime lastPlayedDate;

  BookmarkedEpisodeModel({
    required this.guid,
    required this.podcastTitle,
    required this.episodeTitle,
    required this.audioUrl,
    this.artworkUrl,
    this.totalDurationMs,
    this.description,
    required this.lastPlayedDate,
    required this.lastPositionMs,//
  });
}
