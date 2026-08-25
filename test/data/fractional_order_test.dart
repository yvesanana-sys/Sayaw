import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/fractional_order.dart';

void main() {
  group('positionBetween', () {
    test('an empty list starts at the first step', () {
      expect(positionBetween(null, null), kPositionStep);
    });

    test('prepending goes one step below the head', () {
      expect(positionBetween(null, 1.0), 0.0);
    });

    test('appending goes one step above the tail', () {
      expect(positionBetween(5.0, null), 6.0);
    });

    test('inserting takes the midpoint', () {
      expect(positionBetween(1.0, 2.0), 1.5);
      expect(positionBetween(1.5, 2.0), 1.75);
    });

    test('refuses to subdivide a gap that is already too small', () {
      expect(positionBetween(1.0, 1.0 + kMinPositionGap / 2), isNull);
    });
  });

  group('repeated insertion at the same point', () {
    test('survives ~50 halvings before asking to renormalize', () {
      var before = 1.0;
      const after = 2.0;
      var inserts = 0;

      while (true) {
        final next = positionBetween(before, after);
        if (next == null) break;

        // Every position must stay strictly between its neighbours, or the
        // set order becomes nondeterministic.
        expect(next, greaterThan(before));
        expect(next, lessThan(after));

        before = next;
        inserts++;
        if (inserts > 100) fail('never asked to renormalize');
      }

      // The architecture doc claims "roughly 50"; anything in this range means
      // the guard fires long before doubles actually lose ordering.
      expect(inserts, inInclusiveRange(15, 60));
    });
  });

  group('renormalize', () {
    test('emits evenly spaced ascending positions', () {
      expect(renormalize(4), [1.0, 2.0, 3.0, 4.0]);
      expect(renormalize(0), isEmpty);
    });

    test('output is always subdividable again', () {
      final fresh = renormalize(3);
      expect(positionBetween(fresh[0], fresh[1]), isNotNull);
    });
  });

  group('reorderPosition', () {
    // newIndex is post-removal, matching ReorderableListView.onReorderItem.
    final positions = [1.0, 2.0, 3.0, 4.0];

    test('moving down lands between the new neighbours', () {
      // Move row 0 to sit at index 2 of the remaining [2,3,4] -> between 3 and 4.
      expect(reorderPosition(positions, 0, 2), 3.5);
    });

    test('moving up lands between the new neighbours', () {
      // Move row 3 to index 1 of the remaining [1,2,3] -> between 1 and 2.
      expect(reorderPosition(positions, 3, 1), 1.5);
    });

    test('moving to the head goes below the current head', () {
      expect(reorderPosition(positions, 2, 0), 0.0);
    });

    test('moving to the tail goes above the current tail', () {
      expect(reorderPosition(positions, 0, 3), 5.0);
    });

    test('a no-op move keeps the existing position', () {
      expect(reorderPosition(positions, 1, 1), 2.0);
    });

    test('asks to renormalize when the destination gap is exhausted', () {
      final tight = [1.0, 2.0, 2.0 + kMinPositionGap / 4, 3.0];
      expect(reorderPosition(tight, 3, 2), isNull);
    });

    test('rejects out-of-range indices rather than corrupting the order', () {
      expect(() => reorderPosition(positions, -1, 0), throwsRangeError);
      expect(() => reorderPosition(positions, 0, 4), throwsRangeError);
      expect(() => reorderPosition(positions, 9, 0), throwsRangeError);
    });

    test('one move rewrites exactly one position', () {
      final moved = reorderPosition(positions, 0, 2)!;
      final after = [...positions]..removeAt(0);
      after.insert(2, moved);

      // Every other row keeps the value it had. This is the whole point of
      // fractional ordering: a drag in a 400-song set is one row write.
      expect(after, [2.0, 3.0, 3.5, 4.0]);
      expect(after, orderedEquals(List.of(after)..sort()));
    });
  });
}
