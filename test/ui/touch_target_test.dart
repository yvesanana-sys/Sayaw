import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/screens/deck_screen.dart';
import 'package:sayaw/ui/touch/touch_targets.dart';
import 'package:sayaw/ui/widgets/transport_bar.dart';
import 'package:sayaw/ui/widgets/transport_button.dart';

import 'harness.dart';

/// GUARDRAIL — do not delete or weaken to make a layout fit.
///
/// Every interactive element must be operable by a fingertip on a tablet with
/// no mouse attached. If a layout change makes one of these fail, the layout is
/// wrong, not the threshold. Shrinking a target below 48dp is how an app
/// becomes unusable on the exact device this phase exists to support.
void main() {
  group('transport controls', () {
    testWidgets('every transport button has a 64dp hit region', (tester) async {
      await pumpSayaw(tester, const TransportBar(), queue: testQueue());

      final buttons = find.byType(TransportButton);
      expect(buttons, findsWidgets);

      for (final element in buttons.evaluate()) {
        final widget = element.widget as TransportButton;
        final size = tester.getSize(find.byWidget(widget));

        expect(
          size.width,
          greaterThanOrEqualTo(kTransportTouchTarget),
          reason: '"${widget.label}" is ${size.width}dp wide',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(kTransportTouchTarget),
          reason: '"${widget.label}" is ${size.height}dp tall',
        );
      }
    });

    testWidgets('the semantics rect matches the hit region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSayaw(tester, const TransportBar(), queue: testQueue());

      // Walk the bar by semantics rather than by widget type: this is what
      // assistive tech and the OS target-size checks actually see, and a
      // Semantics node smaller than its render box is a real defect even when
      // the box is the right size.
      for (final element in find.byType(TransportButton).evaluate()) {
        final widget = element.widget as TransportButton;
        final node = tester.getSemantics(find.byWidget(widget));

        expect(
          node.rect.width,
          greaterThanOrEqualTo(kTransportTouchTarget),
          reason: 'semantics for "${widget.label}" is ${node.rect.width}dp wide',
        );
        expect(
          node.rect.height,
          greaterThanOrEqualTo(kTransportTouchTarget),
          reason:
              'semantics for "${widget.label}" is ${node.rect.height}dp tall',
        );
        expect(
          node.label,
          isNotEmpty,
          reason: 'every transport control must announce itself',
        );
      }

      handle.dispose();
    });

    testWidgets('the compact bar keeps 64dp targets at 600dp wide',
        (tester) async {
      // The narrowest supported window is where targets get squeezed first.
      await pumpSayaw(
        tester,
        const TransportBar(compact: true),
        size: kCompactSize,
        queue: testQueue(),
      );

      expect(tester.takeException(), isNull);

      for (final element in find.byType(TransportButton).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(kTransportTouchTarget));
        expect(size.height, greaterThanOrEqualTo(kTransportTouchTarget));
      }
    });
  });

  group('the whole deck screen', () {
    for (final (name, size) in [
      ('compact', kCompactSize),
      ('medium', kMediumSize),
      ('expanded', kExpandedSize),
    ]) {
      testWidgets('$name: no tappable is smaller than 48dp', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpSayaw(
          tester,
          const DeckScreen(),
          size: size,
          queue: testQueue(),
        );

        final undersized = <String>[];
        _visitTappables(
          tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!,
          (node) {
            final rect = node.rect;
            if (rect.width + 0.01 < kMinTouchTarget ||
                rect.height + 0.01 < kMinTouchTarget) {
              undersized.add(
                '"${node.label}" ${rect.width.toStringAsFixed(1)}'
                'x${rect.height.toStringAsFixed(1)}',
              );
            }
          },
        );

        expect(
          undersized,
          isEmpty,
          reason: 'tappable targets below ${kMinTouchTarget}dp in $name '
              'layout: ${undersized.join(', ')}',
        );

        handle.dispose();
      });
    }
  });
}

/// Walks the semantics tree and reports every node the user can tap.
///
/// Nodes that merely *contain* a tap handler because a descendant has one are
/// skipped — a scrollable is not a touch target. Only leaf-ish nodes that
/// declare themselves a button or accept a tap are measured.
void _visitTappables(
  SemanticsNode node,
  void Function(SemanticsNode) onTappable,
) {
  final data = node.getSemanticsData();

  final isButton = data.hasFlag(SemanticsFlag.isButton);
  final tappable = data.hasAction(SemanticsAction.tap);

  // A scrollable reports tap for its scroll affordance; measuring it would be
  // meaningless and it is never a target in its own right.
  final isScrollable = data.hasAction(SemanticsAction.scrollUp) ||
      data.hasAction(SemanticsAction.scrollDown) ||
      data.hasAction(SemanticsAction.scrollLeft) ||
      data.hasAction(SemanticsAction.scrollRight);

  if ((isButton || tappable) && !isScrollable) {
    onTappable(node);
  }

  node.visitChildren((child) {
    _visitTappables(child, onTappable);
    return true;
  });
}
