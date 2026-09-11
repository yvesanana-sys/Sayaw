import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/library_pane.dart';

import '../fakes/fake_library.dart';
import 'harness.dart';

/// Longer than the pane's debounce, which exists so a search does not run once
/// per keystroke.
const _afterDebounce = Duration(milliseconds: 250);

void main() {
  Future<FakeLibrary> pumpLibrary(
    WidgetTester tester, {
    FakeLibrary? library,
    List<Override> extra = const [],
  }) async {
    final fake = library ?? FakeLibrary();
    await pumpSayaw(
      tester,
      const Scaffold(body: LibraryPane()),
      overrides: [libraryAccessProvider.overrideWithValue(fake), ...extra],
    );
    return fake;
  }

  testWidgets('what arrived most recently is shown before anyone types',
      (tester) async {
    final library = await pumpLibrary(tester);

    expect(library.recentCalls, 1);
    expect(library.queries, isEmpty);
    expect(find.text('Track 0'), findsOneWidget);
  });

  testWidgets('typing searches the library, once', (tester) async {
    final library = await pumpLibrary(tester);

    await tester.enterText(find.byType(TextField), 'georgia');
    await tester.pump(_afterDebounce);
    await tester.pumpAndSettle();

    // Once, not once per letter: the whole point of the debounce.
    expect(library.queries, ['georgia']);
    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Track 0'), findsNothing);
  });

  testWidgets('clearing the field goes back to what arrived recently',
      (tester) async {
    final library = await pumpLibrary(tester);

    await tester.enterText(find.byType(TextField), 'georgia');
    await tester.pump(_afterDebounce);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(_afterDebounce);
    await tester.pumpAndSettle();

    expect(library.recentCalls, 2);
    expect(find.text('Track 0'), findsOneWidget);
  });

  testWidgets('a search matching nothing says so, and says what it searched for',
      (tester) async {
    await pumpLibrary(tester);

    await tester.enterText(find.byType(TextField), 'kizomba');
    await tester.pump(_afterDebounce);
    await tester.pumpAndSettle();

    expect(find.text('Nothing matching "kizomba".'), findsOneWidget);
  });

  testWidgets('adding a track hands its id to the library', (tester) async {
    final library = await pumpLibrary(tester);

    await tester.tap(find.bySemanticsLabel('Add Track 0 to the set'));
    await tester.pumpAndSettle();

    expect(library.added, ['track-0']);
  });

  group('adding everything', () {
    testWidgets('asks first, with the real number, then adds them all as one',
        (tester) async {
      // Forty in the library; the list on screen would show them all here,
      // but the number in the question comes from the library, not the list.
      final library = await pumpLibrary(tester);

      await tester.tap(
          find.bySemanticsLabel('Add every track in the library to the set'));
      await tester.pumpAndSettle();
      expect(find.textContaining('all 40 tracks'), findsOneWidget);

      await tester.tap(find.text('Add 40'));
      await tester.pumpAndSettle();

      expect(library.addedAll, hasLength(1), reason: 'one write, not forty');
      expect(library.addedAll.single, hasLength(40));
      expect(library.addedAll.single.first, 'track-0');
      expect(find.text('40 added to the set'), findsOneWidget);
    });

    testWidgets('a search narrows what "all" means', (tester) async {
      final library = await pumpLibrary(tester);

      await tester.enterText(find.byType(TextField), 'Georgia');
      await tester.pump(_afterDebounce);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel(
          'Add every track matching Georgia to the set'));
      await tester.pumpAndSettle();
      expect(find.textContaining('matching "Georgia"'), findsOneWidget);

      await tester.tap(find.text('Add 20'));
      await tester.pumpAndSettle();

      expect(library.addedAll.single, hasLength(20));
      expect(library.addedAll.single, everyElement(contains('track-')));
    });

    testWidgets('cancelling adds nothing', (tester) async {
      final library = await pumpLibrary(tester);

      await tester.tap(
          find.bySemanticsLabel('Add every track in the library to the set'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(library.addedAll, isEmpty);
      expect(library.added, isEmpty);
    });

    testWidgets('with nothing listed there is nothing to add', (tester) async {
      await pumpLibrary(tester, library: FakeLibrary(tracks: []));

      expect(
        find.bySemanticsLabel('Add every track in the library to the set'),
        findsNothing,
      );
    });
  });

  testWidgets('an empty library is explained rather than left blank',
      (tester) async {
    await pumpLibrary(tester, library: FakeLibrary(tracks: []));

    expect(find.textContaining('add a folder of music'), findsOneWidget);
  });

  testWidgets('with no library attached the pane still renders', (tester) async {
    // Every widget test that is not about the library runs in this state, and
    // so does the app for the moment before the runtime finishes starting.
    await pumpSayaw(tester, const Scaffold(body: LibraryPane()));

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('opens with the app'), findsOneWidget);
  });

  testWidgets('a slow search does not overwrite a newer one', (tester) async {
    final library = _SlowLibrary();
    await pumpSayaw(
      tester,
      const Scaffold(body: LibraryPane()),
      overrides: [libraryAccessProvider.overrideWithValue(library)],
    );

    await tester.enterText(find.byType(TextField), 'dean');
    await tester.pump(_afterDebounce);

    // The operator keeps typing while the first query is still out.
    await tester.enterText(find.byType(TextField), 'dean martin');
    await tester.pump(_afterDebounce);

    // Now the slow one comes back, with results for a search nobody is
    // looking at any more.
    library.answer('dean', libraryTracks(count: 1));
    await tester.pumpAndSettle();

    expect(library.queries, ['dean', 'dean martin']);
    expect(find.text('Track 0'), findsNothing);
  });
}

/// Holds each search open until it is answered by name — the ordering a real
/// database on a slow disk produces occasionally, and this pane meets every
/// time somebody types quickly.
class _SlowLibrary extends FakeLibrary {
  /// Nothing in the recents, so anything on screen got there from a search.
  _SlowLibrary() : super(tracks: const []);

  final _pending = <String, Completer<List<Track>>>{};

  void answer(String query, List<Track> results) =>
      _pending.remove(query)?.complete(results);

  @override
  Future<List<Track>> searchLibrary(String query, {int limit = 50}) {
    queries.add(query);
    return (_pending[query] = Completer<List<Track>>()).future;
  }
}
