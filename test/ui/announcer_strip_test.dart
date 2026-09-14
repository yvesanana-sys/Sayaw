import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/announcer_strip.dart';

import 'harness.dart';

Future<ProviderContainer> pumpStrip(
  WidgetTester tester, {
  NextAnnouncementUi? announcement,
  bool merges = false,
  int? seconds,
  String? incomingDance,
}) async {
  final container = await pumpSayaw(
    tester,
    const Scaffold(body: AnnouncerStrip()),
    overrides: [
      nextAnnouncementProvider.overrideWithValue(announcement),
      nextMergesProvider.overrideWithValue(merges),
      secondsUntilTransitionProvider.overrideWithValue(seconds),
      incomingDanceProvider.overrideWithValue(incomingDance),
    ],
  );
  await tester.pumpAndSettle();
  return container;
}

/// The sentence as it is actually painted, spans and all.
String renderedSentence(WidgetTester tester) {
  final rich = tester.widget<RichText>(find.byType(RichText).last);
  return rich.text.toPlainText();
}

void main() {
  testWidgets('it leads with what happens and when', (tester) async {
    await pumpStrip(
      tester,
      announcement: const NextAnnouncementUi(
        label: 'Next dance: Bachata',
        isRecording: false,
        timing: AnnouncementTiming.overTheCrossfade,
      ),
      incomingDance: 'Bachata',
      seconds: 40,
    );

    expect(
      renderedSentence(tester),
      'In 40 seconds, the music blends into Bachata '
      'and the room hears “Next dance: Bachata”.',
    );
  });

  testWidgets('nothing queued says so, and keeps its place', (tester) async {
    await pumpStrip(tester);

    // Blank would be wrong twice over: the decks must not move under a hand
    // reaching for them, and silence about the end of the set looks exactly
    // like a card that has not loaded.
    expect(find.byType(AnnouncerStrip), findsOneWidget);
    expect(tester.getSize(find.byType(AnnouncerStrip)).height,
        AnnouncerStrip.height);
    expect(renderedSentence(tester), 'Nothing after this song.');
  });

  testWidgets('its height does not move with what it says', (tester) async {
    await pumpStrip(tester);
    final empty = tester.getSize(find.byType(AnnouncerStrip)).height;

    await pumpStrip(
      tester,
      announcement: const NextAnnouncementUi(
        label: 'Next dance: Bachata, and please find a partner for this one',
        isRecording: false,
        timing: AnnouncementTiming.beforeTheMusic,
      ),
      incomingDance: 'Bachata',
      seconds: 40,
    );

    expect(tester.getSize(find.byType(AnnouncerStrip)).height, empty);
  });

  testWidgets('a recording is drawn as theirs, a voice as synthesised',
      (tester) async {
    await pumpStrip(
      tester,
      announcement: const NextAnnouncementUi(
        label: 'Take your partners',
        isRecording: true,
        timing: AnnouncementTiming.overTheCrossfade,
      ),
      incomingDance: 'Waltz',
      seconds: 10,
    );
    expect(find.byIcon(Icons.campaign), findsOneWidget);
    expect(renderedSentence(tester), contains('your recording'));

    await pumpStrip(
      tester,
      announcement: const NextAnnouncementUi(
        label: 'Next dance: Waltz',
        isRecording: false,
        timing: AnnouncementTiming.overTheCrossfade,
      ),
      incomingDance: 'Waltz',
      seconds: 10,
    );
    expect(find.byIcon(Icons.record_voice_over), findsOneWidget);
    expect(renderedSentence(tester), isNot(contains('your recording')));
  });

  testWidgets('a merge reads as one dance, not as a tag that failed',
      (tester) async {
    await pumpStrip(tester, merges: true, incomingDance: 'Salsa', seconds: 15);

    expect(renderedSentence(tester),
        'In 15 seconds, the music runs on into Salsa, still the same dance.');
  });

  testWidgets('it announces itself without a pointer', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpStrip(
      tester,
      announcement: const NextAnnouncementUi(
        label: 'Next dance: Bachata',
        isRecording: false,
        timing: AnnouncementTiming.overTheCrossfade,
      ),
      incomingDance: 'Bachata',
      seconds: 40,
    );

    expect(
      find.bySemanticsLabel(RegExp(r'What happens next\. In 40 seconds')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
