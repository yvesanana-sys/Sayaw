import 'dart:math';

/// Row ids are app-generated rather than autoincrementing because a playlist
/// row has to keep its identity across an export, a reimport on another
/// machine, and eventually a sync — none of which can agree on a counter.
///
/// 128 bits from [Random.secure], hex-encoded. A uuid package would add a
/// dependency for the same sixteen bytes.
String newId([Random? random]) {
  final rng = random ?? _secure;
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

final Random _secure = Random.secure();
