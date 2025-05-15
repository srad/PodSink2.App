import 'package:drift/drift.dart';

/// Converts a nullable Duration to/from an integer (total seconds) for database storage.
class NullableDurationConverter extends TypeConverter<Duration?, int?> {
  const NullableDurationConverter();

  @override
  Duration? fromSql(int? fromDb) {
    return fromDb == null ? null : Duration(seconds: fromDb);
  }

  @override
  int? toSql(Duration? value) {
    return value?.inSeconds;
  }
}