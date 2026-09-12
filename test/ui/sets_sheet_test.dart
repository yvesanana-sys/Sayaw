import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/screens/sets_sheet.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';

import '../fakes/fake_sets.dart';
import 'harness.dart';

void main() {
  Future<FakeSets> pumpSheet(WidgetTester tester, {FakeSets? sets}) async {
    final fake = sets ?? FakeSets();
    addTearDown(fake.close);
    // Opened the way the screen opens it — as a dialog over the queue — so
    // closing it has somewhere to go.
    await pumpSayaw(
      tester,
      const Scaffold(body: Center(child: SetsButton())),
      overrides: [
        setsProvider.overrideWithValue(fake),
        setNameProvider.overrideWithValue('Tonight'),
      ],
    );
    await tester.tap(find.byType(SetsButton));
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('the save button asks for a name and saves a copy',
      (tester) async {
    final fake = FakeSets();
    addTearDown(fake.close);
    await pumpSayaw(
      tester,
      const Scaffold(body: Center(child: SaveSetButton())),
      overrides: [setsProvider.overrideWithValue(fake)],
    );

    await tester.tap(find.byType(SaveSetButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Friday class');
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Save'),
    ));
    await tester.pumpAndSettle();

    expect(fake.savedAs, ['Friday class']);
    expect(find.text('Saved a copy as "Friday class"'), findsOneWidget);
  });

  testWidgets('lists the sets, with the open one marked', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpSheet(tester);

    expect(find.text('Tonight'), findsOneWidget);
    expect(find.text('Class'), findsOneWidget);
    expect(find.bySemanticsLabel('Tonight, open'), findsOneWidget);
    expect(find.bySemanticsLabel('Open Class'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('saving a copy needs a name, then takes it', (tester) async {
    final sets = await pumpSheet(tester);

    await tester.tap(find.text('Save copy'));
    await tester.pumpAndSettle();
    expect(find.text('Give the copy a name.'), findsOneWidget);
    expect(sets.savedAs, isEmpty);

    await tester.enterText(find.byType(TextField), 'Saturday social');
    await tester.tap(find.text('Save copy'));
    await tester.pumpAndSettle();

    expect(sets.savedAs, ['Saturday social']);
    expect(find.text('Saved a copy as "Saturday social"'), findsOneWidget);
  });

  testWidgets('opening a set closes the sheet', (tester) async {
    final sets = await pumpSheet(tester);

    await tester.tap(find.bySemanticsLabel('Open Class'));
    await tester.pumpAndSettle();

    expect(sets.opened, ['p2']);
    expect(find.byType(SetsSheet), findsNothing);
  });

  testWidgets('but not while music plays, and it says so', (tester) async {
    final sets = await pumpSheet(tester, sets: FakeSets(isRunning: true));

    await tester.tap(find.bySemanticsLabel('Open Class'));
    await tester.pumpAndSettle();

    expect(sets.opened, isEmpty);
    expect(find.text('Stop the music before opening another set.'),
        findsOneWidget);
    expect(find.byType(SetsSheet), findsOneWidget);
  });

  testWidgets('removing asks first, and says the music stays', (tester) async {
    final sets = await pumpSheet(tester);

    await tester.tap(find.bySemanticsLabel('Remove Class'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The music stays in the library'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(sets.deleted, ['p2']);
  });

  testWidgets('renaming', (tester) async {
    final sets = await pumpSheet(tester);

    await tester.tap(find.bySemanticsLabel('Rename Class'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Beginners');
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(sets.renamed, [('p2', 'Beginners')]);
  });

  testWidgets('a new empty set', (tester) async {
    final sets = await pumpSheet(tester);

    await tester.enterText(find.byType(TextField), 'Practice');
    await tester.tap(find.text('New empty set'));
    await tester.pumpAndSettle();

    expect(sets.created, ['Practice']);
    expect(find.byType(SetsSheet), findsNothing);
  });
}
