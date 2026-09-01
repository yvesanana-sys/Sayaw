import 'dart:async';
import 'dart:io';

import 'package:sayaw/data/connectivity.dart';

/// A radio a test drives by hand.
class FakeRadio implements NetworkRadio {
  FakeRadio({this.up = true});

  bool up;

  /// Makes [hasNetwork] throw, as a machine with no NetworkManager on the bus
  /// does.
  bool throws = false;

  /// How many times the service asked. The point of several assertions is that
  /// this stays small.
  int checks = 0;

  final _events = StreamController<bool>.broadcast();

  @override
  Future<bool> hasNetwork() async {
    checks++;
    if (throws) throw const SocketException('no bus');
    return up;
  }

  @override
  Stream<bool> get onChanged => _events.stream;

  /// Flips the radio and tells anyone listening, the way the OS would.
  void announce(bool nowUp) {
    up = nowUp;
    _events.add(nowUp);
  }

  Future<void> close() => _events.close();
}

/// A service that answers however the test says, and counts being asked.
class FakeProbe implements ServiceProbe {
  FakeProbe(this.services);

  /// Name to reachability. Mutate mid-test to take a server away.
  final Map<String, bool> services;

  int probes = 0;

  /// Held open until [release] is called, for asserting that overlapping
  /// refreshes share one round of requests.
  Completer<void>? gate;

  @override
  Future<List<ServiceReachability>> probe() async {
    probes++;
    if (gate case final gate?) await gate.future;

    return [
      for (final entry in services.entries)
        ServiceReachability(name: entry.key, reachable: entry.value),
    ];
  }

  void release() {
    gate?.complete();
    gate = null;
  }
}
