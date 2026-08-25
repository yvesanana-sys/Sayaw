import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/theme/sayaw_theme.dart';
import 'package:sayaw/ui/wakelock/playback_wakelock.dart';
import 'package:sayaw/ui/window/window_controller.dart';

/// Representative window sizes, one per breakpoint.
///
/// Chosen to be plausible hardware rather than round numbers: a 10-inch tablet
/// held in portrait, the same tablet docked in landscape, and a 15-inch laptop.
const Size kCompactSize = Size(600, 1000);
const Size kMediumSize = Size(900, 700);
const Size kExpandedSize = Size(1400, 900);

/// Everything a Sayaw widget needs to render in a test: the real theme, a
/// [ProviderScope] with the platform-touching providers stubbed, and a window
/// of a known size.
/// Returns the container so a test can assert on state directly rather than
/// inferring it from what happens to be painted.
Future<ProviderContainer> pumpSayaw(
  WidgetTester tester,
  Widget child, {
  Size size = kExpandedSize,
  List<QueueItemUi> queue = const [],
  List<Override> overrides = const [],
  WakelockBackend? wakelock,
}) async {
  await setWindowSize(tester, size);

  final container = ProviderContainer(
    overrides: [
      windowControllerProvider.overrideWithValue(
        WindowController(backend: const NoopWindowBackend(), prefs: null),
      ),
      if (wakelock != null)
        wakelockBackendProvider.overrideWithValue(wakelock),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  if (queue.isNotEmpty) {
    container.read(playbackProvider.notifier).setQueue(queue);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: sayawDarkTheme(),
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

/// Resizes the test window, restoring the default when the test ends.
Future<void> setWindowSize(WidgetTester tester, Size size) async {
  const dpr = 1.0;
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = size * dpr;
  addTearDown(tester.view.reset);
}

/// A short set list covering the cases the UI has to handle: a normal track, a
/// track with a dance type, and one that cannot play on this platform.
List<QueueItemUi> testQueue() => const [
      QueueItemUi(
        id: 'q1',
        title: 'Kiss of Fire',
        artist: 'Georgia Gibbs',
        danceType: 'Tango',
        position: 1.0,
        duration: Duration(minutes: 2, seconds: 58),
      ),
      QueueItemUi(
        id: 'q2',
        title: 'Sway',
        artist: 'Dean Martin',
        danceType: 'Cha-Cha',
        position: 2.0,
        duration: Duration(minutes: 2, seconds: 42),
      ),
      QueueItemUi(
        id: 'q3',
        title: 'Obsesion',
        artist: 'Aventura',
        danceType: 'Bachata',
        position: 3.0,
        duration: Duration(minutes: 4, seconds: 8),
      ),
      QueueItemUi(
        id: 'q4',
        title: 'Smooth',
        artist: 'Santana',
        danceType: 'Rumba',
        position: 4.0,
        duration: Duration(minutes: 4, seconds: 56),
        unavailable: UnavailableReason.drmUnsupportedOnPlatform,
      ),
    ];
