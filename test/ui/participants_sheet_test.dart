import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/ui/screens/participants_sheet.dart';
import 'package:sayaw/ui/state/jack_and_jill_provider.dart';

import '../fakes/fake_jack_and_jill.dart';
import 'harness.dart';

Participant _person(String name, {bool present = true, int draws = 0}) =>
    fakePerson(name).copyWith(isPresent: present, drawCount: draws);

void main() {
  Future<FakeJackAndJill> pumpSheet(
    WidgetTester tester, {
    List<Participant> people = const [],
  }) async {
    final access = FakeJackAndJill()..people = people;
    addTearDown(access.close);

    await pumpSayaw(
      tester,
      Scaffold(body: ParticipantsSheet(access: access)),
      overrides: [jackAndJillProvider.overrideWithValue(access)],
    );
    await tester.pumpAndSettle();
    return access;
  }

  group('taking names at the door', () {
    testWidgets('an empty roster says so', (tester) async {
      await pumpSheet(tester);

      expect(find.text('Nobody signed in yet.'), findsOneWidget);
    });

    testWidgets('typing a name and pressing Add puts it on the list',
        (tester) async {
      final access = await pumpSheet(tester);

      await tester.enterText(find.byType(TextField), 'Marta');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(access.added, ['Marta']);
    });

    testWidgets('Enter does the same, because a door queue is typed not tapped',
        (tester) async {
      final access = await pumpSheet(tester);

      await tester.enterText(find.byType(TextField), 'Yusuf');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(access.added, ['Yusuf']);
    });

    testWidgets('the field clears and keeps focus for the next arrival',
        (tester) async {
      // A queue of arrivals goes in without reaching for the field between
      // each one.
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
      expect(tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
          isTrue);
    });

    testWidgets('an empty name is not added', (tester) async {
      final access = await pumpSheet(tester);

      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(access.added, isEmpty);
    });
  });

  group('the list', () {
    testWidgets('shows who is here out of everyone', (tester) async {
      await pumpSheet(tester, people: [
        _person('Ana'),
        _person('Yusuf'),
        _person('Gone', present: false),
      ]);

      expect(find.text('2 of 3 here'), findsOneWidget);
    });

    testWidgets('unticking someone marks them gone rather than deleting them',
        (tester) async {
      // Their name should not have to be retyped next week.
      final access = await pumpSheet(tester, people: [_person('Ana')]);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      expect(access.presence, {'ana': false});
      expect(access.removed, isEmpty);
    });

    testWidgets('the remove button really removes', (tester) async {
      final access = await pumpSheet(tester, people: [_person('Ana')]);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(access.removed, ['ana']);
    });

    testWidgets('and it says whose row it is, since it is an X on its own',
        (tester) async {
      // Asserted on the widget rather than through `bySemanticsLabel`: inside
      // an AlertDialog the route scoping keeps that finder from seeing it, and
      // what matters here is that the label is declared at all.
      await pumpSheet(tester, people: [_person('Ana'), _person('Yusuf')]);

      final labels = [
        for (final s in tester.widgetList<Semantics>(find.byType(Semantics)))
          s.properties.label,
      ];

      expect(labels, containsAll(['Remove Ana', 'Remove Yusuf']));
      expect(labels, containsAll(['Ana is here', 'Yusuf is here']));
    });

    testWidgets('a draw count is shown once there is one', (tester) async {
      // A caller watching one number climb while another stays at zero is the
      // whole reason the count exists.
      await pumpSheet(tester, people: [
        _person('Ana', draws: 3),
        _person('Yusuf'),
      ]);

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('somebody added while it is open appears', (tester) async {
      final access = await pumpSheet(tester, people: [_person('Ana')]);

      access.emitRoster([_person('Ana'), _person('Yusuf')]);
      await tester.pumpAndSettle();

      expect(find.text('Yusuf'), findsOneWidget);
    });
  });

  group('between events', () {
    testWidgets('there is nothing to reset before anyone has danced',
        (tester) async {
      await pumpSheet(tester, people: [_person('Ana')]);

      expect(find.text('Reset draws'), findsNothing);
    });

    testWidgets('once someone has, the counts can be put back', (tester) async {
      final access =
          await pumpSheet(tester, people: [_person('Ana', draws: 2)]);

      await tester.tap(find.text('Reset draws'));
      await tester.pumpAndSettle();

      expect(access.drawsReset, 1);
    });
  });
}
