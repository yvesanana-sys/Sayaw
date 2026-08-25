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

  /// Insert, or update the row that already carries this id.
  Future<void> upsert(TracksCompanion track) =>
      into(tracks).insertOnConflictUpdate(track);

  Future<void> upsertAll(Iterable<TracksCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(tracks, rows.toList()));

  Future<int> deleteById(String id) =>
      (delete(tracks)..where((t) => t.id.equals(id))).go();

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
