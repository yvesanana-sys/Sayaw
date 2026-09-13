import 'package:drift/drift.dart';

import 'database.dart';
import 'tables.dart';

part 'track_dao.g.dart';

/// Reads and writes over the local mirror of every source.
///
/// Local files, Plex and TIDAL all land in one `tracks` table, which is what
/// makes a single search field across all three possible — the aggregation
/// happens at import time, not at query time, so searching still works with the
/// venue wifi down.
@DriftAccessor(tables: [Tracks])
class TrackDao extends DatabaseAccessor<SayawDatabase> with _$TrackDaoMixin {
  TrackDao(super.db);

  Future<Track?> byId(String id) =>
      (select(tracks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Track>> byIds(Iterable<String> ids) =>
      (select(tracks)..where((t) => t.id.isIn(ids))).get();

  /// The track behind a source triple `(source_type, account_id, source_id)`.
  ///
  /// The inverse of the mapper in `PlaylistRepository.sourceFor`: the cache is
  /// handed a source and has to find the row it belongs to, because
  /// `cache_entries` is keyed by track.
  Future<Track?> bySource({
    required SourceType sourceType,
    String? accountId,
    String? sourceId,
    String? localPath,
  }) {
    final query = select(tracks)
      ..where((t) => t.sourceType.equalsValue(sourceType))
      ..limit(1);

    if (sourceType == SourceType.local) {
      query.where((t) => t.localPath.equals(localPath ?? ''));
    } else {
      query.where((t) =>
          t.accountId.equals(accountId ?? '') &
          t.sourceId.equals(sourceId ?? ''));
    }

    return query.getSingleOrNull();
  }

  /// Insert, or update the row that already carries this id.
  Future<void> upsert(TracksCompanion track) =>
      into(tracks).insertOnConflictUpdate(track);

  Future<void> upsertAll(Iterable<TracksCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(tracks, rows.toList()));

  /// Every track that is a file on this machine.
  Future<List<Track>> localTracks() => (select(tracks)
        ..where((t) => t.sourceType.equalsValue(SourceType.local)))
      .get();

  /// Empties the library. Every row that pointed at a track — the set, the
  /// cache index, the history — goes with it, by the schema's own cascades.
  /// The files on disk are not touched: Sayaw only ever reads them.
  Future<int> deleteAll() => delete(tracks).go();

  Future<int> count() async {
    final n = tracks.id.count();
    final row = await (selectOnly(tracks)..addColumns([n])).getSingle();
    return row.read(n) ?? 0;
  }

  Future<int> deleteById(String id) =>
      (delete(tracks)..where((t) => t.id.equals(id))).go();

  /// What arrived most recently, for the library pane before anyone has typed
  /// anything. A freshly imported folder is the thing an operator is most
  /// likely to be looking for.
  /// Every track the library files under one dance.
  ///
  /// The app has no notion of genre — `default_dance_type_id` is how music has
  /// been classified here since the schema was written — so this is what "a
  /// Bachata track" means.
  Future<List<Track>> byDanceType(String danceTypeId) => (select(tracks)
        ..where((t) => t.defaultDanceTypeId.equals(danceTypeId))
        ..orderBy([(t) => OrderingTerm.asc(t.title)]))
      .get();

  /// Newest import first, and within one import the folder's own order.
  ///
  /// Every file in a scan gets the same `added_at`, so between them the
  /// order was whatever SQLite felt like — a numbered folder shown shuffled,
  /// which beside a set built from it in order read as the two disagreeing.
  Future<List<Track>> recentlyAdded({int limit = 50}) => (select(tracks)
        ..orderBy([
          (t) => OrderingTerm.desc(t.addedAt),
          (t) => OrderingTerm(
                expression: coalesce([t.localPath, t.title]).collate(
                  Collate.noCase,
                ),
              ),
        ])
        ..limit(limit))
      .get();

  /// Full-text search over title, artist and album, ranked by bm25.
  ///
  /// The last word is treated as a prefix so results narrow as the operator
  /// types — the search field is used mid-set, one-handed, in a dark room.
  Future<List<Track>> search(String query, {int limit = 50}) {
    final match = ftsQuery(query);
    if (match == null) return Future.value(const []);

    return customSelect(
      'SELECT t.* FROM tracks_fts '
      'JOIN tracks t ON t.rowid = tracks_fts.rowid '
      'WHERE tracks_fts MATCH ?1 '
      'ORDER BY bm25(tracks_fts) LIMIT ?2',
      variables: [Variable<String>(match), Variable<int>(limit)],
      readsFrom: {tracks},
    ).asyncMap((row) => tracks.mapFromRow(row)).get();
  }

  /// Every track the search would list for [query], without the cap the list
  /// on screen has, and in *filename* order rather than search rank.
  ///
  /// These ids feed a set, and a set has an order the operator reads top to
  /// bottom. Rank is right for a list being scanned for one song; it is
  /// meaningless as a running order, and "most recently added first" is the
  /// folder backwards. Files named to play in order — `01_`, `02_` — arrive
  /// in it.
  ///
  /// The filename, not the title. A title comes from the file's tag when it
  /// has one and from the filename when it does not, and a folder where some
  /// files are tagged sorts the tagged ones by a name nobody numbered — so
  /// `00_03_Rilassamento` went to the bottom of the set while `00_04` stayed
  /// at the top, and a hundred rows down looked like a song never added. A
  /// track with no file — a server's — sorts by its title among them.
  Future<List<String>> idsMatching(String query) async {
    if (query.trim().isEmpty) {
      final rows = await customSelect(
        'SELECT id FROM tracks '
        'ORDER BY COALESCE(local_path, title) COLLATE NOCASE',
        readsFrom: {tracks},
      ).get();
      return [for (final row in rows) row.read<String>('id')];
    }

    // Typed, but nothing in it to search on: what the list shows for that is
    // nothing, and this answers the same.
    final match = ftsQuery(query);
    if (match == null) return const [];

    final rows = await customSelect(
      'SELECT t.id AS id FROM tracks_fts '
      'JOIN tracks t ON t.rowid = tracks_fts.rowid '
      'WHERE tracks_fts MATCH ?1 '
      'ORDER BY COALESCE(t.local_path, t.title) COLLATE NOCASE',
      variables: [Variable<String>(match)],
      readsFrom: {tracks},
    ).get();
    return [for (final row in rows) row.read<String>('id')];
  }

  /// The same search as a live query, for a results list that updates while a
  /// library scan is still running.
  Stream<List<Track>> watchSearch(String query, {int limit = 50}) {
    final match = ftsQuery(query);
    if (match == null) return Stream.value(const []);

    return customSelect(
      'SELECT t.* FROM tracks_fts '
      'JOIN tracks t ON t.rowid = tracks_fts.rowid '
      'WHERE tracks_fts MATCH ?1 '
      'ORDER BY bm25(tracks_fts) LIMIT ?2',
      variables: [Variable<String>(match), Variable<int>(limit)],
      readsFrom: {tracks},
    ).asyncMap((row) => tracks.mapFromRow(row)).watch();
  }
}

/// Turns operator input into an FTS5 match expression, or null when there is
/// nothing searchable in it.
///
/// Every token is quoted, so `AND`, `NOT`, `*`, `:` and `"` are matched as text
/// instead of being read as query syntax — a title like `Sway (12" Mix)` would
/// otherwise raise a syntax error rather than finding the track.
String? ftsQuery(String input) {
  final tokens = input
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return null;

  // Only the final token gets the prefix wildcard: while typing "wal", the
  // intent is "starts with wal", but an earlier completed word is a real word.
  return [
    for (var i = 0; i < tokens.length; i++)
      i == tokens.length - 1 ? '"${tokens[i]}"*' : '"${tokens[i]}"',
  ].join(' ');
}
