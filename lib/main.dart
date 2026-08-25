import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/dance_type_seed.dart';
import 'data/db/connection.dart';
import 'data/db/database.dart';
import 'ui/screens/deck_screen.dart';
import 'ui/state/playback_runtime.dart';
import 'ui/state/playback_ui_state.dart';
import 'ui/theme/sayaw_theme.dart';
import 'ui/wakelock/playback_wakelock.dart';
import 'ui/window/window_controller.dart';

/// The database, opened once in [main] and handed to the widget tree.
final databaseProvider = Provider<SayawDatabase>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

/// Where rendered announcement audio is written.
final announcementCacheProvider = Provider<String>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // libmpv, behind the desktop decks. Has to happen before any Player exists.
  if (isDesktopWindowPlatform) MediaKit.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final db = openSayawDatabase();
  // Only fills in what is missing, so a renamed dance stays renamed.
  await seedDanceTypes(db);

  final support = await getApplicationSupportDirectory();
  final announcementCache = p.join(support.path, 'announcements');

  // Only desktop has a window to size, position or strip the title bar from.
  // On mobile the no-op backend keeps the same call sites valid rather than
  // guarding every one of them.
  final windows = WindowController(
    backend: isDesktopWindowPlatform
        ? const WindowManagerBackend()
        : const NoopWindowBackend(),
    prefs: prefs,
  );
  await windows.restore();

  runApp(
    ProviderScope(
      overrides: [
        windowControllerProvider.overrideWithValue(windows),
        databaseProvider.overrideWithValue(db),
        announcementCacheProvider.overrideWithValue(announcementCache),
      ],
      child: SayawApp(windows: windows),
    ),
  );
}

class SayawApp extends ConsumerWidget {
  const SayawApp({super.key, required this.windows});

  final WindowController windows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sayaw',
      debugShowCheckedModeBanner: false,
      theme: sayawDarkTheme(),
      darkTheme: sayawDarkTheme(),
      // Dark is not a preference here. These rooms have the house lights down,
      // and a white flash between screens is a genuine problem on a stage
      // monitor, so the system setting is deliberately ignored.
      themeMode: ThemeMode.dark,
      home: WindowGeometrySaver(
        controller: windows,
        child: const PlaybackWakelock(
          child: _PerformanceModeShortcuts(child: _Bootstrap()),
        ),
      ),
    );
  }
}

/// Builds the audio runtime and opens the set the app was last using.
///
/// Deliberately after the first frame: the deck screen draws its empty state
/// immediately rather than waiting on libmpv, a database read and a resolve of
/// every row in a four-hour set.
class _Bootstrap extends ConsumerStatefulWidget {
  const _Bootstrap();

  @override
  ConsumerState<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<_Bootstrap> {
  PlaybackRuntime? _runtime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final runtime = PlaybackRuntime.start(
        db: ref.read(databaseProvider),
        controller: ref.read(playbackProvider.notifier),
        announcementCacheDirectory: ref.read(announcementCacheProvider),
      );
      _runtime = runtime;
      await runtime.openMostRecentPlaylist();
    });
  }

  @override
  void dispose() {
    _runtime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const DeckScreen();
}

/// F11 toggles Performance Mode, Escape leaves it.
///
/// Escape is the one a panicking operator will reach for, so it only ever
/// exits — never enters — and it is deliberately not the *only* way out. The
/// touch affordance in the app bar covers the tablet case, where there is no
/// function-key row at all.
class _PerformanceModeShortcuts extends ConsumerWidget {
  const _PerformanceModeShortcuts({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> setMode(bool enabled) => ref
        .read(windowControllerProvider)
        .setPerformanceMode(enabled, ref.read(playbackProvider.notifier));

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f11): () {
          setMode(!ref.read(playbackProvider).performanceMode);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (ref.read(playbackProvider).performanceMode) setMode(false);
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
