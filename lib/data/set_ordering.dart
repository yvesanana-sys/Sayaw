import 'db/playlist_dao.dart';

/// Which way a generated set runs.
enum TempoOrder {
  /// Slowest first. What a Snowball climbs, and what keeps a single-dance set
  /// from lurching between its fastest and slowest track.
  ascending,

  /// Fastest first — a set that winds a floor down at the end of a night.
  descending,
}

/// One row's tempo, and where it came from.
///
/// The distinction matters to the operator: a set ordered on twelve real tags
/// and twenty-eight guesses is not the same set as one ordered on forty tags,
/// and they should be able to tell.
enum TempoSource {
  /// The file's own BPM tag.
  tagged,

  /// The middle of the row's dance type range. A Waltz with no tag is still a
  /// Waltz, and 84–90 is a better guess than nothing at all.
  danceType,

  /// Neither. Nothing can be worked out about this row's tempo.
  unknown,
}

/// The tempo a row is sorted on.
///
/// Null when there is neither a tag nor a dance type to fall back on, which is
/// most of an untagged m4a library — see the BPM notes in `track_metadata.dart`.
double? effectiveBpm(PlaylistRow row) {
  if (row.track?.bpm case final bpm? when bpm > 0) return bpm;

  final min = row.danceType?.bpmMin;
  final max = row.danceType?.bpmMax;
  if (min != null && max != null) return (min + max) / 2;
  return min ?? max;
}

TempoSource tempoSourceOf(PlaylistRow row) {
  if (row.track?.bpm case final bpm? when bpm > 0) return TempoSource.tagged;
  return effectiveBpm(row) == null
      ? TempoSource.unknown
      : TempoSource.danceType;
}

/// A set put in tempo order, and what had to be guessed to do it.
class OrderedSet {
  const OrderedSet({
    required this.itemIds,
    required this.guessed,
    required this.withoutTempo,
  });

  /// Every row of the set, in the order it should now play.
  final List<String> itemIds;

  /// Rows placed on their dance type's range rather than a tag of their own.
  final List<String> guessed;

  /// Rows nothing could be worked out for. Left in the order the operator put
  /// them in, at the end.
  final List<String> withoutTempo;

  int get total => itemIds.length;
  bool get isExact => guessed.isEmpty && withoutTempo.isEmpty;
}

/// Puts a set in tempo order.
///
/// Rows with no tempo at all are not sorted — they keep their existing order
/// and go last. Scattering them through the set would break the one property
/// the ordering exists to provide, and dropping them would change the set
/// behind the operator's back; leaving them at the end is the version they can
/// see and fix.
///
/// Stable: two tracks at the same tempo stay in the order they were put in.
/// `List.sort` is not stable, so the original index is part of the comparison
/// rather than trusted to be preserved.
OrderedSet orderByTempo(
  List<PlaylistRow> rows, {
  TempoOrder order = TempoOrder.ascending,
}) {
  final withTempo = <({PlaylistRow row, double bpm, int index})>[];
  final withoutTempo = <String>[];
  final guessed = <String>[];

  for (var i = 0; i < rows.length; i++) {
    final row = rows[i];
    final bpm = effectiveBpm(row);

    if (bpm == null) {
      withoutTempo.add(row.item.id);
      continue;
    }
    if (tempoSourceOf(row) == TempoSource.danceType) guessed.add(row.item.id);
    withTempo.add((row: row, bpm: bpm, index: i));
  }

  withTempo.sort((a, b) {
    final byTempo = order == TempoOrder.ascending
        ? a.bpm.compareTo(b.bpm)
        : b.bpm.compareTo(a.bpm);
    return byTempo != 0 ? byTempo : a.index.compareTo(b.index);
  });

  return OrderedSet(
    itemIds: [
      for (final entry in withTempo) entry.row.item.id,
      ...withoutTempo,
    ],
    guessed: guessed,
    withoutTempo: withoutTempo,
  );
}
