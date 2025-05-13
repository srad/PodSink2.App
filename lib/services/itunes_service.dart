import 'dart:convert';

import 'package:podsink2/models/podcast.dart';
import 'package:http/http.dart' as http;

class ItunesService {
  final String _baseUrl = 'https://itunes.apple.com/search';

  Future<List<Podcast>> searchPodcasts(String term) async {
    try {
      final encodedTerm = Uri.encodeComponent(term);
      final url = Uri.parse('$_baseUrl?term=$encodedTerm&media=podcast&entity=podcast');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        return results.map((json) => Podcast.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load podcasts from iTunes (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect to iTunes service: $e');
    }
  }
}