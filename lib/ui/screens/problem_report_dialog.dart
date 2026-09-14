import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../data/diagnostics/app_log.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// Opens the report dialog.
Future<void> showProblemReport(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const ProblemReportDialog(),
    );

/// Where the log is, and two ways to hand it over.
///
/// "It just closed" is not something anyone can fix. The last lines the app
/// wrote before it closed usually are, and this is the one place that says
/// where they are and puts them on the clipboard. No sending from here — the
/// operator decides where a log goes, and pasting it into a message they
/// were going to write anyway is the whole of it.
class ProblemReportDialog extends StatefulWidget {
  const ProblemReportDialog({super.key});

  @override
  State<ProblemReportDialog> createState() => _ProblemReportDialogState();
}

class _ProblemReportDialogState extends State<ProblemReportDialog> {
  String? _note;

  Future<void> _copy(AppLog log) async {
    await Clipboard.setData(ClipboardData(text: log.tail()));
    if (mounted) setState(() => _note = 'Copied. Paste it into your message.');
  }

  Future<void> _saveAs(AppLog log) async {
    final where = await getSaveLocation(
      suggestedName: 'sayaw-log-${DateTime.now().toIso8601String().split('T').first}.txt',
    );
    if (where == null || !mounted) return;
    try {
      // Both files, newest last, so one attachment carries the crash and
      // the run before it.
      final previous = File(p.join(log.file.parent.path, 'sayaw.previous.log'));
      final buffer = StringBuffer();
      if (previous.existsSync()) {
        buffer
          ..writeln('===== previous run =====')
          ..writeln(previous.readAsStringSync())
          ..writeln('===== this run =====');
      }
      if (log.file.existsSync()) buffer.write(log.file.readAsStringSync());
      await File(where.path).writeAsString(buffer.toString());
      if (mounted) setState(() => _note = 'Saved ${p.basename(where.path)}.');
    } on Object catch (e) {
      if (mounted) setState(() => _note = 'Could not save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = AppLog.current;
    final canUseFiles =
        Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Report a problem'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If Sayaw closed on its own or something went wrong, the log '
              'says what it was doing at the time. Copy it and paste it into '
              'your message, or save it as a file to attach.',
            ),
            const SizedBox(height: 12),
            if (log == null)
              const Text(
                'No log is being written in this run.',
                style: TextStyle(color: SayawColors.onSurfaceVariant),
              )
            else ...[
              if (log.previousRunCrashed)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'The previous run ended without shutting down. What it '
                    'was doing is in the log.',
                    style: TextStyle(color: SayawColors.error),
                  ),
                ),
              SelectableText(
                log.file.path,
                style: const TextStyle(
                  fontSize: 12,
                  color: SayawColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    height: kMinTouchTarget,
                    child: FilledButton.icon(
                      onPressed: () => _copy(log),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy log'),
                    ),
                  ),
                  if (canUseFiles)
                    SizedBox(
                      height: kMinTouchTarget,
                      child: OutlinedButton.icon(
                        onPressed: () => _saveAs(log),
                        icon: const Icon(Icons.save_alt, size: 18),
                        label: const Text('Save log as…'),
                      ),
                    ),
                ],
              ),
            ],
            if (_note case final note?) ...[
              const SizedBox(height: 12),
              Text(note, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// The app bar's door to the report.
class ProblemReportButton extends StatelessWidget {
  const ProblemReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Report a problem',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: InkWell(
          onTap: () => showProblemReport(context),
          child: const Icon(Icons.bug_report_outlined),
        ),
      ),
    );
  }
}
