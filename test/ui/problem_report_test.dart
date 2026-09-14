import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/diagnostics/app_log.dart';
import 'package:sayaw/ui/screens/problem_report_dialog.dart';

import 'harness.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('sayaw-report');
  });

  tearDown(() {
    AppLog.current = null;
    dir.deleteSync(recursive: true);
  });

  testWidgets('shows where the log is and copies it', (tester) async {
    final log = AppLog.open(dir, version: 'test')..info('deck A loaded x');
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );

    await pumpSayaw(tester, const Scaffold(body: ProblemReportButton()));
    await tester.tap(find.bySemanticsLabel('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.text(log.file.path), findsOneWidget);
    await tester.tap(find.text('Copy log'));
    await tester.pumpAndSettle();

    expect(copied, contains('deck A loaded x'));
    expect(find.text('Copied. Paste it into your message.'), findsOneWidget);
  });

  testWidgets('says so when the last run crashed', (tester) async {
    AppLog.open(dir, version: 'test');
    AppLog.open(dir, version: 'test'); // no shutdown between: a crash

    await pumpSayaw(tester, const Scaffold(body: ProblemReportButton()));
    await tester.tap(find.bySemanticsLabel('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ended without shutting down'), findsOneWidget);
  });

  testWidgets('with no log it says that rather than nothing', (tester) async {
    AppLog.current = null;
    await pumpSayaw(tester, const Scaffold(body: ProblemReportButton()));
    await tester.tap(find.bySemanticsLabel('Report a problem'));
    await tester.pumpAndSettle();

    expect(find.text('No log is being written in this run.'), findsOneWidget);
  });
}
