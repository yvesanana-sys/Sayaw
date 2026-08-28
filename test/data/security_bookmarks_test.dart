import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/media_resolver.dart';
import 'package:sayaw/data/sources/security_bookmarks.dart';

import '../fakes/fake_sources.dart';

/// A bookmark that resolves to whatever the test says, or to nothing.
class _FakeBookmarks implements SecurityBookmarks {
  _FakeBookmarks({this.path, this.isSupported = true});

  String? path;

  @override
  bool isSupported;

  final List<Uint8List> asked = [];

  @override
  Future<String?> resolve(Uint8List bookmark) async {
    asked.add(bookmark);
    return path;
  }

  /// One bookmark per path, derived from it so a test can tell them apart.
  final List<List<String>> createdFor = [];

  @override
  Future<List<Uint8List?>> create(List<String> paths) async {
    createdFor.add(paths);
    return [
      for (final path in paths)
        path.isEmpty ? null : Uint8List.fromList(path.codeUnits),
    ];
  }
}

MediaResolver _resolver(SecurityBookmarks bookmarks) => MediaResolver(
      plex: FakePlexClient(),
      tidal: FakeTidalClient(),
      cache: FakeMediaCache(),
      networkMode: () => NetworkMode.online,
      bookmarks: bookmarks,
    );

void main() {
  late Directory dir;
  late File onDisk;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sayaw-bookmarks');
    addTearDown(() => dir.deleteSync(recursive: true));
    onDisk = File('${dir.path}/kiss-of-fire.flac')
      ..writeAsStringSync('not really audio');
  });

  final bookmark = Uint8List.fromList([1, 2, 3, 4]);

  group('resolving a bookmark', () {
    test('a bookmark that resolves is what gets played', () async {
      // Not the stored path: on a sandboxed build the path is stale and the
      // bookmark is the only handle that still works.
      final bookmarks = _FakeBookmarks(path: onDisk.path);

      final media = await _resolver(bookmarks).resolve(
        LocalSource(path: '/somewhere/else.flac', bookmark: bookmark),
      );

      expect(media.uri, Uri.file(onDisk.path));
      expect(bookmarks.asked.single, bookmark);
    });

    test('a track with no bookmark never asks', () async {
      // Every platform but two, and every file imported from a plain path.
      final bookmarks = _FakeBookmarks(path: onDisk.path);

      await _resolver(bookmarks).resolve(LocalSource(path: onDisk.path));

      expect(bookmarks.asked, isEmpty);
    });

    test('a bookmark that will not resolve falls back to the stored path',
        () async {
      // Which is what happens on every platform that has no implementation,
      // and has to keep working.
      final media = await _resolver(_FakeBookmarks(path: null)).resolve(
        LocalSource(path: onDisk.path, bookmark: bookmark),
      );

      expect(media.uri, Uri.file(onDisk.path));
    });
  });

  group('when it cannot be played', () {
    test('an expired grant is not reported as a missing file', () async {
      // The operator told the wrong one goes looking in the wrong place — for
      // a drive that is plugged in, rather than for a folder grant to give
      // again.
      final bookmarks = _FakeBookmarks(path: null);

      await expectLater(
        _resolver(bookmarks).resolve(
          LocalSource(path: '/gone/away.flac', bookmark: bookmark),
        ),
        throwsA(isA<UnavailableOffline>().having(
            (e) => e.reason, 'reason', contains('granting again'))),
      );
    });

    test('but on a platform without bookmarks it is a missing file', () async {
      // Because there it really is one, and there is no grant to give.
      final bookmarks = _FakeBookmarks(path: null, isSupported: false);

      await expectLater(
        _resolver(bookmarks).resolve(
          LocalSource(path: '/gone/away.flac', bookmark: bookmark),
        ),
        throwsA(isA<UnavailableOffline>()
            .having((e) => e.reason, 'reason', contains('missing'))),
      );
    });

    test('a file that is simply gone still says so', () async {
      await expectLater(
        _resolver(const NoSecurityBookmarks())
            .resolve(LocalSource(path: '/gone/away.flac')),
        throwsA(isA<UnavailableOffline>()),
      );
    });
  });

  group('the platform implementations', () {
    test('a platform without bookmarks answers null and says it has none', () {
      const bookmarks = NoSecurityBookmarks();

      expect(bookmarks.isSupported, isFalse);
      expect(bookmarks.resolve(bookmark), completion(isNull));
    });

    test('the method channel one is not supported off Apple platforms', () {
      // These tests run on Linux, which is the point of the assertion.
      expect(PlatformSecurityBookmarks().isSupported, isFalse);
    });

    test('a missing native handler is a null, not a crash', () async {
      // The state the app is actually in: the Dart side is wired and the
      // native half is not written, so every call comes back as a missing
      // plugin and has to degrade to the stored path.
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('sayaw/security_bookmarks');

      // No handler registered at all, which is what an unimplemented platform
      // looks like from Dart.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      final bookmarks = PlatformSecurityBookmarks(channel);
      expect(await bookmarks.resolve(bookmark), isNull);

      // And it stops claiming the capability, so nothing downstream tells an
      // operator to re-grant a folder when the truth is that the file is gone.
      expect(bookmarks.isSupported, isFalse);
    });

    test('a native side that refuses is also a null', () async {
      // A revoked grant or an unmounted volume. The operator finds out when
      // the file will not play, which is where they would have anyway.
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('sayaw/security_bookmarks');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (call) async => throw PlatformException(code: 'stale'),
      );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      expect(await PlatformSecurityBookmarks(channel).resolve(bookmark), isNull);
    });
  });

  group('making them during a scan', () {
    test('a platform without bookmarks writes none', () async {
      // Every platform but two, and every test in this suite.
      const bookmarks = NoSecurityBookmarks();

      expect(await bookmarks.create(['/a.flac', '/b.flac']), [null, null]);
    });

    test('one round trip for a whole batch, not one per file', () async {
      // A library is tens of thousands of files. A channel call each would
      // dominate the import.
      final bookmarks = _FakeBookmarks();

      await bookmarks.create(['/a.flac', '/b.flac', '/c.flac']);

      expect(bookmarks.createdFor, hasLength(1));
      expect(bookmarks.createdFor.single, hasLength(3));
    });
  });

}
