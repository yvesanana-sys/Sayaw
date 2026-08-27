import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/jack_and_jill.dart';
import 'package:sayaw/ui/screens/jack_and_jill_dialog.dart';
import 'package:sayaw/ui/state/jack_and_jill_provider.dart';

import '../fakes/fake_jack_and_jill.dart';
import 'harness.dart';

void main() {
  Draw completeDraw() => Draw(
        track: fakeTrack('t1', title: 'Obsesion', artist: 'Aventura'),
        dancers: [fakePerson('Ana'), fakePerson('Yusuf')],
        danceType: fakeDance('bachata', 'Bachata'),
      );

  Future<void> pumpDialog(WidgetTester tester, FakeJackAndJill access) async {
    await pumpSayaw(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => JackAndJillDialog(access: access),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      overrides: [jackAndJillProvider.overrideWithValue(access)],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Opened, with a dance already chosen.
  Future<FakeJackAndJill> pumpWithDance(
    WidgetTester tester, {
    Draw? result,
    Set<DrawProblem> problems = const {},
  }) async {
    final access = FakeJackAndJill(
      dances: [fakeDance('bachata', 'Bachata'), fakeDance('waltz', 'Waltz')],
      result: result,
      problemsFound: problems,
    );
    await pumpDialog(tester, access);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bachata').last);
    await tester.pumpAndSettle();

    return access;
  }

  testWidgets('it asks which dance before it will draw', (tester) async {
    final access = FakeJackAndJill(dances: [fakeDance('bachata', 'Bachata')]);
    await pumpDialog(tester, access);

    final draw = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(draw.onPressed, isNull, reason: 'no dance chosen yet');
  });

  testWidgets('a draw reads out two names and a song', (tester) async {
    // This is the one surface whose audience is the floor rather than the
    // operator.
    final access = await pumpWithDance(tester, result: completeDraw());

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(access.drawn, ['bachata']);
    expect(find.text('Ana  &  Yusuf'), findsOneWidget);
    expect(find.text('Obsesion'), findsOneWidget);
    expect(find.text('Aventura'), findsOneWidget);
  });

  testWidgets('a draw is not counted until it is taken', (tester) async {
    // A caller who redraws because the pair just danced together should not
    // have that count against either of them.
    final access = await pumpWithDance(tester, result: completeDraw());

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(access.committed, isEmpty);
    expect(find.textContaining('Not counted yet'), findsOneWidget);
  });

  testWidgets('taking it counts both and queues the song', (tester) async {
    // The song the room was just promised has to be the song that plays.
    final access = await pumpWithDance(tester, result: completeDraw());

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take it'));
    await tester.pumpAndSettle();

    expect(access.committed, hasLength(1));
    expect(access.queued, ['t1']);
    expect(find.textContaining('added to the end of the set'), findsOneWidget);
  });

  testWidgets('it cannot be taken twice', (tester) async {
    // An operator unsure whether the song is queued will queue it twice.
    final access = await pumpWithDance(tester, result: completeDraw());

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take it'));
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(access.queued, hasLength(1));
  });

  testWidgets('drawing again clears the taken state', (tester) async {
    final access = await pumpWithDance(tester, result: completeDraw());

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take it'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Draw again'));
    await tester.pumpAndSettle();

    expect(access.drawn, hasLength(2));
    expect(find.textContaining('Not counted yet'), findsOneWidget);
  });

  testWidgets('too few people is said, not just refused', (tester) async {
    await pumpWithDance(
      tester,
      problems: {DrawProblem.notEnoughDancers},
    );

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Two people have to be signed in'),
        findsOneWidget);
  });

  testWidgets('an empty dance is said too', (tester) async {
    await pumpWithDance(tester, problems: {DrawProblem.noTracks});

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing in the library is filed under'),
        findsOneWidget);
  });

  testWidgets('both problems at once are both said', (tester) async {
    await pumpWithDance(
      tester,
      problems: {DrawProblem.notEnoughDancers, DrawProblem.noTracks},
    );

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Two people have to be'), findsOneWidget);
    expect(find.textContaining('Nothing in the library'), findsOneWidget);
  });

  testWidgets('a screen reader gets the whole announcement', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWithDance(tester, result: completeDraw());

    await tester.tap(find.text('Draw'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel(
          'Ana and Yusuf, dancing Bachata to Obsesion.'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
