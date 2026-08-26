import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/media_resolver.dart';
import 'package:sayaw/ui/screens/deck_screen.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/widgets/network_banner.dart';

import 'harness.dart';

void main() {
  /// Pumps the banner alone and puts the app into [mode].
  Future<void> pumpBanner(
    WidgetTester tester,
    NetworkMode mode, {
    List<String> services = const [],
  }) async {
    final container = await pumpSayaw(
      tester,
      const Scaffold(body: NetworkBanner()),
    );
    container
        .read(playbackProvider.notifier)
        .setNetworkMode(mode, offlineServices: services);
    await tester.pumpAndSettle();
  }

  testWidgets('nothing at all while everything is reachable', (tester) async {
    await pumpBanner(tester, NetworkMode.online);

    expect(find.byType(Text), findsNothing);
    expect(tester.getSize(find.byType(NetworkBanner)).height, 0);
  });

  testWidgets('offline says so, and says what still works', (tester) async {
    // The second half is the half that matters at 11pm: whether the night is
    // over or merely narrower.
    await pumpBanner(tester, NetworkMode.localOnly);

    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.textContaining('Local files and downloads still play'),
        findsOneWidget);
  });

  testWidgets('names the server that went, not just "Plex"', (tester) async {
    await pumpBanner(tester, NetworkMode.localOnly, services: ['Home Server']);

    expect(find.textContaining('Home Server is not reachable'), findsOneWidget);
  });

  testWidgets('degraded names what is down and reassures about the rest',
      (tester) async {
    await pumpBanner(tester, NetworkMode.degraded, services: ["Marta's Library"]);

    expect(find.textContaining("Marta's Library is not reachable"),
        findsOneWidget);
    expect(find.textContaining('Everything else plays normally'),
        findsOneWidget);
  });

  testWidgets('two servers are both named', (tester) async {
    await pumpBanner(
      tester,
      NetworkMode.localOnly,
      services: ['Home Server', 'Studio NAS'],
    );

    expect(find.textContaining('Home Server and Studio NAS are not reachable'),
        findsOneWidget);
  });

  testWidgets('more than two are counted rather than listed', (tester) async {
    // A rack of servers would push the transport controls off a compact
    // layout. The count is enough to send the operator to the sources screen.
    await pumpBanner(
      tester,
      NetworkMode.localOnly,
      services: ['One', 'Two', 'Three', 'Four'],
    );

    expect(find.textContaining('4 servers are not reachable'), findsOneWidget);
  });

  testWidgets('a screen reader is told without being asked', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpBanner(tester, NetworkMode.localOnly, services: ['Home Server']);

    expect(
      tester.getSemantics(find.byType(NetworkBanner)),
      matchesSemantics(
        label: 'Offline — Home Server is not reachable. '
            'Local files and downloads still play.',
        isLiveRegion: true,
      ),
    );
    handle.dispose();
  });

  group('on the deck screen', () {
    for (final (name, size) in const [
      ('compact', kCompactSize),
      ('medium', kMediumSize),
      ('expanded', kExpandedSize),
    ]) {
      testWidgets('$name: above the panes, so it survives Performance Mode',
          (tester) async {
        // There is no app bar to put it in when the title bar is gone, and in
        // a compact layout it has to show whichever pane is selected.
        final container = await pumpSayaw(
          tester,
          const DeckScreen(),
          size: size,
          queue: testQueue(),
        );

        expect(find.byType(NetworkBanner), findsOneWidget);
        expect(find.textContaining('Offline'), findsNothing);

        container.read(playbackProvider.notifier)
          ..setPerformanceMode(true)
          ..setNetworkMode(NetworkMode.localOnly,
              offlineServices: ['Home Server']);
        await tester.pumpAndSettle();

        expect(find.textContaining('Home Server'), findsOneWidget);
      });
    }
  });
}
