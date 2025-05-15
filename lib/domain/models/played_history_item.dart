class PlayedEpisodeHistoryItemModel {
  final String guid; // Episode GUID, primary key
  final String podcastTitle;
  final String episodeTitle;
  final String audioUrl; // To re-initiate playback if needed
  final String? artworkUrl;
  final int? totalDurationMs; // Store as int (milliseconds)
  int lastPositionMs; // Store as int (milliseconds)
  DateTime lastPlayedDate;

  PlayedEpisodeHistoryItemModel({
    required this.guid,
    required this.podcastTitle,
    required this.episodeTitle,
    required this.audioUrl,
    this.artworkUrl,
    this.totalDurationMs,
    required this.lastPositionMs,
    required this.lastPlayedDate, //
  });

  Map<String, dynamic> toMap() {
    return {
      'guid': guid,
      'podcastTitle': podcastTitle,
      'episodeTitle': episodeTitle,
      'audioUrl': audioUrl,
      'artworkUrl': artworkUrl,
      'totalDurationMs': totalDurationMs,
      'lastPositionMs': lastPositionMs,
      'lastPlayedDate': lastPlayedDate.toIso8601String(), // Store date as ISO8601 string
    };
  }

  factory PlayedEpisodeHistoryItemModel.fromMap(Map<String, dynamic> map) {
    return PlayedEpisodeHistoryItemModel(
      guid: map['guid'] as String,
      podcastTitle: map['podcastTitle'] as String,
      episodeTitle: map['episodeTitle'] as String,
      audioUrl: map['audioUrl'] as String,
      artworkUrl: map['artworkUrl'] as String?,
      totalDurationMs: map['totalDurationMs'] as int?,
      lastPositionMs: map['lastPositionMs'] as int,
      lastPlayedDate: DateTime.parse(map['lastPlayedDate'] as String), //
    );
  }
}
