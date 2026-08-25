import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/widgets/keyboard_safe_area.dart';
import 'package:sayaw/ui/widgets/library_pane.dart';

import 'harness.dart';

/// On a Windows tablet the touch keyboard is raised *over* the bottom of the
/// window — the app window is not resized the way a phone's is. Without
/// accounting for `viewInsets`, the field being typed into sits underneath the
/// keyboard doing the typing.
void main() {
  Widget withKeyboard(double height, Widget child) {
    return Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          viewInsets: EdgeInsets.only(bottom: height),
        ),
        child: child,
      ),
    );
  }

  testWidgets('no padding is added when no keyboard is up', (tester) async {
    await pumpSayaw(
      tester,
      withKeyboard(0, const KeyboardSafeArea(child: SizedBox(height: 100))),
    );

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(KeyboardSafeArea),
        matching: find.byType(Padding),
      ),
    );

    expect(padding.padding, EdgeInsets.zero);
  });

  testWidgets('the keyboard height is padded out, plus breathing room',
      (tester) async {
    await pumpSayaw(
      tester,
      withKeyboard(
        320,
        const KeyboardSafeArea(extra: 16, child: SizedBox(height: 100)),
      ),
    );

    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(KeyboardSafeArea),
        matching: find.byType(Padding),
      ),
    );

    expect(padding.padding, const EdgeInsets.only(bottom: 336));
  });

  testWidgets('the library list stays scrollable with the keyboard up',
      (tester) async {
    await pumpSayaw(
      tester,
      withKeyboard(320, const Scaffold(body: LibraryPane())),
      size: kCompactSize,
      queue: testQueue(),
    );

    expect(tester.takeException(), isNull);

    // The viewport shrinks rather than the content being clipped: padding the
    // scrollable is what keeps the focused field reachable by scrolling.
    final viewport = tester.getSize(
      find.descendant(
        of: find.byType(KeyboardSafeArea),
        matching: find.byType(ListView),
      ),
    );
    expect(viewport.height, lessThan(kCompactSize.height - 320));
  });

  testWidgets('focusing the search field does not throw with a keyboard up',
      (tester) async {
    await pumpSayaw(
      tester,
      withKeyboard(320, const Scaffold(body: LibraryPane())),
      size: kCompactSize,
      queue: testQueue(),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });
}
