import 'package:drift/drift.dart';
import '../type_converters.dart'; // Import your type converter

// Using @DataClassName to avoid collision if you keep your existing 'Episode' domain class.
// Drift will generate a data class named 'EpisodeRecord'.
// The companion object for inserts/updates will be 'EpisodesCompanion'.
@UseRowClass(Record)
class Episodes extends Table {
  TextColumn get guid => text()();
  TextColumn get podcastTitle => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get audioUrl => text()();
  DateTimeColumn get pubDate => dateTime().nullable()();
  TextColumn get artworkUrl => text().nullable()();

  // Use the type converter for the duration field
  IntColumn get durationInSeconds => integer().nullable().map(const NullableDurationConverter())();
  // The column in SQLite will be 'duration_in_seconds' of type INTEGER.
  // In your Dart code via Drift, you'll interact with it as a Duration?

  @override
  Set<Column> get primaryKey => {guid};

// You can also define custom names for generated classes if needed,
// e.g., if you want the table to be 'episodes' but the data class 'Episode'.
// By default, table 'Episodes' will generate data class 'Episode' (if no @DataClassName)
// or 'EpisodeRecord' (as specified).
}