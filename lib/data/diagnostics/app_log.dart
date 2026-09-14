import 'dart:io';

import 'package:path/path.dart' as p;

/// A plain text log of what the app was doing, for the moment it stops.
///
/// "It just closed" is not a bug report; the last thirty lines before it
/// closed are. Every line goes to disk the moment it is written — not
/// buffered, not batched — because the crash this exists for is the one
/// that gives no notice. A native fault in the audio engine takes the whole
/// process with it, Dart code included, and the only thing that survives is
/// what was already on disk.
///
/// One file, `sayaw.log`, kept under a size; when it grows past that the
/// previous one is kept as `sayaw.previous.log` and a fresh one starts. Two
/// files is enough to hold the crash and the run before it.
class AppLog {
  AppLog._(this.file, this._running);

  /// The current log file.
  final File file;

  /// A marker that exists while the app runs and is removed when it exits
  /// on purpose. Found at the next start, it says the last run ended some
  /// other way.
  final File _running;

  /// Whether the run before this one ended without saying goodbye.
  bool previousRunCrashed = false;

  static const _maxBytes = 2 * 1024 * 1024;

  /// The log the app is writing to, or null before [open] — every widget
  /// test, and the first microseconds of a launch.
  static AppLog? current;

  /// Opens the log under [directory], rotating the last one if it has grown,
  /// and notes whether the previous run crashed.
  static AppLog open(Directory directory, {required String version}) {
    directory.createSync(recursive: true);
    final file = File(p.join(directory.path, 'sayaw.log'));
    final previous = File(p.join(directory.path, 'sayaw.previous.log'));
    final running = File(p.join(directory.path, 'running'));

    if (file.existsSync() && file.lengthSync() > _maxBytes) {
      if (previous.existsSync()) previous.deleteSync();
      file.renameSync(previous.path);
    }

    final log = AppLog._(file, running)
      ..previousRunCrashed = running.existsSync();
    running.writeAsStringSync(DateTime.now().toIso8601String(), flush: true);

    log.info('=== Sayaw $version started on '
        '${Platform.operatingSystem} ${Platform.operatingSystemVersion} ===');
    if (log.previousRunCrashed) {
      log.warn('The previous run ended without shutting down — see the '
          'lines above this start for what it was doing.');
    }
    current = log;
    return log;
  }

  void info(String message) => _write('INFO', message);

  void warn(String message) => _write('WARN', message);

  void error(String message, [Object? error, StackTrace? stack]) {
    _write('ERROR', error == null ? message : '$message: $error');
    if (stack != null) {
      _append(stack.toString().trimRight());
    }
  }

  /// The app is exiting on purpose. Anything after this that stops the
  /// process is not a crash.
  void shutdown() {
    info('=== shutdown ===');
    try {
      if (_running.existsSync()) _running.deleteSync();
    } on FileSystemException {
      // Nothing to do; the next start reads a crash that was not one. Better
      // than throwing on the way out.
    }
  }

  /// The last [lines] of the log, for the clipboard.
  String tail({int lines = 300}) {
    if (!file.existsSync()) return '';
    final all = file.readAsLinesSync();
    return all.skip(all.length > lines ? all.length - lines : 0).join('\n');
  }

  void _write(String level, String message) {
    final stamp = DateTime.now().toIso8601String();
    _append('$stamp [$level] $message');
  }

  void _append(String line) {
    try {
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } on FileSystemException {
      // A log that cannot be written must not take the app down for it.
    }
  }
}
