import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/screens/deck_screen.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/library_pane.dart';
import 'package:sayaw/ui/widgets/queue_list.dart';

import 'harness.dart';

/// The window is resizable and DJs resize it. Docking a Surface into a keyboard,
/// dragging the window onto a projector, or snapping it to half the screen all
/// cross a breakpoint — mid-set, with audio playing.
///
/// Losing playback state or scroll position on that transition is not a cosmetic
/// bug; it is the operator losing their place in a 300-song event list while a
/// track is running out.
void main() {
  testWidgets('each breakpoint renders its documented panes', (tester) async {
    await pumpSayaw(
      tester,
      const DeckScreen(),
      size: kCompactSize,
      queue: testQueue(),
    );

    // Compact: single pane, bottom navigation, no rail.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byType(LibraryPane), findsNothing);

    await setWindowSize(tester, kMediumSize);
    await tester.pumpAndSettle();

    // Medium: rail, decks plus one secondary pane.
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(QueueList), findsOneWidget);

    await setWindowSize(tester, kExpandedSize);
    await tester.pumpAndSettle();

    // Expanded: library, decks and queue all at once.
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(LibraryPane), findsOneWidget);
    expect(find.byType(QueueList), findsOneWidget);
  });

  testWidgets('playback state survives a live resize across all three modes',
      (tester) async {
    final container = await pumpSayaw(
      tester,
      const DeckScreen(),
      size: kCompactSize,
      queue: testQueue(),
    );

    final controller = container.read(playbackProvider.notifier);
    controller.loadToDeck(DeckSlot.a, testQueue().first);
    controller.togglePlay(DeckSlot.a);
    controller.setCrossfader(0.35);
    await tester.pumpAndSettle();

    expect(container.read(playbackProvider).deckA.isPlaying, isTrue);

    for (final size in [kMediumSize, kExpandedSize, kCompactSize]) {
      await setWindowSize(tester, size);
      await tester.pumpAndSettle();

      final state = container.read(playbackProvider);
      expect(
        state.deckA.isPlaying,
        isTrue,
        reason: 'deck A stopped playing after resizing to $size',
      );
      expect(state.deckA.title, 'Kiss of Fire');
      expect(state.crossfader, closeTo(0.35, 1e-9));
      expect(state.queue.length, 4);
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets('queue scroll position survives a live resize', (tester) async {
    // A long list, so there is somewhere to scroll to.
    final longQueue = [
      for (var i = 0; i < 60; i++)
        QueueItemUi(
          id: 'row-$i',
          title: 'Track $i',
          artist: 'Artist $i',
          position: (i + 1).toDouble(),
        ),
    ];

    await pumpSayaw(
      tester,
      const DeckScreen(),
      size: kExpandedSize,
      queue: longQueue,
    );

    final list = find.descendant(
      of: find.byType(QueueList),
      matching: find.byType(Scrollable),
    );

    await tester.drag(list, const Offset(0, -600));
    await tester.pumpAndSettle();

    final scrolled = tester.widget<Scrollable>(list).controller!.offset;
    expect(scrolled, greaterThan(0));

    await setWindowSize(tester, kMediumSize);
    await tester.pumpAndSettle();

    final after = tester
        .widget<Scrollable>(
          find.descendant(
            of: find.byType(QueueList),
            matching: find.byType(Scrollable),
          ),
        )
        .controller!
        .offset;

    expect(
      after,
      closeTo(scrolled, 1.0),
      reason: 'the scroll controller is owned above the breakpoint switch so '
          'the offset must carry across the transition',
    );
  });

  testWidgets('the selected pane survives a live resize', (tester) async {
    await pumpSayaw(
      tester,
      const DeckScreen(),
      size: kCompactSize,
      queue: testQueue(),
    );

    // Switch to the library in compact, via bottom navigation.
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPane), findsOneWidget);

    await setWindowSize(tester, kMediumSize);
    await tester.pumpAndSettle();

    // The rail should still have Library selected, so the secondary pane is
    // the library rather than snapping back to the queue.
    expect(find.byType(LibraryPane), findsOneWidget);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      SayawPane.library.index,
    );
  });

  testWidgets('resizing below the minimum window size does not overflow',
      (tester) async {
    await pumpSayaw(
      tester,
      const DeckScreen(),
      size: const Size(360, 640),
      queue: testQueue(),
    );

    // Narrower than the 640x480 floor window_manager enforces. The floor is a
    // Win32 constraint, not something the layout can rely on: a display-scale
    // change can hand us fewer logical pixels than that at any moment.
    await setWindowSize(tester, const Size(320, 480));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
