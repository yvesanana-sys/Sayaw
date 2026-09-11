import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/library_access.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/touch/touch_targets.dart';
import 'package:sayaw/ui/widgets/song_length_chips.dart';

import '../fakes/fake_set_shape.dart';
import 'harness.dart';

void main() {
  Future<FakeSetShape> pumpChips(
    WidgetTester tester, {
    Duration? current,
    SetShape? shape,
  }) async {
    final access = FakeSetShape(shape: shape);
    await pumpSayaw(
      tester,
      const Scaffold(body: SongLengthChips()),
      overrides: [
        setShapeProvider.overrideWithValue(access),
        songLengthProvider.overrideWithValue(current),
      ],
    );
    await tester.pumpAndSettle();
    return access;
  }

  testWidgets('the whole song and the usual lengths, whole song selected',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pumpChips(tester);

    for (final text in ['Full song', '2:00', '2:30', '3:00', '3:30', '4:00']) {
      expect(find.text(text), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Playing the whole song of each, selected'),
        findsOneWidget);
    handle.dispose();
  });

  testWidgets('choosing one writes it and keeps the rest of the shape',
      (tester) async {
    final access = await pumpChips(
      tester,
      shape: const SetShape(
        songLimit: 5,
        rotationGap: Duration(seconds: 10),
        snowballStages: 3,
      ),
    );

    await tester.tap(find.text('2:30'));
    await tester.pumpAndSettle();

    final written = access.writes.single;
    expect(written.songDuration, const Duration(minutes: 2, seconds: 30));
    expect(written.songLimit, 5, reason: 'not clobbered');
    expect(written.rotationGap, const Duration(seconds: 10));
    expect(written.snowballStages, 3);
  });

  testWidgets('the set\'s current length is the selected one', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpChips(tester, current: const Duration(minutes: 3));

    expect(find.bySemanticsLabel('Playing 3 minutes of each, selected'),
        findsOneWidget);
    handle.dispose();
  });

  testWidgets('a length that is not a preset is still shown', (tester) async {
    await pumpChips(tester, current: const Duration(minutes: 2, seconds: 45));

    expect(find.text('2:45'), findsOneWidget);
  });

  testWidgets('back to the whole song', (tester) async {
    final access = await pumpChips(tester, current: const Duration(minutes: 2));

    await tester.tap(find.text('Full song'));
    await tester.pumpAndSettle();

    expect(access.writes.single.songDuration, isNull);
  });

  testWidgets('every chip is a fingertip tall', (tester) async {
    await pumpChips(tester);

    for (final text in ['Full song', '2:00', '4:00']) {
      expect(tester.getSize(find.ancestor(
        of: find.text(text),
        matching: find.byType(SizedBox),
      ).first).height, greaterThanOrEqualTo(kMinTouchTarget));
    }
  });
}
