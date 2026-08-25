import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/sources/plex/plex_auth.dart';
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
    sources = FakeSources(servers: [fakeServer()]);
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
      expect(find.text('plex'), findsOneWidget);
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
}
