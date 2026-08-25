import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/window/window_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the app asked of the window instead of driving a real one.
class FakeWindowBackend implements WindowBackend {
  Size? minimumSize;
  Rect bounds = const Rect.fromLTWH(0, 0, 1280, 800);
  bool? titleBarHidden;
  bool fullScreen = false;
  bool shown = false;

  final List<String> calls = [];

  @override
  Future<void> ensureInitialized() async => calls.add('init');

  @override
  Future<void> setMinimumSize(Size size) async {
    calls.add('minSize');
    minimumSize = size;
  }

  @override
  Future<void> setBounds(Rect value) async {
    calls.add('setBounds');
    bounds = value;
  }

  @override
  Future<Rect> getBounds() async => bounds;

  @override
  Future<void> setTitleBarStyle(bool hidden) async {
    calls.add('titleBar:$hidden');
    titleBarHidden = hidden;
  }

  @override
  Future<void> setFullScreen(bool value) async {
    calls.add('fullScreen:$value');
    fullScreen = value;
  }

  @override
  Future<void> show() async {
    calls.add('show');
    shown = true;
  }
}

Future<SharedPreferences> prefsWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('restore', () {
    test('applies the minimum size and shows the window', () async {
      final backend = FakeWindowBackend();
      final controller = WindowController(
        backend: backend,
        prefs: await prefsWith({}),
      );

      await controller.restore();

      expect(backend.minimumSize, kMinimumWindowSize);
      expect(backend.shown, isTrue);
      // Nothing saved yet, so the window keeps whatever geometry it opened with
      // rather than being forced somewhere arbitrary.
      expect(backend.calls, isNot(contains('setBounds')));
    });

    test('restores saved geometry', () async {
      final backend = FakeWindowBackend();
      final controller = WindowController(
        backend: backend,
        prefs: await prefsWith({
          'window.x': 120.0,
          'window.y': 60.0,
          'window.width': 1024.0,
          'window.height': 768.0,
        }),
      );

      await controller.restore();

      expect(backend.bounds, const Rect.fromLTWH(120, 60, 1024, 768));
    });

    test('clamps a saved size below the minimum rather than refusing to open',
        () async {
      final backend = FakeWindowBackend();
      final controller = WindowController(
        backend: backend,
        prefs: await prefsWith({
          'window.x': 0.0,
          'window.y': 0.0,
          'window.width': 200.0,
          'window.height': 150.0,
        }),
      );

      await controller.restore();

      expect(backend.bounds.width, kMinimumWindowSize.width);
      expect(backend.bounds.height, kMinimumWindowSize.height);
    });

    test('a half-written preference file is ignored, not fatal', () async {
      final backend = FakeWindowBackend();
      final controller = WindowController(
        backend: backend,
        // Position saved, size missing — a crash between the two writes.
        prefs: await prefsWith({'window.x': 40.0, 'window.y': 40.0}),
      );

      await controller.restore();

      expect(backend.calls, isNot(contains('setBounds')));
      expect(backend.shown, isTrue);
    });

    test('works with no preference store at all', () async {
      final backend = FakeWindowBackend();
      final controller = WindowController(backend: backend, prefs: null);

      await controller.restore();

      expect(backend.shown, isTrue);
      expect(backend.minimumSize, kMinimumWindowSize);
    });
  });

  group('saveBounds', () {
    test('records the current geometry', () async {
      final backend = FakeWindowBackend()
        ..bounds = const Rect.fromLTWH(10, 20, 900, 700);
      final prefs = await prefsWith({});
      final controller = WindowController(backend: backend, prefs: prefs);

      await controller.saveBounds();

      expect(prefs.getDouble('window.x'), 10);
      expect(prefs.getDouble('window.y'), 20);
      expect(prefs.getDouble('window.width'), 900);
      expect(prefs.getDouble('window.height'), 700);
    });
  });

  group('performance mode', () {
    late FakeWindowBackend backend;
    late WindowController controller;
    late ProviderContainer container;
    late PlaybackController playback;

    setUp(() async {
      backend = FakeWindowBackend()
        ..bounds = const Rect.fromLTWH(50, 50, 1000, 700);
      controller = WindowController(
        backend: backend,
        prefs: await prefsWith({}),
      );
      container = ProviderContainer();
      addTearDown(container.dispose);
      playback = container.read(playbackProvider.notifier);
    });

    test('goes borderless fullscreen and back', () async {
      await controller.setPerformanceMode(true, playback);

      expect(backend.titleBarHidden, isTrue);
      expect(backend.fullScreen, isTrue);
      expect(container.read(playbackProvider).performanceMode, isTrue);

      await controller.setPerformanceMode(false, playback);

      expect(backend.titleBarHidden, isFalse);
      expect(backend.fullScreen, isFalse);
      expect(container.read(playbackProvider).performanceMode, isFalse);
    });

    test('drops the title bar before going fullscreen', () async {
      await controller.setPerformanceMode(true, playback);

      final titleBar = backend.calls.indexOf('titleBar:true');
      final fullScreen = backend.calls.indexOf('fullScreen:true');

      expect(titleBar, greaterThanOrEqualTo(0));
      expect(
        titleBar,
        lessThan(fullScreen),
        reason: 'a decorated fullscreen frame flashes a white bar across the '
            'top of the projector',
      );
    });

    test('restores the pre-performance window geometry on exit', () async {
      await controller.setPerformanceMode(true, playback);

      // The window is now the whole monitor.
      backend.bounds = const Rect.fromLTWH(0, 0, 3840, 2160);

      await controller.setPerformanceMode(false, playback);

      expect(backend.bounds, const Rect.fromLTWH(50, 50, 1000, 700));
    });

    test('does not save monitor-sized bounds while in performance mode',
        () async {
      await controller.setPerformanceMode(true, playback);
      backend.bounds = const Rect.fromLTWH(0, 0, 3840, 2160);

      await controller.saveBounds();
      await controller.setPerformanceMode(false, playback);

      expect(
        backend.bounds,
        const Rect.fromLTWH(50, 50, 1000, 700),
        reason: 'saving fullscreen bounds makes the app open fullscreen '
            'forever after one performance',
      );
    });

    test('toggling to the state it is already in is a no-op', () async {
      await controller.setPerformanceMode(false, playback);
      expect(backend.calls, isEmpty);
    });
  });
}
