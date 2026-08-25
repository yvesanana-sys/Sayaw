import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../state/playback_ui_state.dart';

/// Smallest window we are willing to lay out. Below this the compact layout
/// starts clipping the transport bar, and a DJ who has accidentally dragged the
/// window to nothing cannot get it back without a mouse.
const Size kMinimumWindowSize = Size(640, 480);

const Size kDefaultWindowSize = Size(1280, 800);

/// The window operations this app performs, behind an interface.
///
/// `window_manager` talks to a real Win32 window. In a widget test there is no
/// such window and every call throws on the platform channel, so the seam is
/// here rather than in a `Platform.isWindows` check sprinkled through the UI.
abstract class WindowBackend {
  Future<void> ensureInitialized();
  Future<void> setMinimumSize(Size size);
  Future<void> setBounds(Rect bounds);
  Future<Rect> getBounds();
  Future<void> setTitleBarStyle(bool hidden);
  Future<void> setFullScreen(bool fullScreen);
  Future<void> show();
}

class WindowManagerBackend implements WindowBackend {
  const WindowManagerBackend();

  @override
  Future<void> ensureInitialized() => windowManager.ensureInitialized();

  @override
  Future<void> setMinimumSize(Size size) => windowManager.setMinimumSize(size);

  @override
  Future<void> setBounds(Rect bounds) => windowManager.setBounds(bounds);

  @override
  Future<Rect> getBounds() => windowManager.getBounds();

  @override
  Future<void> setTitleBarStyle(bool hidden) => windowManager.setTitleBarStyle(
        hidden ? TitleBarStyle.hidden : TitleBarStyle.normal,
      );

  @override
  Future<void> setFullScreen(bool fullScreen) =>
      windowManager.setFullScreen(fullScreen);

  @override
  Future<void> show() => windowManager.show();
}

/// Used on mobile, in tests, and anywhere there is no desktop window to drive.
class NoopWindowBackend implements WindowBackend {
  const NoopWindowBackend();

  @override
  Future<void> ensureInitialized() async {}
  @override
  Future<void> setMinimumSize(Size size) async {}
  @override
  Future<void> setBounds(Rect bounds) async {}
  @override
  Future<Rect> getBounds() async => Offset.zero & kDefaultWindowSize;
  @override
  Future<void> setTitleBarStyle(bool hidden) async {}
  @override
  Future<void> setFullScreen(bool fullScreen) async {}
  @override
  Future<void> show() async {}
}

/// Where the window was last time, and whether we are in Performance Mode.
class WindowController {
  WindowController({required this.backend, required this.prefs});

  final WindowBackend backend;
  final SharedPreferences? prefs;

  static const _kX = 'window.x';
  static const _kY = 'window.y';
  static const _kWidth = 'window.width';
  static const _kHeight = 'window.height';

  bool _performanceMode = false;
  bool get performanceMode => _performanceMode;

  /// Applies the minimum size and restores the saved geometry, then shows the
  /// window. Called once from `main()` before `runApp`.
  Future<void> restore() async {
    await backend.ensureInitialized();
    await backend.setMinimumSize(kMinimumWindowSize);

    final saved = _savedBounds();
    if (saved != null) await backend.setBounds(saved);

    await backend.show();
  }

  Rect? _savedBounds() {
    final store = prefs;
    if (store == null) return null;

    final width = store.getDouble(_kWidth);
    final height = store.getDouble(_kHeight);
    if (width == null || height == null) return null;

    // A saved size below the minimum means the preference file predates a
    // minimum-size change, or was hand-edited. Clamp rather than refuse:
    // a window that will not open is worse than one that opens too big.
    final size = Size(
      width.clamp(kMinimumWindowSize.width, double.infinity),
      height.clamp(kMinimumWindowSize.height, double.infinity),
    );

    return Offset(store.getDouble(_kX) ?? 0, store.getDouble(_kY) ?? 0) & size;
  }

  /// Records the current geometry. Called on resize, move, and close.
  ///
  /// Skipped while in Performance Mode: fullscreen bounds are the monitor, not
  /// a window the operator chose, and saving them means the app opens
  /// fullscreen forever after one performance.
  Future<void> saveBounds() async {
    final store = prefs;
    if (store == null || _performanceMode) return;

    final bounds = await backend.getBounds();
    await store.setDouble(_kX, bounds.left);
    await store.setDouble(_kY, bounds.top);
    await store.setDouble(_kWidth, bounds.width);
    await store.setDouble(_kHeight, bounds.height);
  }

  /// Borderless fullscreen for a projector or a stage monitor.
  ///
  /// Order matters on Windows: dropping the title bar before going fullscreen
  /// avoids a frame where the window is fullscreen *and* decorated, which
  /// flashes a white bar across the top of the projector.
  Future<void> setPerformanceMode(
    bool enabled,
    PlaybackController playback,
  ) async {
    if (_performanceMode == enabled) return;

    if (enabled) await saveBounds();

    _performanceMode = enabled;
    playback.setPerformanceMode(enabled);

    await backend.setTitleBarStyle(enabled);
    await backend.setFullScreen(enabled);

    if (!enabled) {
      final saved = _savedBounds();
      if (saved != null) await backend.setBounds(saved);
    }
  }
}

/// True where `window_manager` has a real window to drive.
bool get isDesktopWindowPlatform =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// Overridden in `main()` with a controller built against the real backend,
/// and in tests with one built against [NoopWindowBackend].
final windowControllerProvider = Provider<WindowController>(
  (ref) => throw UnimplementedError(
    'windowControllerProvider must be overridden in ProviderScope',
  ),
);

/// Persists window geometry as the operator drags the window around.
///
/// A [WindowListener] rather than a save on close: Windows can terminate an app
/// without a clean shutdown, and losing the window position every time that
/// happens is a small papercut that shows up at every single event.
class WindowGeometrySaver extends StatefulWidget {
  const WindowGeometrySaver({
    super.key,
    required this.controller,
    required this.child,
  });

  final WindowController controller;
  final Widget child;

  @override
  State<WindowGeometrySaver> createState() => _WindowGeometrySaverState();
}

class _WindowGeometrySaverState extends State<WindowGeometrySaver>
    with WindowListener {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (isDesktopWindowPlatform) windowManager.addListener(this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (isDesktopWindowPlatform) windowManager.removeListener(this);
    super.dispose();
  }

  /// A drag emits a resize event per frame; writing preferences at 60 Hz would
  /// hammer the disk the library database is on.
  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 500),
      widget.controller.saveBounds,
    );
  }

  @override
  void onWindowResized() => _scheduleSave();

  @override
  void onWindowMoved() => _scheduleSave();

  @override
  void onWindowClose() => unawaited(widget.controller.saveBounds());

  @override
  Widget build(BuildContext context) => widget.child;
}
