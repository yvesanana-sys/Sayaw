import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/announcer_strip.dart';

import 'harness.dart';

Future<ProviderContainer> pumpStrip(
  WidgetTester tester,
  NextAnnouncementUi? announcement,
) async {
  final container = await pumpSayaw(
    tester,
    const Scaffold(body: AnnouncerStrip()),
    overrides: [
      if (announcement != null)
        nextAnnouncementProvider.overrideWithValue(announcement),
    ],
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('nothing to say leaves it blank', (tester) async {
    await pumpStrip(tester, null);

    // Blank, but not gone: the decks must not move under a hand reaching for
    // them because the next row happens to be untagged.
    expect(find.byType(AnnouncerStrip), findsOneWidget);
    expect(tester.getSize(find.byType(AnnouncerStrip)).height,
        AnnouncerStrip.height);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('a tagged recording is named, with when it lands',
      (tester) async {
    await pumpStrip(
      tester,
      const NextAnnouncementUi(
        label: 'Take your partners',
        isRecording: true,
        timing: AnnouncementTiming.overTheCrossfade,
      ),
    );

    expect(find.text('Take your partners'), findsOneWidget);
    expect(find.text('over the crossfade'), findsOneWidget);
    expect(find.byIcon(Icons.campaign), findsOneWidget);
  });

  testWidgets('a spoken announcement is drawn as a voice, not a recording',
      (tester) async {
    await pumpStrip(
      tester,
      const NextAnnouncementUi(
        label: 'Next dance: Waltz',
        isRecording: false,
        timing: AnnouncementTiming.beforeTheMusic,
      ),
    );

    expect(find.text('Next dance: Waltz'), findsOneWidget);
    expect(find.text('before the music'), findsOneWidget);
    // Only one of the two is in the operator's own voice, which is worth
    // telling apart at a glance.
    expect(find.byIcon(Icons.record_voice_over), findsOneWidget);
    expect(find.byIcon(Icons.campaign), findsNothing);
  });

  testWidgets('a rotation says the gap is where it lands', (tester) async {
    await pumpStrip(
      tester,
      const NextAnnouncementUi(
        label: 'Rotate',
        isRecording: true,
        timing: AnnouncementTiming.inTheRotationGap,
      ),
    );

    expect(find.text('in the rotation gap'), findsOneWidget);
  });

  testWidgets('it announces itself without a pointer', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpStrip(
      tester,
      const NextAnnouncementUi(
        label: 'Take your partners',
        isRecording: true,
        timing: AnnouncementTiming.overTheCrossfade,
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Next transition announces Take your partners, over the crossfade',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });
}
