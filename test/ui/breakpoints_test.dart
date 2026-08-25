import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/layout/breakpoints.dart';

import 'harness.dart';

void main() {
  group('breakpointForWidth', () {
    test('classifies the documented ranges', () {
      expect(breakpointForWidth(320), SayawBreakpoint.compact);
      expect(breakpointForWidth(699.9), SayawBreakpoint.compact);
      expect(breakpointForWidth(700), SayawBreakpoint.medium);
      expect(breakpointForWidth(900), SayawBreakpoint.medium);
      expect(breakpointForWidth(1100), SayawBreakpoint.medium);
      expect(breakpointForWidth(1100.1), SayawBreakpoint.expanded);
      expect(breakpointForWidth(3840), SayawBreakpoint.expanded);
    });

    test('degenerate widths do not throw', () {
      expect(breakpointForWidth(0), SayawBreakpoint.compact);
      expect(breakpointForWidth(double.infinity), SayawBreakpoint.expanded);
    });

    test('only compact uses bottom navigation', () {
      expect(SayawBreakpoint.compact.usesRail, isFalse);
      expect(SayawBreakpoint.medium.usesRail, isTrue);
      expect(SayawBreakpoint.expanded.usesRail, isTrue);
    });
  });

  group('SayawLayout', () {
    testWidgets('publishes the breakpoint to descendants', (tester) async {
      late SayawBreakpoint seen;

      await pumpSayaw(
        tester,
        SayawLayout(
          builder: (context, _) => Builder(
            builder: (context) {
              seen = SayawLayout.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
        size: kMediumSize,
      );

      expect(seen, SayawBreakpoint.medium);
    });

    testWidgets('measures its own constraints, not the window', (tester) async {
      late SayawBreakpoint seen;

      // A wide window, but this subtree only got a 400dp pane. Laying out for
      // the window here would overflow the pane.
      await pumpSayaw(
        tester,
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 400,
            child: SayawLayout(
              builder: (context, breakpoint) {
                seen = breakpoint;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        size: kExpandedSize,
      );

      expect(seen, SayawBreakpoint.compact);
    });

    testWidgets('falls back to the window when there is no scope above',
        (tester) async {
      late SayawBreakpoint seen;

      await pumpSayaw(
        tester,
        Builder(
          builder: (context) {
            seen = SayawLayout.of(context);
            return const SizedBox.shrink();
          },
        ),
        size: kCompactSize,
      );

      expect(seen, SayawBreakpoint.compact);
    });

    testWidgets('a resize republishes the new breakpoint', (tester) async {
      final seen = <SayawBreakpoint>[];

      await pumpSayaw(
        tester,
        SayawLayout(
          builder: (context, breakpoint) {
            seen.add(breakpoint);
            return const SizedBox.shrink();
          },
        ),
        size: kCompactSize,
      );
      expect(seen.last, SayawBreakpoint.compact);

      await setWindowSize(tester, kExpandedSize);
      await tester.pumpAndSettle();

      expect(seen.last, SayawBreakpoint.expanded);
    });
  });
}
