import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/screens/set_shape_dialog.dart';
import 'package:sayaw/data/set_ordering.dart';
import 'package:sayaw/ui/state/library_access.dart';

import '../fakes/fake_set_shape.dart';
import 'harness.dart';

void main() {
  /// Shown as a real dialog route rather than as a bare body: popping and the
  /// message that follows it both depend on there being a route to pop.
  Future<void> pumpDialog(WidgetTester tester, FakeSetShape access) async {
    await pumpSayaw(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => SetShapeDialog(access: access),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }


  /// A switch by what it is, not where it sits.
  ///
  /// Positional finders broke every time a row was added above them, which is
  /// exactly the kind of test failure that says nothing about the code.
  Finder switchFor(String semanticsLabel) => find.descendant(
        of: find.bySemanticsLabel(semanticsLabel),
        matching: find.byType(Switch),
      );

  const flowLabel = 'Continuous flow, no gap between tracks';

  /// The stepper next to one of the two rows.
  Finder stepper(String row, String which) => find.descendant(
        of: find.ancestor(
          of: find.text(row),
          matching: find.byType(Row),
        ).first,
        matching: find.bySemanticsLabel(which),
      );

  group('what it opens showing', () {
    testWidgets('a plain playlist has both switches off', (tester) async {
      await pumpDialog(tester, FakeSetShape());

      for (final s in tester.widgetList<Switch>(find.byType(Switch))) {
        expect(s.value, isFalse);
      }
      expect(
        find.text('Plays the set as written: every row, each track to its end.'),
        findsOneWidget,
      );
    });

    testWidgets('an existing shape is read back, not defaulted over',
        (tester) async {
      await pumpDialog(
        tester,
        FakeSetShape(
          shape: const SetShape(
            songLimit: 8,
            songDuration: Duration(seconds: 90),
            rotationGap: Duration(seconds: 15),
          ),
        ),
      );

      // By position rather than "all of them": continuous flow is deliberately
      // not available alongside a rotation, so a blanket assertion could never
      // hold and would have to be weakened rather than read.
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect([switches[0].value, switches[1].value, switches[2].value],
          [true, true, true]);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });
  });

  group('the sentence under the numbers', () {
    // Two switches and two numbers do not say what the night will do.
    testWidgets('a song count alone', (tester) async {
      final access = FakeSetShape(shape: const SetShape(songLimit: 5));
      await pumpDialog(tester, access);

      expect(find.text('Plays 5 songs in full, then fades out and stops.'),
          findsOneWidget);
    });

    testWidgets('a length alone', (tester) async {
      final access =
          FakeSetShape(shape: const SetShape(songDuration: Duration(minutes: 2)));
      await pumpDialog(tester, access);

      expect(find.text('Plays 2 minutes of every track, then crossfades to '
          'the next.'), findsOneWidget);
    });

    testWidgets('both, which is what a rotation is', (tester) async {
      final access = FakeSetShape(
        shape: const SetShape(
          songLimit: 5,
          songDuration: Duration(minutes: 2),
        ),
      );
      await pumpDialog(tester, access);

      expect(
        find.text('Plays 2 minutes of each track, 5 times, then fades out '
            'and stops.'),
        findsOneWidget,
      );
    });

    testWidgets('one song reads as one song, not 1 songs', (tester) async {
      final access = FakeSetShape(shape: const SetShape(songLimit: 1));
      await pumpDialog(tester, access);

      expect(find.text('Plays 1 song in full, then fades out and stops.'),
          findsOneWidget);
    });

    testWidgets('a length that is not whole minutes still reads', (tester) async {
      final access =
          FakeSetShape(shape: const SetShape(songDuration: Duration(seconds: 105)));
      await pumpDialog(tester, access);

      expect(find.textContaining('1 minute 45 sec'), findsOneWidget);
    });
  });

  group('changing it', () {
    testWidgets('the steppers move the number', (tester) async {
      final access = FakeSetShape(shape: const SetShape(songLimit: 5));
      await pumpDialog(tester, access);

      await tester.tap(stepper('Stop after', 'More'));
      await tester.pumpAndSettle();

      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('a number can be typed for the operator who wants 137',
        (tester) async {
      final access = FakeSetShape(shape: const SetShape(songLimit: 5));
      await pumpDialog(tester, access);

      await tester.enterText(find.byType(TextField).first, '137');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(access.writes.single.songLimit, 137);
    });

    testWidgets('turning a switch off clears that half', (tester) async {
      final access = FakeSetShape(
        shape: const SetShape(
          songLimit: 5,
          songDuration: Duration(minutes: 2),
        ),
      );
      await pumpDialog(tester, access);

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(access.writes.single.songLimit, isNull);
      expect(access.writes.single.songDuration, const Duration(minutes: 2));
    });

    testWidgets('cancel writes nothing', (tester) async {
      final access = FakeSetShape(shape: const SetShape(songLimit: 5));
      await pumpDialog(tester, access);

      await tester.tap(stepper('Stop after', 'More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(access.writes, isEmpty);
    });

    testWidgets('the steppers stop at the ends rather than going through them',
        (tester) async {
      final access = FakeSetShape(shape: const SetShape(songLimit: 1));
      await pumpDialog(tester, access);

      final fewer = tester.widget<IconButton>(
        find.descendant(
          of: stepper('Stop after', 'Fewer'),
          matching: find.byType(IconButton),
        ),
      );
      expect(fewer.onPressed, isNull);
    });
  });


  group('the rotation', () {
    testWidgets('says what the floor is going to experience', (tester) async {
      final access = FakeSetShape(
        shape: const SetShape(
          songLimit: 5,
          songDuration: Duration(minutes: 2),
          rotationGap: Duration(seconds: 10),
        ),
      );
      await pumpDialog(tester, access);

      expect(find.textContaining('holding 10 seconds of silence between them'),
          findsOneWidget);
      expect(find.textContaining('change partners'), findsOneWidget);
    });

    testWidgets('is off on an ordinary set', (tester) async {
      await pumpDialog(tester, FakeSetShape());

      expect(
        find.text('Plays the set as written: every row, each track to its end.'),
        findsOneWidget,
      );
    });

    testWidgets('turning it on writes a gap', (tester) async {
      final access = FakeSetShape();
      await pumpDialog(tester, access);

      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(access.writes.single.rotationGap, const Duration(seconds: 10));
      expect(access.writes.single.isRotation, isTrue);
    });

    testWidgets('turning it off puts the set back to an ordinary one',
        (tester) async {
      final access =
          FakeSetShape(shape: const SetShape(rotationGap: Duration(seconds: 10)));
      await pumpDialog(tester, access);

      await tester.tap(find.byType(Switch).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(access.writes.single.rotationGap, Duration.zero);
      expect(access.writes.single.isPlainList, isTrue);
    });
  });



  group('continuous flow', () {
    testWidgets('off, a set crossfades and speaks as usual', (tester) async {
      await pumpDialog(tester, FakeSetShape());

      expect(tester.widget<Switch>(switchFor(flowLabel)).value, isFalse);
    });

    testWidgets('turning it on writes it', (tester) async {
      final access = FakeSetShape();
      await pumpDialog(tester, access);

      await tester.tap(switchFor(flowLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(access.writes.single.continuousFlow, isTrue);
    });

    testWidgets('it says what turning it off will do', (tester) async {
      // The lossy part: nothing here can know what crossfade the set had
      // before, so it says which one it will put back.
      await pumpDialog(tester, FakeSetShape());

      expect(find.textContaining('restores a 4 second crossfade'),
          findsOneWidget);
    });

    testWidgets('a rotation takes it away, and says why', (tester) async {
      // Silence between tracks by definition, so the two cannot both be on.
      final access =
          FakeSetShape(shape: const SetShape(rotationGap: Duration(seconds: 10)));
      await pumpDialog(tester, access);

      expect(tester.widget<Switch>(switchFor(flowLabel)).onChanged, isNull);
      expect(find.textContaining('Not with a partner rotation'), findsOneWidget);
    });

    testWidgets('the sentence describes a continuous set', (tester) async {
      final access = FakeSetShape(
        shape: const SetShape(
          continuousFlow: true,
          songDuration: Duration(minutes: 2),
          songLimit: 6,
        ),
      );
      await pumpDialog(tester, access);

      expect(
        find.text('Plays 2 minutes of each track straight into the next, with '
            'no crossfade and nothing spoken in between. Stops after 6 songs.'),
        findsOneWidget,
      );
    });
  });


  group('snowball', () {
    const stagesLabel = 'Number of Snowball stages';

    testWidgets('off on an ordinary set', (tester) async {
      await pumpDialog(tester, FakeSetShape());

      expect(tester.widget<Switch>(switchFor(stagesLabel)).value, isFalse);
    });

    testWidgets('an existing stage count is read back', (tester) async {
      await pumpDialog(
        tester,
        FakeSetShape(shape: const SetShape(snowballStages: 4)),
      );

      expect(tester.widget<Switch>(switchFor(stagesLabel)).value, isTrue);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('turning it on writes a stage count', (tester) async {
      final access = FakeSetShape();
      await pumpDialog(tester, access);

      await tester.tap(switchFor(stagesLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(access.writes.single.snowballStages, 5);
      expect(access.writes.single.isSnowball, isTrue);
    });

    testWidgets('turning it off clears it', (tester) async {
      final access =
          FakeSetShape(shape: const SetShape(snowballStages: 5));
      await pumpDialog(tester, access);

      await tester.tap(switchFor(stagesLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(access.writes.single.snowballStages, 0);
      expect(access.writes.single.isSnowball, isFalse);
    });

    testWidgets('it says that the stage count alone is not a climb',
        (tester) async {
      // The number only decides what is drawn. What makes the tempo rise is
      // the ordering, which is a separate button — so say so rather than let
      // an operator think switching this on did the work.
      await pumpDialog(
        tester,
        FakeSetShape(shape: const SetShape(snowballStages: 5)),
      );

      expect(
        find.text('Shows the climb in 5 stages while it plays. Order the set '
            'slowest first below to make the tempo actually rise.'),
        findsOneWidget,
      );
    });
  });

  group('ordering by tempo', () {
    testWidgets('both directions are offered', (tester) async {
      // A Line of Dance set climbs gently; a night that winds down runs the
      // other way. Neither is called a mode, because the difference is what
      // the operator is doing with it.
      await pumpDialog(tester, FakeSetShape());

      expect(find.text('Slowest first'), findsOneWidget);
      expect(find.text('Fastest first'), findsOneWidget);
    });

    testWidgets('it happens on the button, not on save', (tester) async {
      // It rewrites playlist rows rather than setting a number, so Cancel has
      // to keep meaning what it says about everything else in the dialog.
      final access = FakeSetShape();
      await pumpDialog(tester, access);

      await tester.tap(find.text('Slowest first'));
      await tester.pumpAndSettle();

      expect(access.orderings, [TempoOrder.ascending]);
      expect(access.writes, isEmpty);
    });

    testWidgets('fastest first asks for the other direction', (tester) async {
      final access = FakeSetShape();
      await pumpDialog(tester, access);

      await tester.tap(find.text('Fastest first'));
      await tester.pumpAndSettle();

      expect(access.orderings, [TempoOrder.descending]);
    });

    testWidgets('a clean order says so plainly', (tester) async {
      final access = FakeSetShape()
        ..ordered = const OrderedSet(
          itemIds: ['a', 'b', 'c'],
          guessed: [],
          withoutTempo: [],
        );
      await pumpDialog(tester, access);

      await tester.tap(find.text('Slowest first'));
      await tester.pumpAndSettle();

      expect(find.text('Ordered 3 tracks on their own BPM tags.'),
          findsOneWidget);
    });

    testWidgets('what had to be guessed is reported, not hidden',
        (tester) async {
      // A set ordered on twelve tags and twenty-eight guesses is not the same
      // set as one ordered on forty tags, and only the operator can fix it.
      final access = FakeSetShape()
        ..ordered = const OrderedSet(
          itemIds: ['a', 'b', 'c', 'd'],
          guessed: ['b', 'c'],
          withoutTempo: ['d'],
        );
      await pumpDialog(tester, access);

      await tester.tap(find.text('Slowest first'));
      await tester.pumpAndSettle();

      expect(
        find.text('Ordered 4: 2 placed on their dance type, '
            '1 with no tempo left at the end.'),
        findsOneWidget,
      );
    });

    testWidgets('an empty set says there was nothing to do', (tester) async {
      final access = FakeSetShape();
      await pumpDialog(tester, access);

      await tester.tap(find.text('Slowest first'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing in the set to order.'), findsOneWidget);
    });
  });

  testWidgets('a running set is told what did not take effect yet',
      (tester) async {
    // The operator changed a number and watched the dialog close. Without
    // this they have no way to know half of it is waiting for the next set.
    final access = FakeSetShape(
      shape: const SetShape(songDuration: Duration(minutes: 2)),
      isRunning: true,
      appliesInFull: false,
    );
    await pumpDialog(tester, access);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.textContaining('apply the next time this set is opened'),
        findsOneWidget);
  });

  testWidgets('a change that took in full says nothing', (tester) async {
    final access = FakeSetShape(shape: const SetShape(songLimit: 5));
    await pumpDialog(tester, access);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });
}
