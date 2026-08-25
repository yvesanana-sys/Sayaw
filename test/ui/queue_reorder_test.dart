import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/layout/breakpoints.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/queue_list.dart';

import 'harness.dart';

/// Wraps [QueueList] in a [SayawLayout] so the drag handle picks its gesture
/// from the breakpoint, exactly as it does in the real screen. The breakpoint
/// itself follows from the window size the test sets.
Widget _queue() => SayawLayout(builder: (context, _) => const QueueList());

Finder _handleFor(String id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byType(QueueDragHandle),
    );

void main() {
  group('touch (compact)', () {
    testWidgets('a plain drag on the handle does not reorder', (tester) async {
      final container = await pumpSayaw(
        tester,
        _queue(),
        size: kCompactSize,
        queue: testQueue(),
      );

      final before = [
        for (final item in container.read(playbackProvider).queue) item.id,
      ];

      final gesture =
          await tester.startGesture(tester.getCenter(_handleFor('q1')));
      // No long press: a flick to scroll the set list must never be read as
      // picking a track up mid-event.
      await gesture.moveBy(const Offset(0, 160));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        [for (final item in container.read(playbackProvider).queue) item.id],
        before,
      );
    });

    testWidgets('a long press then drag reorders', (tester) async {
      final container = await pumpSayaw(
        tester,
        _queue(),
        size: kCompactSize,
        queue: testQueue(),
      );

      final rowHeight = tester.getSize(find.byKey(const ValueKey('q1'))).height;

      final gesture =
          await tester.startGesture(tester.getCenter(_handleFor('q1')));
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));

      await gesture.moveBy(Offset(0, rowHeight * 1.6));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      final after = [
        for (final item in container.read(playbackProvider).queue) item.id,
      ];
      expect(after.first, isNot('q1'), reason: 'q1 should have moved down');
      expect(after, containsAll(['q1', 'q2', 'q3', 'q4']));
      expect(after.length, 4);
    });
  });

  group('mouse (expanded)', () {
    testWidgets('a drag reorders immediately, with no long press',
        (tester) async {
      final container = await pumpSayaw(
        tester,
        _queue(),
        size: kExpandedSize,
        queue: testQueue(),
      );

      final rowHeight = tester.getSize(find.byKey(const ValueKey('q1'))).height;

      final gesture = await tester.startGesture(
        tester.getCenter(_handleFor('q1')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await gesture.moveBy(Offset(0, rowHeight * 1.6));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      final after = [
        for (final item in container.read(playbackProvider).queue) item.id,
      ];
      expect(
        after.first,
        isNot('q1'),
        reason: 'waiting half a second before a mouse drag begins feels broken',
      );
      expect(after.length, 4);
    });
  });

  group('positions after a reorder', () {
    test('only the moved row changes position', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playbackProvider.notifier);
      controller.setQueue(testQueue());

      final before = {
        for (final item in container.read(playbackProvider).queue)
          item.id: item.position,
      };

      // Post-removal convention: move the head down to index 2.
      controller.reorderQueue(0, 2);

      final after = container.read(playbackProvider).queue;
      expect([for (final i in after) i.id], ['q2', 'q3', 'q1', 'q4']);

      for (final item in after) {
        if (item.id == 'q1') {
          expect(item.position, isNot(before['q1']));
        } else {
          expect(
            item.position,
            before[item.id],
            reason: '${item.id} must keep its position — a drag writes one row',
          );
        }
      }

      // The list stays strictly ascending, which is what makes position the
      // authoritative sort key.
      final positions = [for (final i in after) i.position];
      expect(positions, orderedEquals(List.of(positions)..sort()));
    });

    test('renormalizes and still moves when the gap is exhausted', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playbackProvider.notifier);
      controller.setQueue(const [
        QueueItemUi(id: 'a', title: 'A', artist: '', position: 1.0),
        QueueItemUi(id: 'b', title: 'B', artist: '', position: 2.0),
        QueueItemUi(id: 'c', title: 'C', artist: '', position: 2.0000001),
        QueueItemUi(id: 'd', title: 'D', artist: '', position: 3.0),
      ]);

      controller.reorderQueue(3, 2);

      final after = container.read(playbackProvider).queue;
      expect([for (final i in after) i.id], ['a', 'b', 'd', 'c']);

      final positions = [for (final i in after) i.position];
      expect(
        positions,
        orderedEquals(List.of(positions)..sort()),
        reason: 'a tight gap must renormalize, never emit a colliding position',
      );
      expect(positions.toSet().length, positions.length);
    });

    test('out-of-range indices are ignored rather than throwing at the UI', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(playbackProvider.notifier);
      controller.setQueue(testQueue());

      controller.reorderQueue(9, 0);
      controller.reorderQueue(0, 9);

      expect(
        [for (final i in container.read(playbackProvider).queue) i.id],
        ['q1', 'q2', 'q3', 'q4'],
      );
    });
  });
}
