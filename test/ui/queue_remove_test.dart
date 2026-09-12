import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/layout/breakpoints.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/queue_list.dart';

import '../fakes/fake_queue_edit.dart';
import 'harness.dart';

Finder _buttonFor(String id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byType(QueueRemoveButton),
    );

void main() {
  Future<(FakeQueueEdit, ProviderContainer)> pump(WidgetTester tester) async {
    final access = FakeQueueEdit();
    final container = await pumpSayaw(
      tester,
      Scaffold(
        body: SayawLayout(builder: (context, _) => const QueueList()),
      ),
      queue: testQueue(),
      overrides: [queueEditProvider.overrideWithValue(access)],
    );
    await tester.pumpAndSettle();
    return (access, container);
  }

  testWidgets('one tap removes, and offers to undo', (tester) async {
    final (access, _) = await pump(tester);

    await tester.tap(_buttonFor('q2'));
    await tester.pumpAndSettle();

    expect(access.removed, ['q2']);
    expect(find.textContaining('Removed'), findsOneWidget);

    await tester.tap(find.text('UNDO'));
    await tester.pumpAndSettle();
    expect(access.restored, ['q2']);
  });

  testWidgets('the row playing cannot be removed, and says so',
      (tester) async {
    final handle = tester.ensureSemantics();
    final (access, container) = await pump(tester);
    container.read(playbackProvider.notifier).playFrom(testQueue()[0]);
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Kiss of Fire is playing and cannot be removed'),
      findsOneWidget,
    );
    await tester.tap(_buttonFor('q1'));
    await tester.pumpAndSettle();
    expect(access.removed, isEmpty);
    handle.dispose();
  });

  testWidgets('every row has one, a fingertip wide', (tester) async {
    await pump(tester);

    expect(find.byType(QueueRemoveButton), findsNWidgets(4));
    for (final e in find.byType(QueueRemoveButton).evaluate()) {
      expect(tester.getSize(find.byWidget(e.widget)).width,
          greaterThanOrEqualTo(48));
    }
  });
}


