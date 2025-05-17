import 'package:drift/drift.dart';
import '../../../data/datasources/app_database.dart';
import '../tables/bookmarked_episodes.dart';

part 'bookmarked_episodes_dao.g.dart';

@DriftAccessor(tables: [BookmarkedEpisodes])
class BookmarkedEpisodesDao extends DatabaseAccessor<AppDatabase> with _$BookmarkedEpisodesDaoMixin {
  BookmarkedEpisodesDao(super.db);

  Future<List<BookmarkedEpisode>> getEpisodes({int limit = 50, int offset = 0}) =>
      (select(bookmarkedEpisodes)
            ..orderBy([(t) => OrderingTerm(expression: t.lastPlayedDate, mode: OrderingMode.desc)])
            ..limit(limit, offset: offset))
          .get();

  Future<int> addOrUpdateBookmark(BookmarkedEpisodesCompanion episode) => into(bookmarkedEpisodes).insert(episode, mode: InsertMode.replace);

  Future<int> removeBookmark(String guid) => (delete(bookmarkedEpisodes)..where((tbl) => tbl.guid.equals(guid))).go();

  Future<int> clearBookmarks() => delete(bookmarkedEpisodes).go();

  Future<int> addOrReplaceBookmarkEpisode(BookmarkedEpisodesCompanion companion) async {
    return into(bookmarkedEpisodes).insert(companion, mode: InsertMode.insertOrReplace);
  }

  Future<bool> isEpisodeBookmarked(String guid) async {
    final episode = await (select(bookmarkedEpisodes)..where((tbl) => tbl.guid.equals(guid))).getSingleOrNull();
    return episode != null;
  }
}
