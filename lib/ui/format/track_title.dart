/// Turns a title imported from a bare filename into something readable.
///
/// Untagged files are imported under their filename (see
/// `LibraryScanner._titleFromFilename`), and a DJ's library is full of them —
/// zero-padded set-order prefixes, underscores standing in for spaces, and
/// markers like `(trimmed+)` left by whatever tool cut the file to length for
/// a competition round. None of that is meant to be read by a person, so the
/// display peels it back. It never touches the stored title: search, the
/// database and TTS announcements all still see the original string.
///
/// A title that already came from a tag — no underscores, no numeric
/// set-order prefix — passes through unchanged.
String displayTitle(String raw) {
  var title = raw;

  // A set-order prefix: one to three groups of digits each followed by an
  // underscore or a space, e.g. "00_00_", "01_ ", "03_".
  title = title.replaceFirst(RegExp(r'^(?:\d{1,3}[_\s]+){1,3}'), '');

  title = title.replaceAll('_', ' ');

  title = title.replaceFirst(
    RegExp(r'\s*\(trimmed\+*\)\s*$', caseSensitive: false),
    '',
  );

  title = title.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

  return title.isEmpty ? raw : title;
}
