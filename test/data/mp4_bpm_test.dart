import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/library/mp4_bpm.dart';
import 'package:sayaw/data/library/track_metadata.dart';

/// One MP4 atom: a big-endian size, a four-character type, then the payload.
List<int> _atom(String type, List<int> payload) {
  final size = 8 + payload.length;
  return [
    (size >> 24) & 0xff,
    (size >> 16) & 0xff,
    (size >> 8) & 0xff,
    size & 0xff,
    ...type.codeUnits,
    ...payload,
  ];
}

/// A `meta` atom, which is a *full* box: four bytes of version and flags sit
/// between its header and its children. Getting that wrong lands in the middle
/// of the first child.
List<int> _meta(List<int> children) =>
    _atom('meta', [0, 0, 0, 0, ...children]);

/// The iTunes value box: a four-byte type indicator, a four-byte locale, then
/// the value itself.
List<int> _data(List<int> value) =>
    _atom('data', [0, 0, 0, 21, 0, 0, 0, 0, ...value]);

/// A version-0 `mvhd`: version, flags, two timestamps, a timescale and a
/// duration, padded to the hundred bytes the parser insists on reading.
List<int> _mvhd() => [
      0, // version
      0, 0, 0, // flags
      0, 0, 0, 0, // created
      0, 0, 0, 0, // modified
      0, 0, 0x03, 0xe8, // timescale: 1000
      0, 0x02, 0xbf, 0x20, // duration: 180000, so three minutes
      ...List<int>.filled(100 - 20, 0),
    ];

/// An m4a carrying [bpm], built by hand.
///
/// Written out rather than checked in as a binary for the same reason the ID3
/// fixtures are: the thing worth testing is that the real descent finds the
/// real atom a tagger writes, and a fixture nobody can read does not say that.
File _m4aWithBpm(Directory dir, String name, int? bpm) {
  final ilst = _atom('ilst', [
    // A neighbour, so the descent has to actually find `tmpo` rather than
    // take whatever comes first.
    ..._atom('\u00a9nam', _data('Kiss of Fire'.codeUnits)),
    if (bpm != null) ..._atom('tmpo', _data([(bpm >> 8) & 0xff, bpm & 0xff])),
  ]);

  final bytes = <int>[
    // `ftyp`, which is what marks the file as an MP4 at all.
    ..._atom('ftyp', 'M4A '.codeUnits + [0, 0, 0, 0]),
    ..._atom('moov', [
      // A real movie header, not padding: the tag library reads a fixed
      // hundred bytes out of this one and walks off the end of a short one.
      // It also has to sit before `udta`, so the descent has to skip it.
      ..._atom('mvhd', _mvhd()),
      ..._atom('udta', _meta(ilst)),
    ]),
  ];

  return File('${dir.path}/$name')..writeAsBytesSync(Uint8List.fromList(bytes));
}

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sayaw-mp4');
    addTearDown(() => dir.deleteSync(recursive: true));
  });

  group('reading the tmpo atom', () {
    test('a tagged m4a gives up its tempo', () async {
      final file = _m4aWithBpm(dir, 'bachata.m4a', 128);

      expect(readMp4Bpm(file), 128);
    });

    test('the whole way through the reader, not just the descent', () async {
      // The parser reads this atom and then drops it, so the point is that
      // `TagMetadataReader` reaches around it.
      final file = _m4aWithBpm(dir, 'waltz.m4a', 84);

      expect((await const TagMetadataReader().read(file))?.bpm, 84.0);
    });

    test('an m4a with no tempo tag is unknown, not zero', () async {
      // Most of a library. A zero would sort to the front of every set.
      final file = _m4aWithBpm(dir, 'untagged.m4a', null);

      expect(readMp4Bpm(file), isNull);
    });

    test('a tempo of zero is absence, the same as everywhere else', () async {
      final file = _m4aWithBpm(dir, 'zero.m4a', 0);

      expect(readMp4Bpm(file), isNull);
    });

    test('the fast end of a ballroom night survives the round trip', () async {
      for (final fast in [176, 208, 360]) {
        expect(readMp4Bpm(_m4aWithBpm(dir, '$fast.m4a', fast)), fast);
      }
    });
  });

  group('files it cannot read', () {
    test('something that is not an MP4 at all', () async {
      final file = File('${dir.path}/notes.txt')..writeAsStringSync('hello');

      expect(readMp4Bpm(file), isNull);
    });

    test('an empty file', () async {
      final file = File('${dir.path}/empty.m4a')..writeAsBytesSync([]);

      expect(readMp4Bpm(file), isNull);
    });

    test('a truncated one, cut off mid-atom', () async {
      final whole = _m4aWithBpm(dir, 'whole.m4a', 128).readAsBytesSync();
      final file = File('${dir.path}/cut.m4a')
        ..writeAsBytesSync(whole.sublist(0, whole.length ~/ 2));

      expect(readMp4Bpm(file), isNull);
    });

    test('an atom claiming to be bigger than the file', () async {
      // A malformed size is the shape that turns a descent into a hang or an
      // out-of-range read.
      final file = File('${dir.path}/liar.m4a')
        ..writeAsBytesSync(Uint8List.fromList([
          ..._atom('ftyp', 'M4A '.codeUnits),
          0xff, 0xff, 0xff, 0xff, ...'moov'.codeUnits,
        ]));

      expect(readMp4Bpm(file), isNull);
    });

    test('an atom claiming to be zero-length', () async {
      // Size zero means "runs to the end", and read naively it is an infinite
      // loop rather than a wrong answer.
      final file = File('${dir.path}/zerobox.m4a')
        ..writeAsBytesSync(Uint8List.fromList([
          ..._atom('ftyp', 'M4A '.codeUnits),
          0, 0, 0, 0, ...'junk'.codeUnits,
          ..._atom('moov', []),
        ]));

      expect(readMp4Bpm(file), isNull);
    });

    test('a file that does not exist', () async {
      expect(readMp4Bpm(File('${dir.path}/nothing.m4a')), isNull);
    });
  });
}
