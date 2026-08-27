import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/set_ordering.dart';
import 'package:sayaw/ui/screens/deck_screen.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/snowball_indicator.dart';

import 'harness.dart';

void main() {
  Future<void> pumpWith(WidgetTester tester, SnowballProgress? progress) async {
    final container = await pumpSayaw(
      tester,
      const Scaffold(body: SnowballIndicator()),
    );
    container
        .read(playbackProvider.notifier)
        .applyEngineState(
          activeSlot: DeckSlot.a,
          phase: container.read(playbackProvider).phase,
          currentIndex: 0,
          active: const DeckUiState(title: 'Track'),
          standby: const DeckUiState(),
          snowball: progress,
        );
    await tester.pumpAndSettle();
  }

  testWidgets('nothing at all on a set that is not a Snowball',
      (tester) async {
    await pumpWith(tester, null);

    expect(tester.getSize(find.byType(SnowballIndicator)).height, 0);
  });

  testWidgets('the stage reads without arithmetic', (tester) async {
    await pumpWith(
      tester,
      const SnowballProgress(stage: 2, stages: 5, songsIn: 7, total: 20),
    );

    expect(find.text('Stage 2 of 5'), findsOneWidget);
    expect(find.text('7 of 20'), findsOneWidget);
  });

  testWidgets('the tempo is shown beside it, and is the honest half',
      (tester) async {
    // The stage number only claims a position in the set. A set that was
    // never ordered shows a stage climbing and a tempo that is not, and that
    // is the thing worth being able to see.
    await pumpWith(
      tester,
      const SnowballProgress(
        stage: 3,
        stages: 5,
        songsIn: 11,
        total: 20,
        bpm: 128.4,
      ),
    );

    expect(find.text('128 BPM'), findsOneWidget);
  });

  testWidgets('a track with no tempo simply has none shown', (tester) async {
    await pumpWith(
      tester,
      const SnowballProgress(stage: 1, stages: 5, songsIn: 1, total: 20),
    );

    expect(find.textContaining('BPM'), findsNothing);
    expect(find.text('Stage 1 of 5'), findsOneWidget);
  });

  testWidgets('one block per stage, filled up to where it has got to',
      (tester) async {
    await pumpWith(
      tester,
      const SnowballProgress(stage: 2, stages: 4, songsIn: 5, total: 20),
    );

    // Four blocks, and the widths are equal — a caller reads "two of four
    // lit", which a smooth bar does not give them.
    final blocks = tester.widgetList<DecoratedBox>(find.descendant(
      of: find.byType(SnowballIndicator),
      matching: find.byType(DecoratedBox),
    ));
    expect(blocks, hasLength(4));
  });

  testWidgets('a screen reader is told the whole thing', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWith(
      tester,
      const SnowballProgress(
        stage: 4,
        stages: 5,
        songsIn: 16,
        total: 20,
        bpm: 140,
      ),
    );

    expect(
      tester.getSemantics(find.byType(SnowballIndicator)),
      matchesSemantics(
        label: 'Snowball stage 4 of 5. Song 16 of 20, 140 beats per minute.',
        isLiveRegion: true,
      ),
    );
    handle.dispose();
  });

  group('on the deck screen', () {
    for (final (name, size) in const [
      ('compact', kCompactSize),
      ('medium', kMediumSize),
      ('expanded', kExpandedSize),
    ]) {
      testWidgets('$name: above the panes, so Performance Mode keeps it',
          (tester) async {
        final container = await pumpSayaw(
          tester,
          const DeckScreen(),
          size: size,
          queue: testQueue(),
        );

        expect(find.textContaining('Stage'), findsNothing);

        container.read(playbackProvider.notifier)
          ..setPerformanceMode(true)
          ..applyEngineState(
            activeSlot: DeckSlot.a,
            phase: container.read(playbackProvider).phase,
            currentIndex: 0,
            active: const DeckUiState(title: 'Track'),
            standby: const DeckUiState(),
            snowball: const SnowballProgress(
              stage: 3,
              stages: 5,
              songsIn: 9,
              total: 15,
            ),
          );
        await tester.pumpAndSettle();

        expect(find.text('Stage 3 of 5'), findsOneWidget);
      });
    }
  });
}
