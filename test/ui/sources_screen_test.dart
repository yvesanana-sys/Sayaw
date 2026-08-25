import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/sources/plex/plex_auth.dart';
import 'package:sayaw/data/sources/plex/plex_library.dart';
import 'package:sayaw/ui/screens/sources_screen.dart';
import 'package:sayaw/ui/state/sources_provider.dart';

import '../fakes/fake_sources_access.dart';
import 'harness.dart';

/// The dialog's poll interval. Widget-test time is fake, so waiting two
/// seconds of it costs nothing.
const _aPoll = Duration(seconds: 2);

void main() {
  late FakeSources sources;

  setUp(() {
    sources = FakeSources(
      servers: [fakeServer()],
      sections: const [PlexSection(key: '1', title: 'Music')],
    );
    addTearDown(sources.close);
  });

  Future<void> pumpSources(WidgetTester tester) => pumpSayaw(
        tester,
        const SourcesScreen(),
        overrides: [sourcesProvider.overrideWithValue(sources)],
      );

  Future<void> openSignIn(WidgetTester tester) async {
    await pumpSources(tester);
    await tester.tap(find.text('Connect a Plex server'));
    await tester.pumpAndSettle();
  }

  group('the sources list', () {
    testWidgets('says local files need none of this when nothing is connected',
        (tester) async {
      await pumpSources(tester);

      expect(find.textContaining('Local files work without any of this'),
          findsOneWidget);
    });

    testWidgets('lists what is connected', (tester) async {
      sources.publish([FakeSources.accountFor(fakeServer(name: 'Booth NAS'))]);
      await pumpSources(tester);

      expect(find.text('Booth NAS'), findsOneWidget);
      expect(find.text('Your server'), findsOneWidget);
    });

    testWidgets('a server says whether it is yours or shared', (tester) async {
      sources.publish([
        FakeSources.accountFor(fakeServer(name: 'Mine')),
        FakeSources.accountFor(
            fakeServer(id: 'b', name: 'Theirs', owned: false)),
      ]);
      await pumpSources(tester);

      // Worth seeing before an import: a shared library cannot be cached, so
      // it will not play with the wifi down.
      expect(find.text('Your server'), findsOneWidget);
      expect(find.text('Shared with you'), findsOneWidget);
    });

    testWidgets('disconnecting a server removes it', (tester) async {
      sources.publish([FakeSources.accountFor(fakeServer())]);
      await pumpSources(tester);

      // The row reads as one node, so the action has to name the server it
      // belongs to — "Disconnect" alone would be ambiguous in a list of them.
      expect(find.bySemanticsLabel(RegExp('Disconnect Home Server')),
          findsOneWidget);

      await tester.tap(find.byIcon(Icons.link_off));
      await tester.pumpAndSettle();

      expect(sources.disconnected, ['server-uuid']);
      expect(find.text('Home Server'), findsNothing);
    });

    testWidgets('with nothing behind it the screen still renders',
        (tester) async {
      await pumpSayaw(tester, const SourcesScreen());

      expect(tester.takeException(), isNull);
      expect(find.textContaining('open with the app'), findsOneWidget);
    });
  });

  group('signing in to Plex', () {
    testWidgets('the code is shown and stays shown while it is polled for',
        (tester) async {
      await openSignIn(tester);

      expect(find.text('AB12'), findsOneWidget);
      expect(find.textContaining('plex.tv/link'), findsOneWidget);

      // Several polls later, an operator who mistyped it can still read it.
      await tester.pump(_aPoll);
      await tester.pump(_aPoll);
      expect(find.text('AB12'), findsOneWidget);
      expect(sources.pinChecks, greaterThan(0));
    });

    testWidgets('approval with one server connects it without asking which',
        (tester) async {
      await openSignIn(tester);

      sources.approve();
      await tester.pump(_aPoll);
      await tester.pumpAndSettle();

      expect(sources.connected.single.machineIdentifier, 'server-uuid');
      expect(find.byType(PlexSignInDialog), findsNothing);
      expect(find.text('Home Server'), findsOneWidget);
    });

    testWidgets('more than one server means picking one', (tester) async {
      sources.servers = [
        fakeServer(id: 'a', name: 'Booth NAS'),
        fakeServer(id: 'b', name: 'Studio', owned: false),
      ];
      await openSignIn(tester);

      sources.approve();
      await tester.pump(_aPoll);
      await tester.pumpAndSettle();

      expect(find.text('Which server?'), findsOneWidget);
      expect(find.text('Shared with you'), findsOneWidget);
      expect(sources.connected, isEmpty);

      await tester.tap(find.text('Booth NAS'));
      await tester.pumpAndSettle();

      expect(sources.connected.single.machineIdentifier, 'a');
    });

    testWidgets('polling stops once a token arrives', (tester) async {
      await openSignIn(tester);

      sources.approve();
      await tester.pump(_aPoll);
      await tester.pumpAndSettle();

      final checksAtConnect = sources.pinChecks;
      await tester.pump(_aPoll);
      await tester.pump(_aPoll);

      expect(sources.pinChecks, checksAtConnect);
    });

    testWidgets('an expired code is explained and can be restarted',
        (tester) async {
      sources.pinFailure = PlexAuthException('That code expired.');
      await openSignIn(tester);

      expect(find.text('That code expired.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(sources.pinRequests, 2);
      expect(find.text('AB12'), findsOneWidget);
    });

    testWidgets('cancelling stops the polling', (tester) async {
      await openSignIn(tester);
      final checksAtCancel = sources.pinChecks;

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.pump(_aPoll);
      await tester.pump(_aPoll);

      expect(find.byType(PlexSignInDialog), findsNothing);
      expect(sources.pinChecks, checksAtCancel);
    });
  });

  group('importing a library', () {
    setUp(() {
      sources.publish([FakeSources.accountFor(fakeServer())]);
    });

    /// [settle] is off while an import is deliberately held open: an
    /// indeterminate progress bar animates forever and `pumpAndSettle` would
    /// wait for it.
    Future<void> openImport(WidgetTester tester, {bool settle = true}) async {
      await pumpSources(tester);
      await tester.tap(find.byIcon(Icons.library_add_outlined));
      settle ? await tester.pumpAndSettle() : await tester.pump();
      if (!settle) await tester.pump();
    }

    testWidgets('one music library imports without asking which',
        (tester) async {
      await openImport(tester);

      expect(sources.importedSections, ['1']);
      expect(find.textContaining('3 added'), findsOneWidget);
      expect(find.textContaining('2 already there'), findsOneWidget);
    });

    testWidgets('more than one means picking one', (tester) async {
      sources.sections = const [
        PlexSection(key: '1', title: 'Music'),
        PlexSection(key: '2', title: 'Practice tracks'),
      ];
      await openImport(tester);

      expect(find.text('Which library?'), findsOneWidget);
      expect(sources.importedSections, isEmpty);

      await tester.tap(find.text('Practice tracks'));
      await tester.pumpAndSettle();

      expect(sources.importedSections, ['2']);
    });

    testWidgets('a server with no music libraries says so', (tester) async {
      sources.sections = const [];
      await openImport(tester);

      expect(find.textContaining('no music libraries'), findsOneWidget);
      expect(sources.importedSections, isEmpty);
    });

    testWidgets('a failure is shown rather than swallowed', (tester) async {
      sources.importFailure = StateError('server went away');
      await openImport(tester);

      expect(find.textContaining('server went away'), findsOneWidget);
    });

    testWidgets('there is no way out while it runs', (tester) async {
      // A half-imported library is one the operator cannot tell about, so
      // cancelling mid-import is not offered.
      sources.importGate = Completer<void>();
      await openImport(tester, settle: false);

      expect(_cancelButton(tester).onPressed, isNull);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      sources.importGate!.complete();
      await tester.pumpAndSettle();

      expect(_cancelButton(tester).onPressed, isNotNull);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('progress shows how far through the library it is',
        (tester) async {
      sources.importGate = Completer<void>();
      sources.importProgress = const [(200, 6000)];
      await openImport(tester, settle: false);

      expect(find.text('200 of 6000'), findsOneWidget);

      sources.importGate!.complete();
      await tester.pumpAndSettle();
    });
  });
}

TextButton _cancelButton(WidgetTester tester) => tester.widget<TextButton>(
      find.byType(TextButton).last,
    );
