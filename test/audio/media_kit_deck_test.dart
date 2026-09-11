import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sayaw/audio/announcement_engine.dart';
import 'package:sayaw/audio/deck.dart';

/// The desktop deck against a real libmpv, where it can be had.
///
/// Every other test in `test/audio/` runs on a fake deck, and that is right:
/// the engine's behaviour is timing, and timing is what a fake makes
/// deterministic. But the bug these pin lived *between* the deck and libmpv —
/// in what the player's duration stream actually emits, and when — and no
/// fake can catch a wrong assumption about the thing it is standing in for.
/// Every announcement on Windows was silent for that reason, through two
/// releases whose test suites were green.
///
/// Skips itself where the native library cannot be loaded, which is any
/// machine without libmpv and the Windows test host. It is run on a Linux
/// machine with `libmpv` installed — see INSTALL.md — and that is where it
/// earns its keep.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String twoSeconds;
  late String threeSeconds;
  var available = false;

  setUpAll(() {
    try {
      MediaKit.ensureInitialized();
      available = true;
    } on Object {
      available = false;
    }
    dir = Directory.systemTemp.createTempSync('sayaw-mpv');
    twoSeconds = _sineWav(dir, 'two.wav', const Duration(seconds: 2));
    threeSeconds = _sineWav(dir, 'three.wav', const Duration(seconds: 3));
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  Future<void> requireLibmpv() async {
    if (!available) markTestSkipped('libmpv is not loadable here');
  }

  test('a loaded file reports its real length, not the zero mpv says first',
      () async {
    await requireLibmpv();
    if (!available) return;

    final deck = MediaKitDeck('voice');
    addTearDown(deck.dispose);

    await deck.load(PlayableMedia(uri: Uri.file(twoSeconds)));

    expect(deck.duration, isNotNull);
    expect(deck.duration!.inMilliseconds, closeTo(2000, 50));
  });

  test('the next file replaces the length rather than inheriting it',
      () async {
    await requireLibmpv();
    if (!available) return;

    final deck = MediaKitDeck('voice');
    addTearDown(deck.dispose);

    await deck.load(PlayableMedia(uri: Uri.file(twoSeconds)));
    await deck.load(PlayableMedia(uri: Uri.file(threeSeconds)));

    expect(deck.duration!.inMilliseconds, closeTo(3000, 50));
  });

  test('a recorded announcement is timed at the length of the recording',
      () async {
    await requireLibmpv();
    if (!available) return;

    final deck = MediaKitDeck('voice');
    addTearDown(deck.dispose);
    final factory = PlatformClipFactory(
      deck: deck,
      cacheDirectory: dir.path,
      settings: const TtsVoiceSettings(),
    );

    final clip = await factory.probe(twoSeconds, text: 'Waltz');

    // Not null, and not the assumed length either: the file says how long it
    // is, and that is what the duck envelope has to be timed against.
    expect(clip, isNotNull);
    expect(clip!.duration.inMilliseconds, closeTo(2000, 50));
  });
}

/// A mono 16-bit PCM sine, written by hand so the test owns its own input and
/// needs no ffmpeg on the machine.
String _sineWav(Directory dir, String name, Duration length) {
  const rate = 44100;
  final samples = (rate * length.inMilliseconds / 1000).round();
  final data = ByteData(44 + samples * 2);

  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples * 2, Endian.little);

  for (var i = 0; i < samples; i++) {
    final v = (math.sin(2 * math.pi * 440 * i / rate) * 12000).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }

  final file = File('${dir.path}/$name')..writeAsBytesSync(data.buffer.asUint8List());
  return file.path;
}
