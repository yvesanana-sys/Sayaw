import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/soundboard.dart';
import 'package:sayaw/ui/screens/soundboard_sheet.dart';
import 'package:sayaw/ui/state/soundboard_provider.dart';

import '../fakes/fake_soundboard.dart';
import 'harness.dart';

const _whistle =
    SoundCue(id: 'whistle', label: 'Whistle', filePath: '/fx/w.wav');
const _tag = SoundCue(
  id: 'tag',
  label: 'Tag!',
  filePath: '/fx/t.wav',
  duckLevel: 0.3,
);

void main() {
  Future<FakeSoundboard> pumpSheet(
    WidgetTester tester, {
    List<SoundCue> cues = const [],
  }) async {
    final access = FakeSoundboard(cues);
    addTearDown(access.close);

    await pumpSayaw(
      tester,
      Scaffold(body: SoundboardSheet(access: access)),
      overrides: [soundboardProvider.overrideWithValue(access)],
    );
    await tester.pumpAndSettle();
    return access;
  }

  group('a new install', () {
    testWidgets('has no sounds, and says so', (tester) async {
      // Nothing ships with the app — a whistle is the operator's own file.
      await pumpSheet(tester);

      expect(find.text('No sounds yet.'), findsOneWidget);
    });

    testWidgets('will not add a cue with no file behind it', (tester) async {
      final access = await pumpSheet(tester);

      await tester.enterText(find.byType(TextField), 'Whistle');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(access.addedCues, isEmpty);
      expect(find.text('Pick a sound first.'), findsOneWidget);
    });
  });

  group('the list of cues', () {
    testWidgets('each one shows what it will do to the music', (tester) async {
      // The distinction that decides whether a cue is usable over vocals.
      await pumpSheet(tester, cues: const [_whistle, _tag]);

      expect(find.text('Plays over the music'), findsOneWidget);
      expect(find.text('Dips the music'), findsOneWidget);
    });

    testWidgets('and the digit that fires it', (tester) async {
      await pumpSheet(tester, cues: const [_whistle, _tag]);

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('one can be tried without leaving the sheet', (tester) async {
      // Checking a file is the right one should not mean closing this and
      // finding the bar.
      final access = await pumpSheet(tester, cues: const [_whistle]);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(access.fired, ['whistle']);
    });

    testWidgets('and one can be removed', (tester) async {
      final access = await pumpSheet(tester, cues: const [_whistle]);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(access.removedCues, ['whistle']);
    });

    testWidgets('the count says how many are on the bar', (tester) async {
      await pumpSheet(tester, cues: const [_whistle, _tag]);

      expect(find.text('2 on the bar'), findsOneWidget);
    });

    testWidgets('every row says whose it is, since the buttons are icons',
        (tester) async {
      await pumpSheet(tester, cues: const [_whistle]);

      final labels = [
        for (final s in tester.widgetList<Semantics>(find.byType(Semantics)))
          s.properties.label,
      ];

      expect(labels, containsAll(['Try Whistle', 'Remove Whistle']));
    });

    testWidgets('a cue added elsewhere appears here too', (tester) async {
      final access = await pumpSheet(tester, cues: const [_whistle]);

      access.emit(const [_whistle, _tag]);
      await tester.pumpAndSettle();

      expect(find.text('Tag!'), findsOneWidget);
    });
  });

  testWidgets('the dip switch is off by default', (tester) async {
    // A whistle is louder than the mix and cuts through on its own, so the
    // common case should not need touching.
    await pumpSheet(tester);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
  });
}
