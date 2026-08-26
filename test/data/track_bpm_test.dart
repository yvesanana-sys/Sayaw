import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/library/track_metadata.dart';

/// An MP3 with one ID3v2.3 text frame in front of a plausible MPEG frame
/// header.
///
/// Built by hand rather than checked in as a binary: the point is to exercise
/// the real parser against the exact frame a tagger writes, and a fixture file
/// nobody can read is a worse way to say that.
File _mp3With(Directory dir, String name, String frameId, String text) {
  final payload = <int>[0x00, ...text.codeUnits]; // ISO-8859-1
  final frame = <int>[
    ...frameId.codeUnits,
    // v2.3 frame sizes are plain big-endian, not syncsafe.
    (payload.length >> 24) & 0xff,
    (payload.length >> 16) & 0xff,
    (payload.length >> 8) & 0xff,
    payload.length & 0xff,
    0x00, 0x00,
    ...payload,
  ];
  final size = frame.length;

  final bytes = <int>[
    0x49, 0x44, 0x33, 0x03, 0x00, 0x00, // "ID3", v2.3, no flags
    // The tag size is syncsafe: seven bits per byte.
    (size >> 21) & 0x7f, (size >> 14) & 0x7f, (size >> 7) & 0x7f, size & 0x7f,
    ...frame,
    0xff, 0xfb, 0x90, 0x00, // MPEG-1 Layer III, 128 kbps, 44.1 kHz
    ...List<int>.filled(400, 0),
  ];

  return File('${dir.path}/$name')..writeAsBytesSync(Uint8List.fromList(bytes));
}

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sayaw-bpm');
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  group('reading it off a real file', () {
    test('a TBPM frame becomes a number', () async {
      final file = _mp3With(dir, 'waltz.mp3', 'TBPM', '84');

      expect((await const TagMetadataReader().read(file))?.bpm, 84.0);
    });

    test('a file with no TBPM frame reads as unknown, not as zero', () async {
      // Most of a DJ library. Nothing downstream may treat this as a tempo.
      final file = _mp3With(dir, 'untagged.mp3', 'TIT2', 'Kiss of Fire');

      expect((await const TagMetadataReader().read(file))?.bpm, isNull);
    });

    test('the tag that says "not analysed" is not a tempo of zero', () async {
      // What a tagger writes when it has nothing to say. Read literally it
      // would sort to the front of every BPM-ordered set.
      final file = _mp3With(dir, 'zero.mp3', 'TBPM', '0');

      expect((await const TagMetadataReader().read(file))?.bpm, isNull);
    });

    test('reading BPM does not disturb the rest of the tags', () async {
      // It is a second parse of the same file, so this is worth pinning.
      final file = _mp3With(dir, 'titled.mp3', 'TIT2', 'Sway');

      expect((await const TagMetadataReader().read(file))?.title, 'Sway');
    });

    test('a file that is not audio at all is null, not a throw', () async {
      final file = File('${dir.path}/notes.mp3')..writeAsStringSync('hello');

      expect(await const TagMetadataReader().read(file), isNull);
    });
  });

  group('what a decade of taggers actually wrote', () {
    test('a plain integer', () {
      expect(TagMetadataReader.parseBpm('128'), 128.0);
    });

    test('a decimal, in either notation', () {
      expect(TagMetadataReader.parseBpm('128.5'), 128.5);
      expect(TagMetadataReader.parseBpm('128,5'), 128.5,
          reason: 'European taggers write a comma');
    });

    test('a number with the unit written out', () {
      expect(TagMetadataReader.parseBpm('128 BPM'), 128.0);
    });

    test('zero and negatives are absence, not tempo', () {
      expect(TagMetadataReader.parseBpm('0'), isNull);
      expect(TagMetadataReader.parseBpm('0.0'), isNull);
      expect(TagMetadataReader.parseBpm('-120'), 120.0,
          reason: 'the sign is not part of the number a tagger meant');
    });

    test('nothing usable is null rather than a guess', () {
      expect(TagMetadataReader.parseBpm(null), isNull);
      expect(TagMetadataReader.parseBpm(''), isNull);
      expect(TagMetadataReader.parseBpm('   '), isNull);
      expect(TagMetadataReader.parseBpm('unknown'), isNull);
    });

    test('an absurd value is garbage, not a very fast dance', () {
      expect(TagMetadataReader.parseBpm('99999'), isNull);
      expect(TagMetadataReader.parseBpm('400'), isNull);
    });

    test('the fast end of a ballroom night still gets through', () {
      // Quickstep runs to about 208, and some taggers store double-time.
      for (final fast in ['176', '208', '360']) {
        expect(TagMetadataReader.parseBpm(fast), isNotNull, reason: fast);
      }
    });
  });
}
