import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/screens/set_shape_dialog.dart';
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
          ),
        ),
      );

      for (final s in tester.widgetList<Switch>(find.byType(Switch))) {
        expect(s.value, isTrue);
      }
      expect(find.text('8'), findsOneWidget);
      expect(find.text('90'), findsOneWidget);
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

    expect(find.textContaining('applies the next time this set is opened'),
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
