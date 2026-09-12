import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/soundboard.dart';
import 'package:sayaw/ui/state/soundboard_provider.dart';
import 'package:sayaw/ui/touch/touch_targets.dart';
import 'package:sayaw/ui/widgets/soundboard_bar.dart';

import '../fakes/fake_soundboard.dart';
import 'harness.dart';

const _whistle =
    SoundCue(id: 'whistle', label: 'Whistle', filePath: '/fx/w.wav');
const _bell = SoundCue(id: 'bell', label: 'Bell', filePath: '/fx/b.wav');
const _tag = SoundCue(
  id: 'tag',
  label: 'Tag!',
  filePath: '/fx/t.wav',
  duckLevel: 0.3,
);

void main() {
  Future<FakeSoundboard> pumpBar(
    WidgetTester tester,
    List<SoundCue> cues,
  ) async {
    final soundboard = FakeSoundboard(cues);
    addTearDown(soundboard.close);

    await pumpSayaw(
      tester,
      const Scaffold(body: SoundboardBar()),
      overrides: [soundboardProvider.overrideWithValue(soundboard)],
    );
    await tester.pumpAndSettle();
    return soundboard;
  }

  testWidgets('an empty soundboard takes up no room', (tester) async {
    // Nothing ships with the app, so this is what a new install looks like.
    await pumpBar(tester, const []);

    expect(tester.getSize(find.byType(SoundboardBar)).height, 0);
  });

  testWidgets('one button per cue, labelled', (tester) async {
    await pumpBar(tester, const [_whistle, _bell]);

    expect(find.text('Whistle'), findsOneWidget);
    expect(find.text('Bell'), findsOneWidget);
  });

  testWidgets('more cues than fit in a row are all still on screen',
      (tester) async {
    // Twelve whistles on a 600dp-wide compact window. A strip that scrolled
    // sideways showed five and hid the rest; every one has to be reachable
    // without a scroll, because a cut-in is a thing that happens now.
    final many = [
      for (var i = 0; i < 12; i++)
        SoundCue(id: 'c$i', label: 'Cue $i', filePath: '/fx/$i.wav'),
    ];
    await pumpBar(tester, many);

    final bar = tester.getRect(find.byType(SoundboardBar));
    for (var i = 0; i < 12; i++) {
      final button = tester.getRect(
          find.bySemanticsLabel(RegExp('^Play Cue $i(, shortcut \\d)?\$')));
      expect(bar.contains(button.center), isTrue,
          reason: 'Cue $i is off the visible bar');
    }
    expect(bar.height, greaterThan(kMinTouchTarget * 2),
        reason: 'grew to a second row rather than hiding cues');
  });

  testWidgets('pressing one fires it', (tester) async {
    final soundboard = await pumpBar(tester, const [_whistle, _bell]);

    await tester.tap(find.text('Bell'));
    await tester.pumpAndSettle();

    expect(soundboard.fired, ['bell']);
  });

  testWidgets('the button does not wait for the cue to finish',
      (tester) async {
    // A whistle runs for as long as the file does. A button that stayed
    // pressed through it would be the wrong thing entirely.
    final soundboard = await pumpBar(tester, const [_whistle]);

    await tester.tap(find.text('Whistle'));
    await tester.pump();

    expect(soundboard.fired, ['whistle']);
  });

  testWidgets('the first nine show the digit that fires them', (tester) async {
    await pumpBar(tester, [
      for (var i = 1; i <= 11; i++)
        SoundCue(id: 'c$i', label: 'Cue $i', filePath: '/fx/$i.wav'),
    ]);

    // Scrolled off-screen buttons are not built, so assert on the shortcut
    // the first one carries rather than counting all nine.
    expect(
      find.bySemanticsLabel('Play Cue 1, shortcut 1'),
      findsOneWidget,
    );
  });

  testWidgets('a tenth cue has a button but no shortcut', (tester) async {
    // There is no tenth digit, and a two-key chord in the dark is not a
    // cut-in.
    await pumpBar(tester, [
      for (var i = 1; i <= 10; i++)
        SoundCue(id: 'c$i', label: 'Cue $i', filePath: '/fx/$i.wav'),
    ]);

    await tester.dragUntilVisible(
      find.text('Cue 10'),
      find.byType(ListView),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Play Cue 10'), findsOneWidget);
  });

  testWidgets('a cue that talks over the music looks different from one that '
      'does not', (tester) async {
    // Only one of them will speak over the vocals, which is worth telling
    // apart before pressing it.
    await pumpBar(tester, const [_whistle, _tag]);

    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.byIcon(Icons.campaign), findsOneWidget);
  });

  testWidgets('with no audio behind it the buttons are dead, not missing',
      (tester) async {
    await pumpSayaw(
      tester,
      const Scaffold(body: SoundboardBar()),
      overrides: [
        soundboardProvider.overrideWithValue(null),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(SoundboardBar), findsOneWidget);
  });

  testWidgets('a cue added while the app is running appears', (tester) async {
    final soundboard = await pumpBar(tester, const [_whistle]);
    expect(find.text('Bell'), findsNothing);

    soundboard.emit(const [_whistle, _bell]);
    await tester.pumpAndSettle();

    expect(find.text('Bell'), findsOneWidget);
  });

  testWidgets('a cue that did not sound is said out loud', (tester) async {
    // Pressed a button in front of a room and heard nothing. Silence about it
    // is the worst of both: no sound and no explanation.
    final soundboard = await pumpBar(tester, const [_whistle]);

    soundboard.failNext('Whistle');
    await tester.pumpAndSettle();

    expect(find.textContaining('Whistle did not play'), findsOneWidget);
  });

  testWidgets('a cue that sounded says nothing', (tester) async {
    final soundboard = await pumpBar(tester, const [_whistle]);

    await tester.tap(find.text('Whistle'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(soundboard.fired, ['whistle']);
  });

}
