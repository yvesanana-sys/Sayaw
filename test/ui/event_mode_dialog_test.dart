import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/event_mode.dart';
import 'package:sayaw/ui/screens/event_mode_dialog.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';

import '../fakes/fake_event_mode.dart';
import 'harness.dart';

void main() {
  late FakeEventMode eventMode;

  setUp(() => eventMode = FakeEventMode());

  Future<void> pumpDialog(WidgetTester tester) => pumpSayaw(
        tester,
        Scaffold(body: EventModeDialog(eventMode: eventMode)),
        overrides: [eventModeProvider.overrideWithValue(eventMode)],
      );

  Future<void> start(WidgetTester tester, {bool settle = true}) async {
    await pumpDialog(tester);
    await tester.tap(find.text('Start'));
    settle ? await tester.pumpAndSettle() : await tester.pump();
  }

  group('before it runs', () {
    testWidgets('it says what it is about to do', (tester) async {
      await pumpDialog(tester);

      expect(find.textContaining('venue wifi before doors open'),
          findsOneWidget);
      expect(eventMode.runs, 0);
    });

    testWidgets('nothing happens until the operator starts it', (tester) async {
      // It downloads a set over someone's connection. Starting on open would
      // be a surprise, and possibly an expensive one.
      await pumpDialog(tester);
      await tester.pump(const Duration(seconds: 5));

      expect(eventMode.runs, 0);
    });
  });

  group('while it runs', () {
    testWidgets('the step and the track are both named', (tester) async {
      eventMode
        ..gate = Completer<void>()
        ..progress = const [
          PreflightProgress(
            step: PreflightStep.downloading,
            done: 11,
            total: 318,
            title: 'Kiss of Fire',
          ),
        ];

      await start(tester, settle: false);

      // A stall with a name attached to it is diagnosable; a spinner is not.
      expect(find.text('Downloading 12 of 318'), findsOneWidget);
      expect(find.text('Kiss of Fire'), findsOneWidget);

      eventMode.gate!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('there is no way out part-way through', (tester) async {
      eventMode.gate = Completer<void>();
      await start(tester, settle: false);

      expect(find.text('Cancel'), findsOneWidget);
      expect(_dismiss(tester).onPressed, isNull);

      eventMode.gate!.complete();
      await tester.pumpAndSettle();

      // Nothing was cancelled by then, so the way out stops offering to.
      expect(_dismiss(tester).onPressed, isNotNull);
      expect(find.text('Done'), findsOneWidget);
    });
  });

  group('the report', () {
    testWidgets('leads with how much of the set is ready', (tester) async {
      eventMode.report = mixedSet();
      await start(tester);

      expect(find.text('1 of 4 tracks ready offline'), findsOneWidget);
      expect(find.text('All 47 announcements rendered.'), findsOneWidget);
    });

    testWidgets('groups problems by what to do about them', (tester) async {
      // Two streaming-only tracks are one decision about the set; one missing
      // file is one trip to plug a drive in.
      eventMode.report = mixedSet();
      await start(tester);

      expect(
        find.text('2 streaming only — will be skipped without internet'),
        findsOneWidget,
      );
      expect(find.text('1 missing files'), findsOneWidget);
    });

    testWidgets('names each problem row, with its reason', (tester) async {
      eventMode.report = mixedSet();
      await start(tester);

      expect(find.text('Sway — /Volumes/DJ is not mounted'), findsOneWidget);
      expect(find.text('Propuesta Indecente'), findsOneWidget);
    });

    testWidgets('a row that is fine is not listed', (tester) async {
      eventMode.report = mixedSet();
      await start(tester);

      // Three hundred rows that are ready are a number, not a list.
      expect(find.text('Kiss of Fire'), findsNothing);
    });

    testWidgets('a set that needs nothing says so plainly', (tester) async {
      await start(tester);

      expect(find.text('3 of 3 tracks ready offline'), findsOneWidget);
      expect(find.textContaining('Nothing in this set needs a connection'),
          findsOneWidget);
    });

    testWidgets('announcements that could not be rendered are counted',
        (tester) async {
      eventMode.report = const PreflightReport(
        items: [],
        announcementsRendered: 40,
        announcementsMissing: 7,
      );
      await start(tester);

      expect(find.textContaining('7 could not be'), findsOneWidget);
    });
  });

  group('when it goes wrong', () {
    testWidgets('the failure is shown and can be retried', (tester) async {
      eventMode.failure = StateError('server went away');
      await start(tester);

      expect(find.textContaining('server went away'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(eventMode.runs, 2);
      expect(find.text('3 of 3 tracks ready offline'), findsOneWidget);
    });
  });

  group('the app bar button', () {
    testWidgets('is offered when a set is open', (tester) async {
      await pumpSayaw(
        tester,
        const Scaffold(body: EventModeButton()),
        overrides: [eventModeProvider.overrideWithValue(eventMode)],
      );

      expect(_button(tester).onPressed, isNotNull);
    });

    testWidgets('is not offered when there is no set to prepare',
        (tester) async {
      await pumpSayaw(
        tester,
        const Scaffold(body: EventModeButton()),
        overrides: [
          eventModeProvider
              .overrideWithValue(FakeEventMode(openPlaylistId: null)),
        ],
      );

      expect(_button(tester).onPressed, isNull);
    });

    testWidgets('is not offered with no audio behind the screen',
        (tester) async {
      await pumpSayaw(tester, const Scaffold(body: EventModeButton()));

      expect(tester.takeException(), isNull);
      expect(_button(tester).onPressed, isNull);
    });
  });
}

/// The dialog's way out, which is called Cancel while there is still
/// something to abandon and Done once the report is in.
TextButton _dismiss(WidgetTester tester) =>
    tester.widget<TextButton>(find.ancestor(
      of: find.byWidgetPredicate(
        (w) => w is Text && (w.data == 'Cancel' || w.data == 'Done'),
      ),
      matching: find.byType(TextButton),
    ));

IconButton _button(WidgetTester tester) =>
    tester.widget<IconButton>(find.byType(IconButton));
