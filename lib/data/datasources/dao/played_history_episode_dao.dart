import 'package:drift/drift.dart';
import '../../../data/datasources/app_database.dart';
import '../tables/played_history_episodes.dart';

part 'played_history_episode_dao.g.dart';

@DriftAccessor(tables: [PlayedHistoryEpisodes])
class PlayedHistoryEpisodesDao extends DatabaseAccessor<AppDatabase> with _$PlayedHistoryEpisodesDaoMixin {
  PlayedHistoryEpisodesDao(super.db);

  Future<List<PlayedHistoryEpisode>> getHistoryItems({int limit = 50, int offset = 0}) =>
      (select(playedHistoryEpisodes)
        ..orderBy([(t) => OrderingTerm(expression: t.lastPlayedDate, mode: OrderingMode.desc)])
        ..limit(limit, offset: offset))
          .get();

  Future<int> addOrUpdateHistoryItem(PlayedHistoryEpisodesCompanion item) =>
      into(playedHistoryEpisodes).insert(item, mode: InsertMode.replace);

  Future<int> deleteHistoryItem(String guid) =>
      (delete(playedHistoryEpisodes)..where((tbl) => tbl.guid.equals(guid))).go();

  Future<int> clearAllHistory() => delete(playedHistoryEpisodes).go();
}