/// Fractional position ordering for playlist rows.
///
/// `playlist_items.position` is a `REAL`. Moving one track in a 400-song event
/// playlist rewrites **one row**, not 400 — which matters because that write
/// happens while audio is playing off the same SQLite file.
library;

/// Smallest gap between adjacent positions before precision becomes a real
/// risk. Doubles have ~15 significant digits; halving a gap repeatedly from
/// 1.0 reaches this after roughly 50 insertions at the same point.
const double kMinPositionGap = 1e-6;

/// Positions assigned by [renormalize], and the spacing between fresh appends.
const double kPositionStep = 1.0;

/// The position a row should take when moved to sit between [before] and
/// [after], either of which may be null at the ends of the list.
///
/// Returns null when the neighbours are too close to subdivide safely — the
/// caller must [renormalize] the playlist and retry. Returning null rather than
/// silently emitting a colliding position keeps the failure visible: two rows
/// with equal positions produce a nondeterministic set order, which on stage
/// looks like the app randomly reordering the night.
double? positionBetween(double? before, double? after) {
  if (before == null && after == null) return kPositionStep;
  if (before == null) return after! - kPositionStep;
  if (after == null) return before + kPositionStep;

  if (after - before < kMinPositionGap) return null;
  return before + (after - before) / 2;
}

/// Evenly spaced positions `1.0, 2.0, 3.0…` for a list of [count] rows.
///
/// Cheap, and only ever needed after ~50 consecutive insertions at the same
/// point. Write these in a single transaction.
List<double> renormalize(int count) =>
    List<double>.generate(count, (i) => (i + 1) * kPositionStep);

/// The new position for the row at [oldIndex] after the operator drags it to
/// [newIndex], given the current ordered [positions].
///
/// [newIndex] follows the convention of `ReorderableListView.onReorderItem`:
/// the index the row occupies *after* it has been lifted out, so it is already
/// adjusted for the removal and is always in `[0, positions.length - 1]`.
///
/// Returns null when the gap at the destination is too small to subdivide;
/// the caller renormalizes and retries.
double? reorderPosition(
  List<double> positions,
  int oldIndex,
  int newIndex,
) {
  if (oldIndex < 0 || oldIndex >= positions.length) {
    throw RangeError.index(oldIndex, positions, 'oldIndex');
  }
  if (newIndex < 0 || newIndex >= positions.length) {
    throw RangeError.index(newIndex, positions, 'newIndex');
  }

  if (newIndex == oldIndex) return positions[oldIndex];

  final remaining = [...positions]..removeAt(oldIndex);
  final before = newIndex > 0 ? remaining[newIndex - 1] : null;
  final after = newIndex < remaining.length ? remaining[newIndex] : null;

  return positionBetween(before, after);
}
