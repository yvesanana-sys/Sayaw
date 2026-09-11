import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/layout/breakpoints.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/announcer_strip.dart';
import 'package:sayaw/ui/widgets/queue_list.dart';

import '../fakes/fake_merge.dart';
import 'harness.dart';

Finder _buttonFor(String id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byType(QueueMergeButton),
    );

void main() {
  Future<FakeMerge> pumpQueue(WidgetTester tester,
      {List<QueueItemUi>? queue}) async {
    final access = FakeMerge();
    await pumpSayaw(
      tester,
      Scaffold(
        body: SayawLayout(builder: (context, _) => const QueueList()),
      ),
      queue: queue ?? testQueue(),
      overrides: [mergeProvider.overrideWithValue(access)],
    );
    await tester.pumpAndSettle();
    return access;
  }

  testWidgets('every row but the last can be run into the next',
      (tester) async {
    await pumpQueue(tester);

    expect(find.byType(QueueMergeButton), findsNWidgets(3));
    expect(_buttonFor('q4'), findsNothing,
        reason: 'the last row has nothing to run into');
  });

  testWidgets('a tap joins them, another separates them', (tester) async {
    final access = await pumpQueue(tester);

    await tester.tap(_buttonFor('q1'));
    await tester.pumpAndSettle();
    expect(access.joins, [('q1', true)]);

    // The fake does not redraw the row; a joined row would offer to separate.
    final joined = [
      for (final item in testQueue())
        item.id == 'q1' ? item.withMergeIntoNext(true) : item,
    ];
    final again = await pumpQueue(tester, queue: joined);
    await tester.tap(_buttonFor('q1'));
    await tester.pumpAndSettle();
    expect(again.joins, [('q1', false)]);
  });

  testWidgets('a joined row says so without a pointer', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpQueue(tester, queue: [
      for (final item in testQueue())
        item.id == 'q1' ? item.withMergeIntoNext(true) : item,
    ]);

    expect(
      find.bySemanticsLabel(
          'Kiss of Fire merges into the next song. Separate them'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('the strip says merge where it would say nothing',
      (tester) async {
    final container = await pumpSayaw(
      tester,
      const Scaffold(body: AnnouncerStrip()),
      overrides: [nextMergesProvider.overrideWithValue(true)],
    );
    await tester.pumpAndSettle();

    expect(find.text('Merges into the next song'), findsOneWidget);
    expect(container.read(playbackProvider).announcement, isNull);
  });
}
