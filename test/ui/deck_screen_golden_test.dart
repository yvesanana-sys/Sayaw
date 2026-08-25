@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/screens/deck_screen.dart';

import '../fakes/fake_library.dart';
import 'harness.dart';

/// Goldens for the three breakpoints.
///
/// Text renders as boxes: `flutter test` ships no real fonts, so glyph shapes
/// are not what is being pinned here. What is pinned is *layout* — pane counts,
/// which navigation surface appears, where the crossfader and transport bar
/// sit, and the relative size of every control. That is exactly the thing a
/// careless layout change breaks, and it is stable across machines.
///
/// Regenerate deliberately, never reflexively:
///
///     flutter test --update-goldens test/ui/deck_screen_golden_test.dart
///
/// A diff here means the layout moved. Look at the failure image under
/// `test/ui/failures/` before accepting it.
void main() {
  /// Deterministic state, so a golden never depends on what happened to be
  /// loaded. Deck A is playing, deck B is cued, the fader is off-centre.
  Future<void> pumpDeckScreen(WidgetTester tester, Size size) async {
    final container = await pumpSayaw(
      tester,
      const DeckScreen(),
      size: size,
      queue: testQueue(),
      // The library pane draws rows in the expanded golden, so the layout
      // being pinned is the one an operator sees rather than an empty state.
      overrides: [libraryAccessProvider.overrideWithValue(FakeLibrary())],
    );

    final controller = container.read(playbackProvider.notifier);
    final items = testQueue();
    controller.loadToDeck(DeckSlot.a, items[0]);
    controller.loadToDeck(DeckSlot.b, items[1]);
    controller.togglePlay(DeckSlot.a);
    controller.setCrossfader(0.35);

    await tester.pumpAndSettle();
  }

  testWidgets('compact — single pane, bottom navigation', (tester) async {
    await pumpDeckScreen(tester, kCompactSize);
    await expectLater(
      find.byType(DeckScreen),
      matchesGoldenFile('goldens/deck_screen_compact.png'),
    );
  });

  testWidgets('medium — navigation rail, two panes', (tester) async {
    await pumpDeckScreen(tester, kMediumSize);
    await expectLater(
      find.byType(DeckScreen),
      matchesGoldenFile('goldens/deck_screen_medium.png'),
    );
  });

  testWidgets('expanded — library, decks and queue side by side',
      (tester) async {
    await pumpDeckScreen(tester, kExpandedSize);
    await expectLater(
      find.byType(DeckScreen),
      matchesGoldenFile('goldens/deck_screen_expanded.png'),
    );
  });
}
