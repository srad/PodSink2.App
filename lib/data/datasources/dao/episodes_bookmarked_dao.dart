import 'package:drift/drift.dart';
import '../../../data/datasources/app_database.dart';
import '../tables/episodes_bookmarked.dart';

part 'episodes_bookmarked_dao.g.dart';

@DriftAccessor(tables: [EpisodesBookmarked])
class EpisodesBookmarkedDao extends DatabaseAccessor<AppDatabase> with _$EpisodesBookmarkedDaoMixin {
  EpisodesBookmarkedDao(super.db);

  Future<List<EpisodesBookmarked>> getHistoryItems({int limit = 50, int offset = 0}) =>
      (select(episodesBookmarked)
        ..orderBy([(t) => OrderingTerm(expression: t.lastPlayedDate, mode: OrderingMode.desc)])
        ..limit(limit, offset: offset))
          .get();

  Future<int> addOrUpdateHistoryItem(EpisodesBookmarked item) =>
      into(episodesBookmarked).insert(item, mode: InsertMode.replace);

  Future<int> deleteHistoryItem(String guid) =>
      (delete(episodesBookmarked)..where((tbl) => tbl.guid.equals(guid))).go();

  Future<int> clearBookmarks() => delete(episodesBookmarked).go();


}