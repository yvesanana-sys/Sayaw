import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../fractional_order.dart';
import 'database.dart';
import 'tables.dart';

part 'playlist_dao.g.dart';

/// One row of a set, with the track and dance type it points at already
/// resolved. Everything the deck screen draws, and everything the repository
/// needs to build a `QueueEntry`, comes from this.
class PlaylistRow {
  const PlaylistRow({required this.item, this.track, this.danceType});

  final PlaylistItem item;

  /// Null for an announcement, silence or marker row, which have no track.
  final Track? track;
  final DanceType? danceType;
}

/// Playlists and their ordered rows.
@DriftAccessor(tables: [Playlists, PlaylistItems, Tracks, DanceTypes])
class PlaylistDao extends DatabaseAccessor<SayawDatabase> with _$PlaylistDaoMixin {
  PlaylistDao(super.db);

  // ---------------------------------------------------------------------
  // Playlists
  // ---------------------------------------------------------------------

  Stream<List<Playlist>> watchAll({bool includeArchived = false}) {
    final q = select(playlists)
      ..orderBy([
        (p) => OrderingTerm.desc(p.eventDate),
        (p) => OrderingTerm.asc(p.name),
      ]);
    if (!includeArchived) q.where((p) => p.isArchived.equals(false));
    return q.watch();
  }

  Future<Playlist?> byId(String id) =>
      (select(playlists)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<String> createPlaylist({
    required String name,
    String? description,
    String? eventKind,
    DateTime? eventDate,
    String? id,
  }) async {
    final now = clock.now();
    final rowId = id ?? newId();
    await into(playlists).insert(PlaylistsCompanion.insert(
      id: rowId,
      name: name,
      description: Value(description),
      eventKind: Value(eventKind),
      eventDate: Value(eventDate),
      createdAt: now,
      updatedAt: now,
    ));
    return rowId;
  }

  /// How the set is shaped: stop after [songLimit] songs, playing
  /// [targetDuration] of each.
  ///
  /// Both are required and both are nullable, so a caller has to say what it
  /// means for each — passing null is "no limit", not "leave it alone". A
  /// rotation that has been turned back into an ordinary set needs to be able
  /// to clear these, and an optional argument could not express it.
  Future<void> setShape(
    String playlistId, {
    required int? songLimit,
    required Duration? targetDuration,
    Duration rotationGap = Duration.zero,
  }) =>
      (update(playlists)..where((p) => p.id.equals(playlistId))).write(
        PlaylistsCompanion(
          songLimit: Value(songLimit),
          targetDurationMs: Value(targetDuration),
          rotationGapMs: Value(rotationGap),
          updatedAt: Value(clock.now()),
        ),
      );

  // ---------------------------------------------------------------------
  // Rows
  // ---------------------------------------------------------------------

  SimpleSelectStatement<$PlaylistItemsTable, PlaylistItem> _itemsOf(
          String playlistId) =>
      select(playlistItems)
        ..where((i) => i.playlistId.equals(playlistId))
        ..orderBy([(i) => OrderingTerm.asc(i.position)]);

  Stream<List<PlaylistRow>> watchItems(String playlistId) =>
      _joinedItems(playlistId).watch();

  Future<List<PlaylistRow>> itemsOf(String playlistId) =>
      _joinedItems(playlistId).get();

  /// One row on its own, for re-resolving a single entry mid-set without
  /// reading the whole playlist back.
  ///
  /// Null once the row has been deleted, which is what happens when someone
  /// edits the set while it is playing.
  Future<PlaylistRow?> rowById(String itemId) =>
      _joinedRows(playlistItems.id.equals(itemId)).getSingleOrNull();

  Selectable<PlaylistRow> _joinedItems(String playlistId) => _joinedRows(
        playlistItems.playlistId.equals(playlistId),
        ordered: true,
      );

  Selectable<PlaylistRow> _joinedRows(
    Expression<bool> where, {
    bool ordered = false,
  }) {
    final q = select(playlistItems).join([
      leftOuterJoin(tracks, tracks.id.equalsExp(playlistItems.trackId)),
      leftOuterJoin(danceTypes, danceTypes.id.equalsExp(playlistItems.danceTypeId)),
    ])..where(where);

    if (ordered) q.orderBy([OrderingTerm.asc(playlistItems.position)]);

    return q.map((row) => PlaylistRow(
          item: row.readTable(playlistItems),
          track: row.readTableOrNull(tracks),
          danceType: row.readTableOrNull(danceTypes),
        ));
  }

  /// Adds a track to the end of the set.
  Future<String> appendTrack({
    required String playlistId,
    required String trackId,
    String? danceTypeId,
    String? id,
  }) async {
    final now = clock.now();
    final rowId = id ?? newId();

    await transaction(() async {
      final last = await _lastPosition(playlistId);
      await into(playlistItems).insert(PlaylistItemsCompanion.insert(
        id: rowId,
        playlistId: playlistId,
        position: positionBetween(last, null)!,
        trackId: Value(trackId),
        danceTypeId: Value(danceTypeId),
        itemType: const Value(PlaylistItemType.track),
        createdAt: now,
        updatedAt: now,
      ));
    });

    return rowId;
  }

  Future<int> removeItem(String itemId) =>
      (delete(playlistItems)..where((i) => i.id.equals(itemId))).go();

  /// Moves the row at [oldIndex] to [newIndex], following
  /// `ReorderableListView`'s post-removal index convention.
  ///
  /// Writes exactly one row in the ordinary case. Returns the row's new
  /// position, which is what the UI needs to keep its optimistic list in step
  /// with the database.
  Future<double> move({
    required String playlistId,
    required int oldIndex,
    required int newIndex,
  }) =>
      transaction(() async {
        var rows = await _itemsOf(playlistId).get();
        var next = reorderPosition(
          [for (final r in rows) r.position],
          oldIndex,
          newIndex,
        );

        // The neighbours have been subdivided about fifty times and there is no
        // longer a double between them. Spread the whole set back out and try
        // once more; this is the only path that writes every row.
        if (next == null) {
          await _renormalize(rows);
          rows = await _itemsOf(playlistId).get();
          next = reorderPosition(
            [for (final r in rows) r.position],
            oldIndex,
            newIndex,
          )!;
        }

        await _setPosition(rows[oldIndex].id, next);
        return next;
      });

  /// Rewrites positions as `1.0, 2.0, 3.0…`.
  Future<void> renormalizePositions(String playlistId) =>
      transaction(() async => _renormalize(await _itemsOf(playlistId).get()));

  /// Which rows would still play with the network gone.
  ///
  /// Reads the `v_item_availability` view so the pre-flight check and the
  /// engine's skip logic can never disagree about what will play. Keyed by
  /// playlist item id.
  Future<Map<String, bool>> offlineAvailability(String playlistId) async {
    final rows = await customSelect(
      'SELECT item_id, offline_playable FROM v_item_availability '
      'WHERE playlist_id = ?1 ORDER BY position',
      variables: [Variable<String>(playlistId)],
      readsFrom: {playlistItems, tracks, db.cacheEntries},
    ).get();

    return {
      for (final row in rows)
        row.read<String>('item_id'): row.read<int>('offline_playable') == 1,
    };
  }

  // ---------------------------------------------------------------------

  Future<double?> _lastPosition(String playlistId) async {
    final max = playlistItems.position.max();
    final row = await (selectOnly(playlistItems)
          ..addColumns([max])
          ..where(playlistItems.playlistId.equals(playlistId)))
        .getSingle();
    return row.read(max);
  }

  Future<void> _setPosition(String itemId, double position) =>
      (update(playlistItems)..where((i) => i.id.equals(itemId))).write(
        PlaylistItemsCompanion(
          position: Value(position),
          updatedAt: Value(clock.now()),
        ),
      );

  /// [rows] must already be ordered by position.
  ///
  /// `idx_items_order` is unique, and SQLite checks it row by row, so writing
  /// the final positions directly can collide with a row that has not been
  /// rewritten yet. Shifting everything above the target range first — highest
  /// row first, so each write lands above every row still to be moved — keeps
  /// every intermediate state legal.
  Future<void> _renormalize(List<PlaylistItem> rows) async {
    if (rows.isEmpty) return;

    final shift = rows.length + 1 - rows.first.position;
    if (shift > 0) {
      for (final row in rows.reversed) {
        await _setPosition(row.id, row.position + shift);
      }
    }

    final fresh = renormalize(rows.length);
    for (var i = 0; i < rows.length; i++) {
      await _setPosition(rows[i].id, fresh[i]);
    }
  }
}
