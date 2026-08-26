import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/connectivity.dart';
import 'package:sayaw/data/media_resolver.dart';

import '../fakes/fake_network.dart';

void main() {
  late FakeRadio radio;

  setUp(() => radio = FakeRadio());
  tearDown(() => radio.close());

  ConnectivityService serviceWith(
    List<ServiceProbe> probes, {
    Duration interval = const Duration(hours: 1),
  }) {
    final service = ConnectivityService(
      radio: radio,
      probes: probes,
      interval: interval,
    );
    addTearDown(service.dispose);
    return service;
  }

  group('deciding the mode', () {
    test('optimistic until the first probe answers', () {
      // Starting at localOnly would make every launch open its first set as if
      // offline and mislabel every streamed row until the probe returns.
      expect(serviceWith(const []).mode, NetworkMode.online);
    });

    test('no radio is localOnly, without probing anything', () async {
      radio.up = false;
      final probe = FakeProbe({'Home Server': true});

      expect(await serviceWith([probe]).refresh(), NetworkMode.localOnly);

      // Each probe would be a timeout, and they are seconds the operator
      // spends looking at a spinner for an answer already known.
      expect(probe.probes, 0);
    });

    test('a link and nothing signed in is online', () async {
      // A rig with only local files is not offline. It has nothing to be
      // offline *from*.
      expect(await serviceWith([FakeProbe({})]).refresh(), NetworkMode.online);
    });

    test('every service answering is online', () async {
      final service = serviceWith([
        FakeProbe({'Home Server': true, 'Studio NAS': true}),
      ]);

      expect(await service.refresh(), NetworkMode.online);
      expect(service.unreachable, isEmpty);
    });

    test('one of two down is degraded, and names the one that went', () async {
      // Which server matters: only one of them has tonight's music on it.
      final service = serviceWith([
        FakeProbe({'Home Server': true, "Marta's Library": false}),
      ]);

      expect(await service.refresh(), NetworkMode.degraded);
      expect(service.unreachable, ["Marta's Library"]);
    });

    test('a captive portal reads as localOnly, not as a working network',
        () async {
      // The radio associated, took a lease and passes nothing. This is the
      // failure the class exists for: every OS API calls it "connected".
      final service = serviceWith([
        FakeProbe({'Home Server': false, 'Studio NAS': false}),
      ]);

      expect(await service.refresh(), NetworkMode.localOnly);
      expect(service.unreachable, ['Home Server', 'Studio NAS']);
    });

    test('the only server being down is localOnly, not degraded', () async {
      // Nothing streamable is left, so there is no point letting the resolver
      // keep trying and paying a timeout per track.
      final service = serviceWith([
        FakeProbe({'Home Server': false}),
      ]);

      expect(await service.refresh(), NetworkMode.localOnly);
    });

    test('probes from several providers are combined', () async {
      final service = serviceWith([
        FakeProbe({'Home Server': true}),
        FakeProbe({'TIDAL': false}),
      ]);

      expect(await service.refresh(), NetworkMode.degraded);
      expect(service.unreachable, ['TIDAL']);
    });
  });

  group('telling the rest of the app', () {
    test('emits on a transition', () async {
      final probe = FakeProbe({'Home Server': true});
      final service = serviceWith([probe]);

      final seen = <NetworkMode>[];
      service.changes.listen(seen.add);

      await service.refresh();
      probe.services['Home Server'] = false;
      await service.refresh();
      probe.services['Home Server'] = true;
      await service.refresh();

      await pumpEventQueue();
      expect(seen, [NetworkMode.localOnly, NetworkMode.online]);
    });

    test('a probe that confirms what was already true says nothing', () async {
      // The banner is above every layout. Rebuilding it every thirty seconds
      // for the length of an event is not free.
      final service = serviceWith([
        FakeProbe({'Home Server': false}),
      ]);

      final seen = <NetworkMode>[];
      service.changes.listen(seen.add);

      await service.refresh();
      await service.refresh();
      await service.refresh();

      await pumpEventQueue();
      expect(seen, [NetworkMode.localOnly]);
    });
  });

  group('when it looks', () {
    test('the radio changing triggers a probe', () async {
      final probe = FakeProbe({'Home Server': true});
      final service = serviceWith([probe]);
      await service.start();

      expect(probe.probes, 1);

      radio.announce(false);
      await pumpEventQueue();

      expect(service.mode, NetworkMode.localOnly);
    });

    test('polls on its own while nothing else changes', () async {
      // The quiet failures — a server rebooting, a portal session expiring —
      // arrive with no radio event at all.
      final probe = FakeProbe({'Home Server': true});
      final service = serviceWith(
        [probe],
        interval: const Duration(milliseconds: 20),
      );
      await service.start();

      probe.services['Home Server'] = false;
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(service.mode, NetworkMode.localOnly);
    });

    test('overlapping refreshes share one round of requests', () async {
      // The radio fires while a poll is in flight — that is exactly when it
      // fires. A second round would only make the answer arrive later.
      final probe = FakeProbe({'Home Server': true})..gate = Completer<void>();
      final service = serviceWith([probe]);

      final first = service.refresh();
      final second = service.refresh();
      probe.release();

      expect(await first, NetworkMode.online);
      expect(await second, NetworkMode.online);
      expect(probe.probes, 1);

      // And the next one is a fresh look, not the shared answer again.
      probe.services['Home Server'] = false;
      expect(await service.refresh(), NetworkMode.localOnly);
    });

    test('stops looking once disposed', () async {
      final probe = FakeProbe({'Home Server': true});
      final service = ConnectivityService(
        radio: radio,
        probes: [probe],
        interval: const Duration(milliseconds: 20),
      );
      await service.start();
      await service.dispose();

      final after = probe.probes;
      radio.announce(false);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(probe.probes, after);
    });
  });
}
