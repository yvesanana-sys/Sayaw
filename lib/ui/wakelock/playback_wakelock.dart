import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../state/playback_ui_state.dart';

/// Keeps the display awake, behind an interface so tests do not need a
/// platform channel.
abstract class WakelockBackend {
  Future<void> enable();
  Future<void> disable();
}

class WakelockPlusBackend implements WakelockBackend {
  const WakelockPlusBackend();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}

/// Records calls instead of making them. Used by tests, and by any platform
/// where holding a wakelock is meaningless.
class RecordingWakelockBackend implements WakelockBackend {
  final List<bool> calls = [];

  bool get isEnabled => calls.isNotEmpty && calls.last;

  @override
  Future<void> enable() async => calls.add(true);

  @override
  Future<void> disable() async => calls.add(false);
}

final wakelockBackendProvider = Provider<WakelockBackend>(
  (ref) => const WakelockPlusBackend(),
);

/// Holds a wakelock for exactly as long as a deck is playing.
///
/// A tablet dimming and sleeping at a social night is a show-stopper — Windows
/// will suspend the display on its own idle timer no matter that audio is
/// coming out of it, because nothing about our playback counts as user
/// activity. Equally, holding the lock forever drains a tablet that is sitting
/// idle between sets, so it is released the moment both decks stop.
///
/// Drop this anywhere under the [ProviderScope]; it renders [child] unchanged.
class PlaybackWakelock extends ConsumerStatefulWidget {
  const PlaybackWakelock({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PlaybackWakelock> createState() => _PlaybackWakelockState();
}

class _PlaybackWakelockState extends ConsumerState<PlaybackWakelock> {
  bool _held = false;

  /// Cached because `dispose` cannot touch `ref` — Riverpod has already torn
  /// the element down by then, and releasing the lock is exactly the thing
  /// that must still happen at that point.
  WakelockBackend? _backend;

  @override
  void initState() {
    super.initState();
    // `WidgetRef.listen` has no `fireImmediately`, so seed from the current
    // value. Deferred off the build phase because acquiring the lock is a
    // platform call.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _apply(ref.read(anyDeckPlayingProvider));
    });
  }

  @override
  void dispose() {
    // Releasing on dispose rather than leaving it to the OS: a hot restart in
    // development otherwise leaves the lock held with nothing to release it.
    // `_held` can only be true once `_apply` has cached the backend.
    if (_held) {
      // Same reasoning, and the same platform: this runs during teardown,
      // where an exception is even less use to anybody.
      try {
        _backend?.disable();
      } on Object {
        // Nothing left to do about it.
      }
    }
    super.dispose();
  }

  Future<void> _apply(bool shouldHold) async {
    if (_held == shouldHold) return;
    _held = shouldHold;

    final backend = _backend ??= ref.read(wakelockBackendProvider);

    try {
      if (shouldHold) {
        await backend!.enable();
      } else {
        await backend!.disable();
      }
    } on Object {
      // A wakelock that cannot be taken is a screen that may sleep, which is
      // a worse night and not a broken one. Nothing here is worth taking the
      // app down for, and `listen` gives this nowhere to return an error to —
      // it would be an unhandled async error the operator never sees.
      //
      // Found by running it: on Linux `wakelock_plus` goes over DBus, and a
      // machine with no session bus threw the moment playback started.
      _held = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // `listen` rather than `watch`: acquiring a wakelock is a side effect, and
    // it must not run during build.
    ref.listen<bool>(
      anyDeckPlayingProvider,
      (_, playing) => _apply(playing),
    );

    return widget.child;
  }
}
