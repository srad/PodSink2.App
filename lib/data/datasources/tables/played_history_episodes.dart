import 'package:drift/drift.dart';

@UseRowClass(Record)
class PlayedHistoryEpisodes extends Table {
  TextColumn get guid => text()();
  TextColumn get podcastTitle => text()();
  TextColumn get episodeTitle => text()();
  TextColumn get audioUrl => text()();
  TextColumn get artworkUrl => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get totalDurationMs => integer().nullable()();
  IntColumn get lastPositionMs => integer()();
  DateTimeColumn get lastPlayedDate => dateTime()();

  @override
  Set<Column> get primaryKey => {guid};
}