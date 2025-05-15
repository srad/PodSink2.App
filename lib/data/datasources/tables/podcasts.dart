import 'package:drift/drift.dart';

@UseRowClass(Record)
class Podcasts extends Table {
  TextColumn get id => text()(); // By default, TEXT PRIMARY KEY NOT NULL
  TextColumn get title => text()();
  TextColumn get artistName => text()();
  TextColumn get artworkUrl => text()();
  TextColumn get feedUrl => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}