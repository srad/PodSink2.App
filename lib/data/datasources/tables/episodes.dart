import 'package:drift/drift.dart';
import '../type_converters.dart';

@UseRowClass(Record)
class Episodes extends Table {
  TextColumn get guid => text()();
  TextColumn get podcastTitle => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get audioUrl => text()();
  DateTimeColumn get pubDate => dateTime().nullable()();
  TextColumn get artworkUrl => text().nullable()();
  BoolColumn get isNew => boolean().withDefault(const Constant(true))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get durationInSeconds => integer().nullable().map(const NullableDurationConverter())();

  @override
  Set<Column> get primaryKey => {guid};
}