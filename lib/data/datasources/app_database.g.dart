// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
typedef Podcast =
    ({
      String artistName,
      String artworkUrl,
      String feedUrl,
      String id,
      int sortOrder,
      String title,
    });

class $PodcastsTable extends Podcasts with TableInfo<$PodcastsTable, Podcast> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PodcastsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistNameMeta = const VerificationMeta(
    'artistName',
  );
  @override
  late final GeneratedColumn<String> artistName = GeneratedColumn<String>(
    'artist_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedUrlMeta = const VerificationMeta(
    'feedUrl',
  );
  @override
  late final GeneratedColumn<String> feedUrl = GeneratedColumn<String>(
    'feed_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artistName,
    artworkUrl,
    feedUrl,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'podcasts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Podcast> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist_name')) {
      context.handle(
        _artistNameMeta,
        artistName.isAcceptableOrUnknown(data['artist_name']!, _artistNameMeta),
      );
    } else if (isInserting) {
      context.missing(_artistNameMeta);
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_artworkUrlMeta);
    }
    if (data.containsKey('feed_url')) {
      context.handle(
        _feedUrlMeta,
        feedUrl.isAcceptableOrUnknown(data['feed_url']!, _feedUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_feedUrlMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Podcast map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return (
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      artistName:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}artist_name'],
          )!,
      artworkUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}artwork_url'],
          )!,
      feedUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}feed_url'],
          )!,
      sortOrder:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}sort_order'],
          )!,
    );
  }

  @override
  $PodcastsTable createAlias(String alias) {
    return $PodcastsTable(attachedDatabase, alias);
  }
}

class PodcastsCompanion extends UpdateCompanion<Podcast> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> artistName;
  final Value<String> artworkUrl;
  final Value<String> feedUrl;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const PodcastsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artistName = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.feedUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PodcastsCompanion.insert({
    required String id,
    required String title,
    required String artistName,
    required String artworkUrl,
    required String feedUrl,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       artistName = Value(artistName),
       artworkUrl = Value(artworkUrl),
       feedUrl = Value(feedUrl);
  static Insertable<Podcast> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artistName,
    Expression<String>? artworkUrl,
    Expression<String>? feedUrl,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artistName != null) 'artist_name': artistName,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (feedUrl != null) 'feed_url': feedUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PodcastsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? artistName,
    Value<String>? artworkUrl,
    Value<String>? feedUrl,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return PodcastsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      feedUrl: feedUrl ?? this.feedUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artistName.present) {
      map['artist_name'] = Variable<String>(artistName.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (feedUrl.present) {
      map['feed_url'] = Variable<String>(feedUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PodcastsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artistName: $artistName, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('feedUrl: $feedUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

typedef PlayedHistoryEpisode =
    ({
      String? artworkUrl,
      String audioUrl,
      String episodeTitle,
      String guid,
      DateTime lastPlayedDate,
      int lastPositionMs,
      String podcastTitle,
      int? totalDurationMs,
    });

class $PlayedHistoryEpisodesTable extends PlayedHistoryEpisodes
    with TableInfo<$PlayedHistoryEpisodesTable, PlayedHistoryEpisode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayedHistoryEpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _podcastTitleMeta = const VerificationMeta(
    'podcastTitle',
  );
  @override
  late final GeneratedColumn<String> podcastTitle = GeneratedColumn<String>(
    'podcast_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeTitleMeta = const VerificationMeta(
    'episodeTitle',
  );
  @override
  late final GeneratedColumn<String> episodeTitle = GeneratedColumn<String>(
    'episode_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalDurationMsMeta = const VerificationMeta(
    'totalDurationMs',
  );
  @override
  late final GeneratedColumn<int> totalDurationMs = GeneratedColumn<int>(
    'total_duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPositionMsMeta = const VerificationMeta(
    'lastPositionMs',
  );
  @override
  late final GeneratedColumn<int> lastPositionMs = GeneratedColumn<int>(
    'last_position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPlayedDateMeta = const VerificationMeta(
    'lastPlayedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedDate =
      GeneratedColumn<DateTime>(
        'last_played_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    guid,
    podcastTitle,
    episodeTitle,
    audioUrl,
    artworkUrl,
    totalDurationMs,
    lastPositionMs,
    lastPlayedDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'played_history_episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayedHistoryEpisode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('podcast_title')) {
      context.handle(
        _podcastTitleMeta,
        podcastTitle.isAcceptableOrUnknown(
          data['podcast_title']!,
          _podcastTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_podcastTitleMeta);
    }
    if (data.containsKey('episode_title')) {
      context.handle(
        _episodeTitleMeta,
        episodeTitle.isAcceptableOrUnknown(
          data['episode_title']!,
          _episodeTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_episodeTitleMeta);
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_audioUrlMeta);
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('total_duration_ms')) {
      context.handle(
        _totalDurationMsMeta,
        totalDurationMs.isAcceptableOrUnknown(
          data['total_duration_ms']!,
          _totalDurationMsMeta,
        ),
      );
    }
    if (data.containsKey('last_position_ms')) {
      context.handle(
        _lastPositionMsMeta,
        lastPositionMs.isAcceptableOrUnknown(
          data['last_position_ms']!,
          _lastPositionMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPositionMsMeta);
    }
    if (data.containsKey('last_played_date')) {
      context.handle(
        _lastPlayedDateMeta,
        lastPlayedDate.isAcceptableOrUnknown(
          data['last_played_date']!,
          _lastPlayedDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastPlayedDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {guid};
  @override
  PlayedHistoryEpisode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return (
      guid:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}guid'],
          )!,
      podcastTitle:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}podcast_title'],
          )!,
      episodeTitle:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}episode_title'],
          )!,
      audioUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}audio_url'],
          )!,
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      totalDurationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_duration_ms'],
      ),
      lastPositionMs:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}last_position_ms'],
          )!,
      lastPlayedDate:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}last_played_date'],
          )!,
    );
  }

  @override
  $PlayedHistoryEpisodesTable createAlias(String alias) {
    return $PlayedHistoryEpisodesTable(attachedDatabase, alias);
  }
}

class PlayedHistoryEpisodesCompanion
    extends UpdateCompanion<PlayedHistoryEpisode> {
  final Value<String> guid;
  final Value<String> podcastTitle;
  final Value<String> episodeTitle;
  final Value<String> audioUrl;
  final Value<String?> artworkUrl;
  final Value<int?> totalDurationMs;
  final Value<int> lastPositionMs;
  final Value<DateTime> lastPlayedDate;
  final Value<int> rowid;
  const PlayedHistoryEpisodesCompanion({
    this.guid = const Value.absent(),
    this.podcastTitle = const Value.absent(),
    this.episodeTitle = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    this.lastPositionMs = const Value.absent(),
    this.lastPlayedDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlayedHistoryEpisodesCompanion.insert({
    required String guid,
    required String podcastTitle,
    required String episodeTitle,
    required String audioUrl,
    this.artworkUrl = const Value.absent(),
    this.totalDurationMs = const Value.absent(),
    required int lastPositionMs,
    required DateTime lastPlayedDate,
    this.rowid = const Value.absent(),
  }) : guid = Value(guid),
       podcastTitle = Value(podcastTitle),
       episodeTitle = Value(episodeTitle),
       audioUrl = Value(audioUrl),
       lastPositionMs = Value(lastPositionMs),
       lastPlayedDate = Value(lastPlayedDate);
  static Insertable<PlayedHistoryEpisode> custom({
    Expression<String>? guid,
    Expression<String>? podcastTitle,
    Expression<String>? episodeTitle,
    Expression<String>? audioUrl,
    Expression<String>? artworkUrl,
    Expression<int>? totalDurationMs,
    Expression<int>? lastPositionMs,
    Expression<DateTime>? lastPlayedDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (guid != null) 'guid': guid,
      if (podcastTitle != null) 'podcast_title': podcastTitle,
      if (episodeTitle != null) 'episode_title': episodeTitle,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (totalDurationMs != null) 'total_duration_ms': totalDurationMs,
      if (lastPositionMs != null) 'last_position_ms': lastPositionMs,
      if (lastPlayedDate != null) 'last_played_date': lastPlayedDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlayedHistoryEpisodesCompanion copyWith({
    Value<String>? guid,
    Value<String>? podcastTitle,
    Value<String>? episodeTitle,
    Value<String>? audioUrl,
    Value<String?>? artworkUrl,
    Value<int?>? totalDurationMs,
    Value<int>? lastPositionMs,
    Value<DateTime>? lastPlayedDate,
    Value<int>? rowid,
  }) {
    return PlayedHistoryEpisodesCompanion(
      guid: guid ?? this.guid,
      podcastTitle: podcastTitle ?? this.podcastTitle,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      audioUrl: audioUrl ?? this.audioUrl,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      lastPositionMs: lastPositionMs ?? this.lastPositionMs,
      lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (podcastTitle.present) {
      map['podcast_title'] = Variable<String>(podcastTitle.value);
    }
    if (episodeTitle.present) {
      map['episode_title'] = Variable<String>(episodeTitle.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (totalDurationMs.present) {
      map['total_duration_ms'] = Variable<int>(totalDurationMs.value);
    }
    if (lastPositionMs.present) {
      map['last_position_ms'] = Variable<int>(lastPositionMs.value);
    }
    if (lastPlayedDate.present) {
      map['last_played_date'] = Variable<DateTime>(lastPlayedDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayedHistoryEpisodesCompanion(')
          ..write('guid: $guid, ')
          ..write('podcastTitle: $podcastTitle, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('totalDurationMs: $totalDurationMs, ')
          ..write('lastPositionMs: $lastPositionMs, ')
          ..write('lastPlayedDate: $lastPlayedDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

typedef Episode =
    ({
      String? artworkUrl,
      String audioUrl,
      String description,
      Duration? durationInSeconds,
      String guid,
      String podcastTitle,
      DateTime? pubDate,
      String title,
    });

class $EpisodesTable extends Episodes with TableInfo<$EpisodesTable, Episode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _guidMeta = const VerificationMeta('guid');
  @override
  late final GeneratedColumn<String> guid = GeneratedColumn<String>(
    'guid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _podcastTitleMeta = const VerificationMeta(
    'podcastTitle',
  );
  @override
  late final GeneratedColumn<String> podcastTitle = GeneratedColumn<String>(
    'podcast_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pubDateMeta = const VerificationMeta(
    'pubDate',
  );
  @override
  late final GeneratedColumn<DateTime> pubDate = GeneratedColumn<DateTime>(
    'pub_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration?, int>
  durationInSeconds = GeneratedColumn<int>(
    'duration_in_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Duration?>($EpisodesTable.$converterdurationInSeconds);
  @override
  List<GeneratedColumn> get $columns => [
    guid,
    podcastTitle,
    title,
    description,
    audioUrl,
    pubDate,
    artworkUrl,
    durationInSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Episode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('guid')) {
      context.handle(
        _guidMeta,
        guid.isAcceptableOrUnknown(data['guid']!, _guidMeta),
      );
    } else if (isInserting) {
      context.missing(_guidMeta);
    }
    if (data.containsKey('podcast_title')) {
      context.handle(
        _podcastTitleMeta,
        podcastTitle.isAcceptableOrUnknown(
          data['podcast_title']!,
          _podcastTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_podcastTitleMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_audioUrlMeta);
    }
    if (data.containsKey('pub_date')) {
      context.handle(
        _pubDateMeta,
        pubDate.isAcceptableOrUnknown(data['pub_date']!, _pubDateMeta),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {guid};
  @override
  Episode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return (
      guid:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}guid'],
          )!,
      podcastTitle:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}podcast_title'],
          )!,
      title:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}title'],
          )!,
      description:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}description'],
          )!,
      audioUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}audio_url'],
          )!,
      pubDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pub_date'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      durationInSeconds: $EpisodesTable.$converterdurationInSeconds.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duration_in_seconds'],
        ),
      ),
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }

  static TypeConverter<Duration?, int?> $converterdurationInSeconds =
      const NullableDurationConverter();
}

class EpisodesCompanion extends UpdateCompanion<Episode> {
  final Value<String> guid;
  final Value<String> podcastTitle;
  final Value<String> title;
  final Value<String> description;
  final Value<String> audioUrl;
  final Value<DateTime?> pubDate;
  final Value<String?> artworkUrl;
  final Value<Duration?> durationInSeconds;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.guid = const Value.absent(),
    this.podcastTitle = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.pubDate = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.durationInSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String guid,
    required String podcastTitle,
    required String title,
    required String description,
    required String audioUrl,
    this.pubDate = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.durationInSeconds = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : guid = Value(guid),
       podcastTitle = Value(podcastTitle),
       title = Value(title),
       description = Value(description),
       audioUrl = Value(audioUrl);
  static Insertable<Episode> custom({
    Expression<String>? guid,
    Expression<String>? podcastTitle,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? audioUrl,
    Expression<DateTime>? pubDate,
    Expression<String>? artworkUrl,
    Expression<int>? durationInSeconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (guid != null) 'guid': guid,
      if (podcastTitle != null) 'podcast_title': podcastTitle,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (pubDate != null) 'pub_date': pubDate,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (durationInSeconds != null) 'duration_in_seconds': durationInSeconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<String>? guid,
    Value<String>? podcastTitle,
    Value<String>? title,
    Value<String>? description,
    Value<String>? audioUrl,
    Value<DateTime?>? pubDate,
    Value<String?>? artworkUrl,
    Value<Duration?>? durationInSeconds,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      guid: guid ?? this.guid,
      podcastTitle: podcastTitle ?? this.podcastTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      pubDate: pubDate ?? this.pubDate,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      durationInSeconds: durationInSeconds ?? this.durationInSeconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (guid.present) {
      map['guid'] = Variable<String>(guid.value);
    }
    if (podcastTitle.present) {
      map['podcast_title'] = Variable<String>(podcastTitle.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (pubDate.present) {
      map['pub_date'] = Variable<DateTime>(pubDate.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (durationInSeconds.present) {
      map['duration_in_seconds'] = Variable<int>(
        $EpisodesTable.$converterdurationInSeconds.toSql(
          durationInSeconds.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('guid: $guid, ')
          ..write('podcastTitle: $podcastTitle, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('pubDate: $pubDate, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('durationInSeconds: $durationInSeconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PodcastsTable podcasts = $PodcastsTable(this);
  late final $PlayedHistoryEpisodesTable playedHistoryEpisodes =
      $PlayedHistoryEpisodesTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final PodcastsDao podcastsDao = PodcastsDao(this as AppDatabase);
  late final PlayedHistoryEpisodesDao playedHistoryEpisodesDao =
      PlayedHistoryEpisodesDao(this as AppDatabase);
  late final EpisodesDao episodesDao = EpisodesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    podcasts,
    playedHistoryEpisodes,
    episodes,
  ];
}

typedef $$PodcastsTableCreateCompanionBuilder =
    PodcastsCompanion Function({
      required String id,
      required String title,
      required String artistName,
      required String artworkUrl,
      required String feedUrl,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$PodcastsTableUpdateCompanionBuilder =
    PodcastsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> artistName,
      Value<String> artworkUrl,
      Value<String> feedUrl,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$PodcastsTableFilterComposer
    extends Composer<_$AppDatabase, $PodcastsTable> {
  $$PodcastsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PodcastsTableOrderingComposer
    extends Composer<_$AppDatabase, $PodcastsTable> {
  $$PodcastsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedUrl => $composableBuilder(
    column: $table.feedUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PodcastsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PodcastsTable> {
  $$PodcastsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artistName => $composableBuilder(
    column: $table.artistName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedUrl =>
      $composableBuilder(column: $table.feedUrl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$PodcastsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PodcastsTable,
          Podcast,
          $$PodcastsTableFilterComposer,
          $$PodcastsTableOrderingComposer,
          $$PodcastsTableAnnotationComposer,
          $$PodcastsTableCreateCompanionBuilder,
          $$PodcastsTableUpdateCompanionBuilder,
          (Podcast, BaseReferences<_$AppDatabase, $PodcastsTable, Podcast>),
          Podcast,
          PrefetchHooks Function()
        > {
  $$PodcastsTableTableManager(_$AppDatabase db, $PodcastsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PodcastsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$PodcastsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$PodcastsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artistName = const Value.absent(),
                Value<String> artworkUrl = const Value.absent(),
                Value<String> feedUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PodcastsCompanion(
                id: id,
                title: title,
                artistName: artistName,
                artworkUrl: artworkUrl,
                feedUrl: feedUrl,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String artistName,
                required String artworkUrl,
                required String feedUrl,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PodcastsCompanion.insert(
                id: id,
                title: title,
                artistName: artistName,
                artworkUrl: artworkUrl,
                feedUrl: feedUrl,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PodcastsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PodcastsTable,
      Podcast,
      $$PodcastsTableFilterComposer,
      $$PodcastsTableOrderingComposer,
      $$PodcastsTableAnnotationComposer,
      $$PodcastsTableCreateCompanionBuilder,
      $$PodcastsTableUpdateCompanionBuilder,
      (Podcast, BaseReferences<_$AppDatabase, $PodcastsTable, Podcast>),
      Podcast,
      PrefetchHooks Function()
    >;
typedef $$PlayedHistoryEpisodesTableCreateCompanionBuilder =
    PlayedHistoryEpisodesCompanion Function({
      required String guid,
      required String podcastTitle,
      required String episodeTitle,
      required String audioUrl,
      Value<String?> artworkUrl,
      Value<int?> totalDurationMs,
      required int lastPositionMs,
      required DateTime lastPlayedDate,
      Value<int> rowid,
    });
typedef $$PlayedHistoryEpisodesTableUpdateCompanionBuilder =
    PlayedHistoryEpisodesCompanion Function({
      Value<String> guid,
      Value<String> podcastTitle,
      Value<String> episodeTitle,
      Value<String> audioUrl,
      Value<String?> artworkUrl,
      Value<int?> totalDurationMs,
      Value<int> lastPositionMs,
      Value<DateTime> lastPlayedDate,
      Value<int> rowid,
    });

class $$PlayedHistoryEpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $PlayedHistoryEpisodesTable> {
  $$PlayedHistoryEpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get podcastTitle => $composableBuilder(
    column: $table.podcastTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlayedHistoryEpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlayedHistoryEpisodesTable> {
  $$PlayedHistoryEpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get podcastTitle => $composableBuilder(
    column: $table.podcastTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlayedHistoryEpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlayedHistoryEpisodesTable> {
  $$PlayedHistoryEpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get podcastTitle => $composableBuilder(
    column: $table.podcastTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalDurationMs => $composableBuilder(
    column: $table.totalDurationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPositionMs => $composableBuilder(
    column: $table.lastPositionMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedDate => $composableBuilder(
    column: $table.lastPlayedDate,
    builder: (column) => column,
  );
}

class $$PlayedHistoryEpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PlayedHistoryEpisodesTable,
          PlayedHistoryEpisode,
          $$PlayedHistoryEpisodesTableFilterComposer,
          $$PlayedHistoryEpisodesTableOrderingComposer,
          $$PlayedHistoryEpisodesTableAnnotationComposer,
          $$PlayedHistoryEpisodesTableCreateCompanionBuilder,
          $$PlayedHistoryEpisodesTableUpdateCompanionBuilder,
          (
            PlayedHistoryEpisode,
            BaseReferences<
              _$AppDatabase,
              $PlayedHistoryEpisodesTable,
              PlayedHistoryEpisode
            >,
          ),
          PlayedHistoryEpisode,
          PrefetchHooks Function()
        > {
  $$PlayedHistoryEpisodesTableTableManager(
    _$AppDatabase db,
    $PlayedHistoryEpisodesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$PlayedHistoryEpisodesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$PlayedHistoryEpisodesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$PlayedHistoryEpisodesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> guid = const Value.absent(),
                Value<String> podcastTitle = const Value.absent(),
                Value<String> episodeTitle = const Value.absent(),
                Value<String> audioUrl = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> totalDurationMs = const Value.absent(),
                Value<int> lastPositionMs = const Value.absent(),
                Value<DateTime> lastPlayedDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlayedHistoryEpisodesCompanion(
                guid: guid,
                podcastTitle: podcastTitle,
                episodeTitle: episodeTitle,
                audioUrl: audioUrl,
                artworkUrl: artworkUrl,
                totalDurationMs: totalDurationMs,
                lastPositionMs: lastPositionMs,
                lastPlayedDate: lastPlayedDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String guid,
                required String podcastTitle,
                required String episodeTitle,
                required String audioUrl,
                Value<String?> artworkUrl = const Value.absent(),
                Value<int?> totalDurationMs = const Value.absent(),
                required int lastPositionMs,
                required DateTime lastPlayedDate,
                Value<int> rowid = const Value.absent(),
              }) => PlayedHistoryEpisodesCompanion.insert(
                guid: guid,
                podcastTitle: podcastTitle,
                episodeTitle: episodeTitle,
                audioUrl: audioUrl,
                artworkUrl: artworkUrl,
                totalDurationMs: totalDurationMs,
                lastPositionMs: lastPositionMs,
                lastPlayedDate: lastPlayedDate,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlayedHistoryEpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PlayedHistoryEpisodesTable,
      PlayedHistoryEpisode,
      $$PlayedHistoryEpisodesTableFilterComposer,
      $$PlayedHistoryEpisodesTableOrderingComposer,
      $$PlayedHistoryEpisodesTableAnnotationComposer,
      $$PlayedHistoryEpisodesTableCreateCompanionBuilder,
      $$PlayedHistoryEpisodesTableUpdateCompanionBuilder,
      (
        PlayedHistoryEpisode,
        BaseReferences<
          _$AppDatabase,
          $PlayedHistoryEpisodesTable,
          PlayedHistoryEpisode
        >,
      ),
      PlayedHistoryEpisode,
      PrefetchHooks Function()
    >;
typedef $$EpisodesTableCreateCompanionBuilder =
    EpisodesCompanion Function({
      required String guid,
      required String podcastTitle,
      required String title,
      required String description,
      required String audioUrl,
      Value<DateTime?> pubDate,
      Value<String?> artworkUrl,
      Value<Duration?> durationInSeconds,
      Value<int> rowid,
    });
typedef $$EpisodesTableUpdateCompanionBuilder =
    EpisodesCompanion Function({
      Value<String> guid,
      Value<String> podcastTitle,
      Value<String> title,
      Value<String> description,
      Value<String> audioUrl,
      Value<DateTime?> pubDate,
      Value<String?> artworkUrl,
      Value<Duration?> durationInSeconds,
      Value<int> rowid,
    });

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get podcastTitle => $composableBuilder(
    column: $table.podcastTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration?, Duration, int>
  get durationInSeconds => $composableBuilder(
    column: $table.durationInSeconds,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get guid => $composableBuilder(
    column: $table.guid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get podcastTitle => $composableBuilder(
    column: $table.podcastTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pubDate => $composableBuilder(
    column: $table.pubDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationInSeconds => $composableBuilder(
    column: $table.durationInSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get guid =>
      $composableBuilder(column: $table.guid, builder: (column) => column);

  GeneratedColumn<String> get podcastTitle => $composableBuilder(
    column: $table.podcastTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get pubDate =>
      $composableBuilder(column: $table.pubDate, builder: (column) => column);

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Duration?, int> get durationInSeconds =>
      $composableBuilder(
        column: $table.durationInSeconds,
        builder: (column) => column,
      );
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTable,
          Episode,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
          Episode,
          PrefetchHooks Function()
        > {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> guid = const Value.absent(),
                Value<String> podcastTitle = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> audioUrl = const Value.absent(),
                Value<DateTime?> pubDate = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<Duration?> durationInSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                guid: guid,
                podcastTitle: podcastTitle,
                title: title,
                description: description,
                audioUrl: audioUrl,
                pubDate: pubDate,
                artworkUrl: artworkUrl,
                durationInSeconds: durationInSeconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String guid,
                required String podcastTitle,
                required String title,
                required String description,
                required String audioUrl,
                Value<DateTime?> pubDate = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<Duration?> durationInSeconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                guid: guid,
                podcastTitle: podcastTitle,
                title: title,
                description: description,
                audioUrl: audioUrl,
                pubDate: pubDate,
                artworkUrl: artworkUrl,
                durationInSeconds: durationInSeconds,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTable,
      Episode,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (Episode, BaseReferences<_$AppDatabase, $EpisodesTable, Episode>),
      Episode,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PodcastsTableTableManager get podcasts =>
      $$PodcastsTableTableManager(_db, _db.podcasts);
  $$PlayedHistoryEpisodesTableTableManager get playedHistoryEpisodes =>
      $$PlayedHistoryEpisodesTableTableManager(_db, _db.playedHistoryEpisodes);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
}
