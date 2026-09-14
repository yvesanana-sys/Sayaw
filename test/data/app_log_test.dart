import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/diagnostics/app_log.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sayaw-log');
    AppLog.current = null;
  });

  tearDown(() {
    AppLog.current = null;
    dir.deleteSync(recursive: true);
  });

  test('every line is on disk the moment it is written', () {
    final log = AppLog.open(dir, version: '0.1.0-rc22');
    log.info('opening set');
    log.error('deck A', StateError('cannot open'));

    // Read back through a fresh handle, not the one that wrote: what a crash
    // leaves behind is what is on disk, not what is in a buffer.
    final lines = File('${dir.path}/sayaw.log').readAsLinesSync();
    expect(lines.first, contains('Sayaw 0.1.0-rc22 started on'));
    expect(lines, contains(matches(r'\[INFO\] opening set$')));
    expect(lines, contains(matches(r'\[ERROR\] deck A: Bad state: cannot open$')));
  });

  test('a run that says goodbye is not a crash; one that does not, is', () {
    AppLog.open(dir, version: 'x').shutdown();
    expect(AppLog.open(dir, version: 'x').previousRunCrashed, isFalse);

    // No shutdown this time — the process just stopped.
    expect(AppLog.open(dir, version: 'x').previousRunCrashed, isTrue);

    final text = File('${dir.path}/sayaw.log').readAsStringSync();
    expect(text, contains('previous run ended without shutting down'));
  });

  test('a log that has grown is kept as the previous one', () {
    final log = AppLog.open(dir, version: 'x');
    final big = 'x' * 1024;
    for (var i = 0; i < 2100; i++) {
      log.info(big);
    }

    AppLog.open(dir, version: 'x');

    expect(File('${dir.path}/sayaw.previous.log').existsSync(), isTrue);
    expect(File('${dir.path}/sayaw.log').lengthSync(), lessThan(4096));
  });

  test('the tail is the last lines, for the clipboard', () {
    final log = AppLog.open(dir, version: 'x');
    for (var i = 0; i < 500; i++) {
      log.info('line $i');
    }

    final tail = log.tail(lines: 10);

    expect(tail.split('\n'), hasLength(10));
    expect(tail, endsWith('line 499'));
  });

  test('a stack trace goes with its error', () {
    final log = AppLog.open(dir, version: 'x');
    try {
      throw StateError('boom');
    } catch (e, s) {
      log.error('Uncaught', e, s);
    }

    expect(File('${dir.path}/sayaw.log').readAsStringSync(),
        contains('app_log_test.dart'));
  });
}
