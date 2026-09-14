import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/crossfader.dart';

import 'harness.dart';

QueueItemUi _row(String id, String title, String dance, double position) =>
    QueueItemUi(
      id: id,
      title: title,
      artist: 'Someone',
      danceType: dance,
      position: position,
    );

final _set = [
  _row('1', 'Vivir Mi Vida', 'Salsa', 1),
  _row('2', 'Obsesión', 'Bachata', 2),
];

void main() {
  group('which way is forward', () {
    test('with deck A live, the lane reads straight off the fader', () {
      const state = PlaybackUiState(crossfader: 0.3, liveSlot: DeckSlot.a);
      expect(state.lanePosition, 0.3);
      expect(state.crossfaderForLane(0.75), 0.75);
    });

    test('with deck B live, the lane is the mirror of it', () {
      // B lives at the fader's far end, so "still on the floor" is the end the
      // fader calls 1.0. Without this flip the same drag would bring the next
      // song in on one transition and push it away on the next.
      const state = PlaybackUiState(crossfader: 0.3, liveSlot: DeckSlot.b);
      expect(state.lanePosition, closeTo(0.7, 1e-9));
      expect(state.crossfaderForLane(0.75), closeTo(0.25, 1e-9));
    });

    test('the translation round-trips from either deck', () {
      for (final slot in DeckSlot.values) {
        for (final p in [0.0, 0.25, 0.5, 0.9, 1.0]) {
          final state = PlaybackUiState(
            crossfader: PlaybackUiState(liveSlot: slot).crossfaderForLane(p),
            liveSlot: slot,
          );
          expect(state.lanePosition, closeTo(p, 1e-9),
              reason: 'lane $p on deck ${slot.name}');
        }
      }
    });
  });

  group('moving the lane', () {
    testWidgets('toward the right brings in the cued song, whichever deck '
        'it is on', (tester) async {
      for (final live in DeckSlot.values) {
        final container = await pumpSayaw(
          tester,
          const Scaffold(body: Crossfader()),
          queue: _set,
        );
        final controller = container.read(playbackProvider.notifier);
        controller.state = controller.state.copyWith(liveSlot: live);

        // All the way across, in the operator's terms.
        controller.setLanePosition(1.0);

        // The deck that was NOT live is now the one the fader favours — the
        // assertion that would fail if the flip were dropped.
        final fader = container.read(playbackProvider).crossfader;
        expect(
          live == DeckSlot.a ? fader : 1 - fader,
          1.0,
          reason: 'lane fully across should hand over from ${live.name}',
        );
        expect(container.read(playbackProvider).lanePosition, 1.0);
      }
    });

    testWidgets('a nudge increases toward the incoming song', (tester) async {
      final container = await pumpSayaw(
        tester,
        const Scaffold(body: Crossfader()),
        queue: _set,
      );
      final controller = container.read(playbackProvider.notifier);
      controller.state = controller.state.copyWith(liveSlot: DeckSlot.b);
      controller.setLanePosition(0.4);

      final before = container.read(playbackProvider).lanePosition;
      controller.setLanePosition(before + 0.1);
      expect(container.read(playbackProvider).lanePosition,
          greaterThan(before));
    });

    test('it never leaves the band', () {
      const state = PlaybackUiState(liveSlot: DeckSlot.a);
      expect(state.crossfaderForLane(0.0), 0.0);
      expect(state.crossfaderForLane(1.0), 1.0);
    });
  });

  group('what the ends are called', () {
    testWidgets('the dance, not the deck letter', (tester) async {
      final container = await pumpSayaw(
        tester,
        const Scaffold(body: Crossfader()),
        queue: _set,
      );
      final controller = container.read(playbackProvider.notifier);
      controller.loadToDeck(DeckSlot.a, _set[0]);
      controller.loadToDeck(DeckSlot.b, _set[1]);
      await tester.pumpAndSettle();

      expect(find.text('SALSA OUT'), findsOneWidget);
      expect(find.text('BACHATA IN'), findsOneWidget);
    });

    testWidgets('the letters A and B never appear', (tester) async {
      // The rule the redesign is built on: a dance teacher at a laptop should
      // never have to learn which deck is which.
      final container = await pumpSayaw(
        tester,
        const Scaffold(body: Crossfader()),
        queue: _set,
      );
      final controller = container.read(playbackProvider.notifier);
      controller.loadToDeck(DeckSlot.a, _set[0]);
      controller.loadToDeck(DeckSlot.b, _set[1]);
      await tester.pumpAndSettle();

      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final data = text.data ?? '';
        expect(data, isNot(equals('A')));
        expect(data, isNot(equals('B')));
        expect(data, isNot(contains('Deck ')));
      }
    });

    testWidgets('an empty deck says its role rather than nothing',
        (tester) async {
      await pumpSayaw(tester, const Scaffold(body: Crossfader()));

      // Never a doubled word, and never a deck letter standing in for a song.
      expect(find.text('NOTHING PLAYING'), findsOneWidget);
      expect(find.text('NOTHING CUED'), findsOneWidget);
    });
  });

  group('read aloud', () {
    testWidgets('it is described in songs, not in percentages of a deck',
        (tester) async {
      final handle = tester.ensureSemantics();
      final container = await pumpSayaw(
        tester,
        const Scaffold(body: Crossfader()),
        queue: _set,
      );
      final controller = container.read(playbackProvider.notifier);
      controller.loadToDeck(DeckSlot.a, _set[0]);
      controller.loadToDeck(DeckSlot.b, _set[1]);
      controller.setLanePosition(0.0);
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Handover from SALSA to BACHATA')),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
