import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/data/library/library_scanner.dart';
import 'package:sayaw/ui/screens/deck_screen.dart';
import 'package:sayaw/ui/screens/first_run_screen.dart';
import 'package:sayaw/ui/state/first_run.dart';
import 'package:sayaw/ui/state/library_access.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';

import 'harness.dart';

/// A library holding exactly [count] tracks and nothing else.
class _CountingLibrary implements LibraryAccess {
  _CountingLibrary(this.count);

  int count;

  @override
  Future<int> libraryCount() async => count;

  @override
  Future<List<Track>> searchLibrary(String query, {int limit = 50}) async => [];

  @override
  Future<List<Track>> recentTracks({int limit = 50}) async => [];

  @override
  Future<void> addToSet(String trackId) async {}

  @override
  Future<List<String>> everyTrackMatching(String query) async => [];

  @override
  Future<void> addAllToSet(List<String> trackIds) async {}

  @override
  Future<int> clearLibrary() async => 0;

  @override
  Future<ScanReport> scanFolders(
    Iterable<Directory> folders, {
    void Function(int filesSeen, String path)? onProgress,
  }) async =>
      const ScanReport(
        added: 0,
        updated: 0,
        unchanged: 0,
        problems: [],
        missing: [],
      );
}

/// A library that cannot answer — a database still opening, or a broken one.
class _MuteLibrary extends _CountingLibrary {
  _MuteLibrary() : super(0);

  @override
  Future<int> libraryCount() async => throw StateError('not ready');
}

Future<void> _pumpDeck(WidgetTester tester, LibraryAccess? library) async {
  await pumpSayaw(
    tester,
    const DeckScreen(),
    size: kExpandedSize,
    overrides: [
      if (library != null) libraryAccessProvider.overrideWithValue(library),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('when it takes over', () {
    testWidgets('an empty library gets the ordered path, not four dead ends',
        (tester) async {
      await _pumpDeck(tester, _CountingLibrary(0));

      expect(find.byType(FirstRunScreen), findsOneWidget);
      expect(find.text("Let's get tonight ready."), findsOneWidget);
    });

    testWidgets('a library with music goes straight to the app',
        (tester) async {
      await _pumpDeck(tester, _CountingLibrary(318));
      expect(find.byType(FirstRunScreen), findsNothing);
    });

    testWidgets('no library to ask is not an empty one', (tester) async {
      // The dangerous direction: a provider that is simply not wired must not
      // put a wizard in front of an operator who is mid-set.
      await _pumpDeck(tester, null);
      expect(find.byType(FirstRunScreen), findsNothing);
    });

    testWidgets('a library that will not answer is not an empty one',
        (tester) async {
      await _pumpDeck(tester, _MuteLibrary());
      expect(find.byType(FirstRunScreen), findsNothing);
    });

    test('only a real zero counts as a first run', () {
      final container = ProviderContainer(overrides: [
        libraryCountProvider.overrideWith((ref) async => null),
      ]);
      addTearDown(container.dispose);
      expect(container.read(isFirstRunProvider), isFalse);
    });
  });

  group('what it asks for', () {
    testWidgets('one step is live and the rest say why they are not',
        (tester) async {
      await pumpSayaw(
        tester,
        const FirstRunScreen(),
        overrides: [
          libraryAccessProvider.overrideWithValue(_CountingLibrary(0)),
        ],
      );

      // Exactly one enabled button among the three steps — the whole point of
      // the screen. The others say what they are waiting for rather than
      // greying out and leaving the operator to guess.
      expect(find.text('After step 1'), findsOneWidget);
      expect(find.text('Optional'), findsOneWidget);
      expect(find.text('Point Sayaw at your music'), findsOneWidget);
    });

    testWidgets('it says nothing is copied or uploaded', (tester) async {
      // A volunteer pointing an unknown app at their music folder deserves to
      // be told this before they do it, not in a settings screen afterwards.
      await pumpSayaw(tester, const FirstRunScreen());
      expect(
        find.text('A folder on this machine or a drive. '
            'Nothing is copied or uploaded.'),
        findsOneWidget,
      );
    });

    testWidgets('Plex is offered, and explicitly not required', (tester) async {
      await pumpSayaw(tester, const FirstRunScreen());

      expect(find.text('Connect a Plex server'), findsOneWidget);
      expect(
        find.text('Local files work without any of this — a server is for the '
            'rest of your library.'),
        findsOneWidget,
      );
    });

    testWidgets('every step reads aloud, disabled ones included',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSayaw(tester, const FirstRunScreen());

      expect(find.bySemanticsLabel(RegExp('Step 1, do this now')),
          findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Step 2, not yet')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Step 3, optional')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('nothing pressable is under 48dp', (tester) async {
      await pumpSayaw(tester, const FirstRunScreen());

      for (final element in find.byType(InkWell).evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.height, greaterThanOrEqualTo(48.0));
      }
    });
  });
}
