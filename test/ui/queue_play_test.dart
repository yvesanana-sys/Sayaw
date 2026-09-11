import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/layout/breakpoints.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/queue_list.dart';
import 'package:sayaw/ui/widgets/transport_bar.dart';
import 'package:sayaw/ui/widgets/transport_button.dart';

import 'harness.dart';

Widget _queue() => Scaffold(
      body: SayawLayout(builder: (context, _) => const QueueList()),
    );

Finder _targetFor(String id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byType(QueuePlayTarget),
    );

void main() {
  group('tapping a row', () {
    testWidgets('plays it', (tester) async {
      final container = await pumpSayaw(tester, _queue(), queue: testQueue());

      await tester.tap(find.text('Obsesion'));
      await tester.pumpAndSettle();

      final state = container.read(playbackProvider);
      expect(state.currentIndex, 2);
      expect(state.deckA.title, 'Obsesion');
      expect(state.deckA.isPlaying, isTrue);
    });

    testWidgets('the row already playing is not a target', (tester) async {
      final container = await pumpSayaw(tester, _queue(), queue: testQueue());
      container.read(playbackProvider.notifier).playFrom(testQueue()[0]);
      await tester.pumpAndSettle();

      // Wrapped in the target widget, which declines to be one.
      final target = tester.widget<QueuePlayTarget>(_targetFor('q1'));
      expect(target.isCurrent, isTrue);
      expect(
        find.descendant(of: _targetFor('q1'), matching: find.byType(InkWell)),
        findsNothing,
      );
    });

    testWidgets('a row that will not play is not one either', (tester) async {
      await pumpSayaw(tester, _queue(), queue: testQueue());

      // q4 is DRM-locked on this platform.
      expect(
        find.descendant(of: _targetFor('q4'), matching: find.byType(InkWell)),
        findsNothing,
      );
    });

    testWidgets('it announces itself without a pointer', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSayaw(tester, _queue(), queue: testQueue());

      expect(find.bySemanticsLabel('Play Sway now'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('at every width the target is a fingertip tall',
        (tester) async {
      for (final size in [kCompactSize, kMediumSize, kExpandedSize]) {
        await pumpSayaw(tester, _queue(), size: size, queue: testQueue());

        expect(tester.getSize(_targetFor('q2')).height,
            greaterThanOrEqualTo(48.0));
      }
    });
  });

  group('the stop button', () {
    testWidgets('is inert with nothing playing', (tester) async {
      await pumpSayaw(tester, const TransportBar(), queue: testQueue());

      final stop = tester.widget<TransportButton>(
        find.widgetWithText(TransportButton, 'STOP'),
      );
      expect(stop.onPressed, isNull);
    });

    testWidgets('stops the music and puts the track back at its start',
        (tester) async {
      final container =
          await pumpSayaw(tester, const TransportBar(), queue: testQueue());
      final controller = container.read(playbackProvider.notifier);
      controller.loadToDeck(DeckSlot.a, testQueue()[0]);
      controller.togglePlay(DeckSlot.a);
      await tester.pumpAndSettle();
      expect(container.read(playbackProvider).deckA.isPlaying, isTrue);

      await tester.tap(find.widgetWithText(TransportButton, 'STOP'));
      await tester.pumpAndSettle();

      final state = container.read(playbackProvider);
      expect(state.anyDeckPlaying, isFalse);
      expect(state.deckA.position, Duration.zero);
      expect(state.deckA.title, 'Kiss of Fire', reason: 'still loaded');
    });
  });
}
