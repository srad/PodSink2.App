import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:podsink2/domain/models/episode.dart';
import 'package:podsink2/domain/models/podcast.dart';
import 'package:webfeed_plus/domain/atom_feed.dart';
import 'package:webfeed_plus/domain/rss_feed.dart';

class RssParserService {
  Future<List<EpisodeModel>> fetchEpisodes(PodcastModel podcast) async {
    if (podcast.feedUrl.isEmpty) return [];
    try {
      final response = await http.get(Uri.parse(podcast.feedUrl));
      if (response.statusCode == 200) {
        try {
          var rssFeed = RssFeed.parse(response.body);
          if (rssFeed.items == null || rssFeed.items!.isEmpty) {
            return _parseAtomFeed(response.body, podcast);
          }
          return rssFeed.items!.map((item) => EpisodeModel.fromRssItem(item, rssFeed.title ?? podcast.title, rssFeed.image?.url ?? podcast.artworkUrl)).toList();
        } catch (e) {
          return _parseAtomFeed(response.body, podcast);
        }
      } else {
        throw Exception('Failed to load RSS feed (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching/parsing feed: $e');
    }
  }

  List<EpisodeModel> _parseAtomFeed(String xmlString, PodcastModel podcast) {
    try {
      var atomFeed = AtomFeed.parse(xmlString);
      if (atomFeed.items == null || atomFeed.items!.isEmpty) return [];
      return atomFeed.items!.map((item) {
        String? audioUrl = item.links?.firstWhere((link) => link.rel == 'enclosure' && (link.type?.startsWith('audio/') ?? false))?.href;
        return EpisodeModel(
          guid: item.id ?? UniqueKey().toString(),
          podcastTitle: atomFeed.title ?? podcast.title,
          title: item.title ?? 'Unknown Episode',
          description: item.summary ?? item.content ?? 'No description.',
          audioUrl: audioUrl ?? '',
          pubDate: item.updated ?? (item.published != null ? DateTime.tryParse(item.published!) : null),
          artworkUrl: atomFeed.logo ?? atomFeed.icon ?? podcast.artworkUrl,
          duration: null,
        );
      }).toList();
    } catch (e) {
      throw Exception('Feed format not recognized or Atom parsing error: $e');
    }
  }
}