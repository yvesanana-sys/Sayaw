import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/screens/deck_screen.dart';

import 'harness.dart';

/// There is no hover on a tablet.
///
/// A control whose only label is a [Tooltip], or whose only affordance appears
/// on `onEnter`, is invisible to a finger. This suite is the audit: anything
/// the desktop build reveals on hover has to be reachable, and readable,
/// without a pointer ever entering the widget.
void main() {
  for (final (name, size) in [
    ('compact', kCompactSize),
    ('medium', kMediumSize),
    ('expanded', kExpandedSize),
  ]) {
    testWidgets('$name: no action is gated behind a tooltip', (tester) async {
      await pumpSayaw(
        tester,
        const DeckScreen(),
        size: size,
        queue: testQueue(),
      );

      // The test is not "no Tooltip widgets exist" — Material builds one
      // unconditionally inside every NavigationDestination. It is "no tooltip
      // carries information", because a tooltip with a message is the only
      // place that message lives, and a finger will never see it. Captions and
      // semantics labels carry it instead.
      final withMessages = [
        for (final element in find.byType(Tooltip).evaluate())
          if ((element.widget as Tooltip).message?.isNotEmpty ?? false)
            (element.widget as Tooltip).message!,
      ];

      expect(
        withMessages,
        isEmpty,
        reason: 'these tooltips hold text nothing else shows, and are '
            'unreachable by touch: ${withMessages.join(', ')}',
      );
    });

    testWidgets('$name: every button announces itself without hover',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSayaw(
        tester,
        const DeckScreen(),
        size: size,
        queue: testQueue(),
      );

      final unlabelled = <String>[];
      _visit(
        _semanticsRoot(tester),
        (node) {
          final data = node.getSemanticsData();
          if (!data.flagsCollection.isButton) return;
          if (data.label.trim().isEmpty && data.tooltip.trim().isEmpty) {
            unlabelled.add('${node.id} at ${node.rect}');
          }
        },
      );

      expect(
        unlabelled,
        isEmpty,
        reason: 'unlabelled buttons in $name layout: ${unlabelled.join(', ')}',
      );

      handle.dispose();
    });
  }

  testWidgets('every control is operable with no pointer ever hovering',
      (tester) async {
    await pumpSayaw(
      tester,
      const DeckScreen(),
      size: kCompactSize,
      queue: testQueue(),
    );

    // Drive the whole transport with taps only — no mouse, no hover, no
    // long-press-for-hidden-options. A track reaches a deck by tapping its
    // row in the queue, which in this layout is a pane away.
    await tester.tap(find.text('Queue'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Play Kiss of Fire now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decks'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Pause deck A'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Stop'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Play deck A'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Play deck A'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Pause deck A'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Crossfade now'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

void _visit(SemanticsNode node, void Function(SemanticsNode) visitor) {
  visitor(node);
  node.visitChildren((child) {
    _visit(child, visitor);
    return true;
  });
}

/// The root of the semantics tree.
///
/// Via the binding's render views rather than `binding.pipelineOwner`, which
/// is deprecated: the binding can manage several views, so there is no single
/// pipeline owner to ask any more. A widget test has exactly one, and taking
/// `.first` says so rather than pretending otherwise.
SemanticsNode _semanticsRoot(WidgetTester tester) =>
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!;
