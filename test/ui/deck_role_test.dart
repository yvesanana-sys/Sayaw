import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/deck_panel.dart';

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
  group('which deck is playing which part', () {
    test('roles resolve through the live deck, and swap with it', () {
      const onA = PlaybackUiState(liveSlot: DeckSlot.a);
      expect(onA.slotFor(DeckRole.onFloor), DeckSlot.a);
      expect(onA.slotFor(DeckRole.comingIn), DeckSlot.b);

      const onB = PlaybackUiState(liveSlot: DeckSlot.b);
      expect(onB.slotFor(DeckRole.onFloor), DeckSlot.b);
      expect(onB.slotFor(DeckRole.comingIn), DeckSlot.a);
    });

    test('the two roles are never the same deck', () {
      for (final live in DeckSlot.values) {
        final state = PlaybackUiState(liveSlot: live);
        expect(state.slotFor(DeckRole.onFloor),
            isNot(state.slotFor(DeckRole.comingIn)));
      }
    });
  });

  group('the panel on top', () {
    testWidgets('is the song the room has, whichever deck carries it',
        (tester) async {
      for (final live in DeckSlot.values) {
        final container = await pumpSayaw(
          tester,
          const Scaffold(body: DeckPanel(role: DeckRole.onFloor)),
          queue: _set,
        );
        final controller = container.read(playbackProvider.notifier);
        controller.loadToDeck(DeckSlot.a, _set[0]);
        controller.loadToDeck(DeckSlot.b, _set[1]);
        controller.state = controller.state.copyWith(liveSlot: live);
        await tester.pumpAndSettle();

        // The panel follows the role, so its content changes when the decks
        // alternate — which is the whole point: the operator reads position on
        // the screen instead of tracking a letter.
        expect(
          find.text(live == DeckSlot.a ? 'Vivir Mi Vida' : 'Obsesión'),
          findsOneWidget,
          reason: 'on-the-floor panel with deck ${live.name} live',
        );
      }
    });

    testWidgets('says its role, never a deck letter', (tester) async {
      final container = await pumpSayaw(
        tester,
        const Scaffold(
          body: Column(
            children: [
              DeckPanel(role: DeckRole.onFloor),
              DeckPanel(role: DeckRole.comingIn),
            ],
          ),
        ),
        queue: _set,
      );
      container.read(playbackProvider.notifier)
        ..loadToDeck(DeckSlot.a, _set[0])
        ..loadToDeck(DeckSlot.b, _set[1]);
      await tester.pumpAndSettle();

      expect(find.text('ON THE FLOOR'), findsOneWidget);
      expect(find.text('COMING IN'), findsOneWidget);

      for (final text in tester.widgetList<Text>(find.byType(Text))) {
        final data = text.data ?? '';
        expect(data, isNot(equals('A')));
        expect(data, isNot(equals('B')));
        expect(data, isNot(contains('Deck ')));
      }
    });

    testWidgets('an empty deck says which kind of empty it is', (tester) async {
      await pumpSayaw(
        tester,
        const Scaffold(
          body: Column(
            children: [
              DeckPanel(role: DeckRole.onFloor),
              DeckPanel(role: DeckRole.comingIn),
            ],
          ),
        ),
      );

      expect(find.text('Nothing playing yet'), findsOneWidget);
      expect(find.text('Nothing cued up yet'), findsOneWidget);
    });

    testWidgets('it reads aloud by role too', (tester) async {
      final handle = tester.ensureSemantics();
      final container = await pumpSayaw(
        tester,
        const Scaffold(body: DeckPanel(role: DeckRole.comingIn)),
        queue: _set,
      );
      container.read(playbackProvider.notifier)
        ..loadToDeck(DeckSlot.a, _set[0])
        ..loadToDeck(DeckSlot.b, _set[1]);
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp('COMING IN: Obsesión')),
          findsOneWidget);
      handle.dispose();
    });
  });
}
