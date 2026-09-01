import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'media_resolver.dart' show NetworkMode;

/// What the operating system believes the radio is doing.
///
/// Behind an interface for two reasons: a widget test has no platform channels
/// to ask, and the answer is wrong often enough that [ConnectivityService]
/// never acts on it alone.
abstract class NetworkRadio {
  /// True when the OS believes there is *a* link. Not a promise that anything
  /// is reachable over it.
  Future<bool> hasNetwork();

  /// Fires when the OS's answer changes.
  Stream<bool> get onChanged;
}

class ConnectivityPlusRadio implements NetworkRadio {
  ConnectivityPlusRadio([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hasNetwork() async {
    try {
      return _isUp(await _connectivity.checkConnectivity());
    } on Object {
      // The OS would not answer. On Linux that is a machine with no
      // NetworkManager on the bus, and on any platform it can be a plugin
      // that is not there — neither is a reason to declare the night offline.
      //
      // True rather than false, because the probes are the real test and can
      // answer this without help. Saying false here would skip them and take
      // a rig with a working network into local-only for the whole event.
      return true;
    }
  }

  @override
  Stream<bool> get onChanged => _connectivity.onConnectivityChanged
      .map(_isUp)
      // An error here would cancel the subscription and stop the app ever
      // noticing a network change again. The poll is still running; this just
      // has nothing to add.
      .handleError((Object _) {})
      .distinct();

  /// The plugin documents `none` as the only value that ever appears alone, so
  /// anything else in the list is a link of some kind. Which kind it is does
  /// not matter here — cellular and wifi fail in the same way for our purposes,
  /// and the probe is what decides.
  static bool _isUp(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}

/// One configured service, and whether it answered.
class ServiceReachability {
  const ServiceReachability({required this.name, required this.reachable});

  /// As the operator named it — 'Studio NAS', not a machine identifier. This
  /// ends up in a banner they read on stage.
  final String name;

  final bool reachable;
}

/// Asks one kind of service whether it is actually there.
///
/// One implementation per provider, so adding TIDAL later is adding a probe
/// rather than reworking the state machine.
abstract class ServiceProbe {
  /// Every configured account of this kind, with a live answer for each.
  ///
  /// Empty when none is signed in. That is not the same as unreachable and
  /// must not read as offline: a rig with only local files is perfectly online.
  Future<List<ServiceReachability>> probe();
}

/// Whether the set can reach the services it was built against.
///
/// The reason this is not just `connectivity_plus`: venue wifi routinely
/// associates, hands out a DHCP lease, answers the captive portal's own DNS
/// and passes no other traffic at all. Every OS-level API reports that as
/// "connected". Combining the radio with a real request against each
/// configured server is the only way to tell it from a working network, and
/// getting it wrong means the engine spends the first transition of the night
/// waiting on a socket that will never open.
///
/// `Online → Degraded (something is down) → LocalOnly (nothing is)`.
class ConnectivityService {
  ConnectivityService({
    required this.radio,
    required this.probes,
    this.interval = const Duration(seconds: 30),
  });

  final NetworkRadio radio;
  final List<ServiceProbe> probes;

  /// How often to ask again while nothing else has changed.
  ///
  /// A radio event covers the abrupt failures — the AP dropping, the cable
  /// coming out. This covers the quiet ones, which are the more common kind in
  /// a venue: the server rebooting, the uplink saturating, the portal session
  /// timing out after an hour.
  final Duration interval;

  /// Optimistic until the first probe answers.
  ///
  /// The alternative is starting at [NetworkMode.localOnly], which would make
  /// the app open its first set as if offline on every launch and mislabel
  /// every streamed row for as long as the probe takes.
  NetworkMode _mode = NetworkMode.online;
  NetworkMode get mode => _mode;

  List<String> _unreachable = const [];

  /// Configured services that are not answering, by name. Empty when the radio
  /// itself is down — there is nothing to single out.
  List<String> get unreachable => _unreachable;

  final _changes = StreamController<NetworkMode>.broadcast();

  /// Fires on transitions only, never on a probe that confirms what was
  /// already true.
  Stream<NetworkMode> get changes => _changes.stream;

  Timer? _poll;
  StreamSubscription<bool>? _radioEvents;
  Future<NetworkMode>? _inFlight;

  Future<NetworkMode> start() async {
    // Subscribing is itself something the radio can die inside of, so it goes
    // through the same containment as everything else it does.
    await _contained(() async {
      _radioEvents = radio.onChanged.listen(
        (_) => refresh(),
        onError: (Object _) {},
      );
    });

    _poll = Timer.periodic(interval, (_) => refresh());
    return refresh();
  }

  /// Runs [body] with anything the radio raises kept inside.
  ///
  /// `connectivity_plus` on Linux reaches NetworkManager over DBus, and where
  /// that is not listening it raises the socket failure *into the zone* rather
  /// than returning it — so a `try`/`catch` around the await never sees it and
  /// the app dies at startup with an unhandled exception. Found by running the
  /// thing rather than by reading it.
  ///
  /// The radio is an optimisation and never an authority: all it does is save
  /// a round of probes when there is obviously no link. Losing it costs those
  /// probes and nothing else, which is why swallowing this is the right trade
  /// rather than a shrug.
  Future<void> _contained(Future<void> Function() body) {
    final done = Completer<void>();

    runZonedGuarded(
      () async {
        try {
          await body();
        } finally {
          if (!done.isCompleted) done.complete();
        }
      },
      (_, _) {
        if (!done.isCompleted) done.complete();
      },
    );

    return done.future;
  }

  /// Probes now rather than waiting for the next tick.
  ///
  /// Overlapping calls share one probe. The radio firing while a poll is
  /// already in flight is routine — that is exactly when it fires — and racing
  /// two rounds of requests against the same server would only make the answer
  /// arrive later.
  Future<NetworkMode> refresh() =>
      _inFlight ??= _guarded().whenComplete(() => _inFlight = null);

  /// One probe, with nothing allowed out of it.
  ///
  /// [start] is deliberately not awaited by its caller and the poll timer has
  /// nowhere to return an error to, so anything thrown here is an unhandled
  /// async error — and the service stops polling for the rest of the night.
  /// A round that cannot be completed simply leaves the mode where it was.
  Future<NetworkMode> _guarded() async {
    try {
      return await _refresh();
    } on Object {
      return _mode;
    }
  }

  Future<void> dispose() async {
    _poll?.cancel();
    _poll = null;
    await _radioEvents?.cancel();
    _radioEvents = null;
    await _changes.close();
  }

  // ---------------------------------------------------------------------

  Future<NetworkMode> _refresh() async {
    if (!await _radioSaysUp()) {
      // No link at all. Probing would be one timeout per server and the same
      // answer at the end of it, and those timeouts are seconds the operator
      // spends looking at a spinner.
      return _settle(NetworkMode.localOnly, const []);
    }

    // In parallel: one slow server must not delay the verdict on the others,
    // and each probe is already bounded in time.
    final results = await Future.wait([for (final probe in probes) probe.probe()]);
    final services = [for (final result in results) ...result];

    // A link, and nothing signed in to be wrong about. Local files play, and
    // there is no server to declare down.
    if (services.isEmpty) return _settle(NetworkMode.online, const []);

    final down = [
      for (final service in services)
        if (!service.reachable) service.name,
    ];

    if (down.isEmpty) return _settle(NetworkMode.online, const []);

    // Everything unreachable while the OS insists there is a network is the
    // captive portal this class exists for. Calling it degraded would leave
    // the resolver trying, and every attempt costs a timeout.
    if (down.length == services.length) {
      return _settle(NetworkMode.localOnly, down);
    }

    return _settle(NetworkMode.degraded, down);
  }

  /// What the radio thinks, or "there is a link" when it cannot be asked.
  ///
  /// True rather than false on failure, because the probes are the real test
  /// and can answer without it. False would skip them and take a rig with a
  /// working network into local-only for the whole event.
  Future<bool> _radioSaysUp() async {
    var up = true;
    await _contained(() async => up = await radio.hasNetwork());
    return up;
  }

  NetworkMode _settle(NetworkMode mode, List<String> down) {
    _unreachable = List.unmodifiable(down);

    if (mode != _mode) {
      _mode = mode;
      if (!_changes.isClosed) _changes.add(mode);
    }
    return mode;
  }
}
