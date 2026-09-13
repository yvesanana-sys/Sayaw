import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/dance_type_seed.dart';
import 'data/jack_and_jill_service.dart';
import 'data/soundboard_service.dart';
import 'data/db/connection.dart';
import 'data/db/database.dart';
import 'data/sources/plex/plex_identity.dart';
import 'ui/screens/deck_screen.dart';
import 'ui/state/playback_runtime.dart';
import 'ui/state/jack_and_jill_provider.dart';
import 'ui/state/soundboard_provider.dart';
import 'ui/state/sources_provider.dart';
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

/// Where downloaded media is written.
final mediaCacheProvider = Provider<String>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

/// How this install identifies itself to plex.tv.
final plexIdentityProvider = Provider<PlexIdentity>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

/// Generated once and kept: plex.tv ties the approved PIN, and every token
/// minted from it, to this identifier. Losing it means signing in again.
const _plexClientIdKey = 'sayaw.plex.clientIdentifier';

Future<PlexIdentity> _plexIdentity(SharedPreferences prefs) async {
  var id = prefs.getString(_plexClientIdKey);
  if (id == null) {
    id = newId();
    await prefs.setString(_plexClientIdKey, id);
  }
  return PlexIdentity(
    clientIdentifier: id,
    version: _appVersion,
    // Shown in Authorized Devices on plex.tv, so it wants to read as the
    // machine in the DJ booth rather than as a generic app name.
    deviceName: Platform.localHostname,
    platform: Platform.operatingSystem,
  );
}

const _appVersion = '1.0.0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // libmpv, behind the desktop decks. Has to happen before any Player exists.
  if (isDesktopWindowPlatform) MediaKit.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final db = openSayawDatabase();
  // Only fills in what is missing, so a renamed dance stays renamed.
  await seedDanceTypes(db);

  final plexIdentity = await _plexIdentity(prefs);

  final support = await getApplicationSupportDirectory();
  final announcementCache = p.join(support.path, 'announcements');
  final mediaCache = p.join(support.path, 'media');

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
        mediaCacheProvider.overrideWithValue(mediaCache),
        plexIdentityProvider.overrideWithValue(plexIdentity),
      ],
      child: SayawApp(windows: windows),
    ),
  );
}

/// Every pointer drags.
class SayawScrollBehavior extends MaterialScrollBehavior {
  const SayawScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
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
      // A drag scrolls, whatever is doing the dragging. Flutter's desktop
      // default lets only a wheel scroll a list, so a hand on a laptop
      // trackpad or a touchscreen — or a mouse, dragged the way every list
      // on a phone is dragged — reached the ninth cue and stopped, with
      // nothing on screen to say there were more.
      scrollBehavior: const SayawScrollBehavior(),
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
  SoundboardService? _soundboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final runtime = PlaybackRuntime.start(
        db: ref.read(databaseProvider),
        controller: ref.read(playbackProvider.notifier),
        announcementCacheDirectory: ref.read(announcementCacheProvider),
        mediaCacheDirectory: ref.read(mediaCacheProvider),
        plexIdentity: ref.read(plexIdentityProvider),
      );
      _runtime = runtime;
      ref.read(sourcesHolderProvider.notifier).set(runtime.sources);
      _soundboard = SoundboardService(
        board: runtime.soundboard,
        db: runtime.db,
      );
      ref.read(soundboardHolderProvider.notifier).set(_soundboard);
      ref
          .read(jackAndJillHolderProvider.notifier)
          .set(JackAndJillService(db: runtime.db, library: runtime.session));

      // Before the set is opened: on Android this is the foreground service,
      // and starting it after a four-hour playlist has finished resolving is
      // four hours of resolving during which the OS may reclaim the app.
      await runtime.startMediaSession();

      await runtime.openMostRecentPlaylist();
    });
  }

  @override
  void dispose() {
    _soundboard?.dispose();
    _runtime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const DeckScreen();
}

/// The digits, bound to the first nine soundboard cues.
///
/// Here rather than on the deck screen because this is the widget that owns
/// the autofocus node: `CallbackShortcuts` is consulted by walking *up* from
/// whatever has focus, so bindings placed below it would simply never fire.
Map<ShortcutActivator, VoidCallback> _soundboardBindings(WidgetRef ref) {
  final soundboard = ref.watch(soundboardProvider);
  final cues = ref.watch(soundCuesProvider).value ?? const [];
  if (soundboard == null) return const {};

  const digits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  return {
    for (var i = 0; i < cues.length && i < digits.length; i++)
      SingleActivator(digits[i]): () => soundboard.fire(cues[i]),
  };
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
        ..._soundboardBindings(ref),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
