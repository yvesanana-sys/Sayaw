import 'dart:io';
import 'dart:typed_data';

/// The BPM an MP4 keeps in its `tmpo` atom.
///
/// `audio_metadata_reader` reads that atom off the disk and then drops it —
/// `Mp4Metadata` has no field for it — so without this an m4a library has no
/// tempo at all, which is most of a library that was bought rather than
/// ripped, and the two tempo-ordered modes have nothing to sort on.
///
/// A targeted descent rather than a general parser: it walks
/// `moov > udta > meta > ilst > tmpo > data` reading headers only, so a
/// fifty-megabyte file costs a handful of seeks rather than being loaded.
/// Anything unexpected anywhere on that path is a null — a file this cannot
/// read is still a file that plays.
int? readMp4Bpm(File file) {
  RandomAccessFile? reader;
  try {
    reader = file.openSync();
    final payload = _descend(
      reader,
      const ['moov', 'udta', 'meta', 'ilst', 'tmpo', 'data'],
      0,
      reader.lengthSync(),
    );
    if (payload == null) return null;

    // An iTunes `data` atom is a four-byte type indicator, a four-byte locale
    // and then the value. `tmpo` writes the value as a big-endian sixteen-bit
    // integer.
    final length = payload.end - payload.start;
    if (length < 10) return null;

    reader.setPositionSync(payload.start + 8);
    final value = reader.readSync(2);
    if (value.length < 2) return null;

    final bpm = (value[0] << 8) | value[1];
    return bpm > 0 ? bpm : null;
  } on Object {
    // Truncated, not really an MP4, or a container laid out in a way this
    // does not recognise.
    return null;
  } finally {
    reader?.closeSync();
  }
}

/// The payload range of the atom at the end of [path], searching within
/// `[start, end)`.
({int start, int end})? _descend(
  RandomAccessFile reader,
  List<String> path,
  int start,
  int end,
) {
  if (path.isEmpty) return (start: start, end: end);

  var offset = start;

  while (offset + 8 <= end) {
    reader.setPositionSync(offset);
    final header = reader.readSync(8);
    if (header.length < 8) return null;

    var size = _uint32(header, 0);
    final type = String.fromCharCodes(header.sublist(4, 8));
    var payloadStart = offset + 8;

    if (size == 1) {
      // A 64-bit size, for an atom over four gigabytes. Only the low half is
      // read: an atom above 2^53 is not a thing this will ever be handed.
      final extended = reader.readSync(8);
      if (extended.length < 8) return null;
      size = _uint32(extended, 0) * 0x100000000 + _uint32(extended, 4);
      payloadStart = offset + 16;
    } else if (size == 0) {
      // Runs to the end of its container.
      size = end - offset;
    }

    if (size < 8 || offset + size > end) return null;

    if (type == path.first) {
      // `meta` is a full box: four bytes of version and flags sit between its
      // header and its children. Descending without stepping over them lands
      // in the middle of the first child and finds nothing.
      final childStart = type == 'meta' ? payloadStart + 4 : payloadStart;
      return _descend(reader, path.sublist(1), childStart, offset + size);
    }

    offset += size;
  }

  return null;
}

int _uint32(Uint8List bytes, int at) =>
    (bytes[at] << 24) | (bytes[at + 1] << 16) | (bytes[at + 2] << 8) | bytes[at + 3];
