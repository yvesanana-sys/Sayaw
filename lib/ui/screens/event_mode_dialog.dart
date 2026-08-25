import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/event_mode.dart';
import '../state/library_access.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// "Prepare for offline", and what it found.
///
/// The report is the point, not the progress bar: a DJ in a venue at six needs
/// to know which six of three hundred and eighteen tracks will not play, in
/// time to do something about it.
class EventModeDialog extends ConsumerStatefulWidget {
  const EventModeDialog({super.key, required this.eventMode});

  final EventModeAccess eventMode;

  @override
  ConsumerState<EventModeDialog> createState() => _EventModeDialogState();
}

class _EventModeDialogState extends ConsumerState<EventModeDialog> {
  PreflightProgress? _progress;
  PreflightReport? _report;
  String? _error;
  bool _running = false;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _error = null;
      _report = null;
    });

    try {
      final report = await widget.eventMode.prepareForOffline(
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (mounted) setState(() => _report = report);
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Prepare for offline'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(child: _content()),
      ),
      actions: [
        TextButton(
          onPressed: _running ? null : () => Navigator.of(context).pop(),
          child: Text(_report == null ? 'Cancel' : 'Done'),
        ),
        if (!_running && _report == null && _error == null)
          FilledButton(onPressed: _run, child: const Text('Start')),
        if (!_running && _error != null)
          TextButton(onPressed: _run, child: const Text('Try again')),
      ],
    );
  }

  Widget _content() {
    if (_error case final error?) {
      return Text(error, style: const TextStyle(color: SayawColors.error));
    }

    if (_report case final report?) return _Report(report: report);

    if (!_running) {
      return const Text(
        'Downloads what it can, renders every announcement, and checks that '
        'every file is still where it was. Do this on the venue wifi before '
        'doors open and the set stops depending on it.',
        style: TextStyle(color: SayawColors.onSurfaceVariant),
      );
    }

    final progress = _progress;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress == null || progress.total == 0
              ? null
              : progress.done / progress.total,
        ),
        const SizedBox(height: 12),
        Text(
          switch (progress?.step) {
            null || PreflightStep.resolving => 'Reading the set…',
            PreflightStep.downloading =>
              'Downloading ${progress!.done + 1} of ${progress.total}',
            PreflightStep.announcing => 'Rendering announcements…',
          },
          style: const TextStyle(color: SayawColors.onSurfaceVariant),
        ),
        if (progress?.title case final title?)
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({required this.report});

  final PreflightReport report;

  @override
  Widget build(BuildContext context) {
    final problems = [
      for (final item in report.items)
        if (item.outcome != PreflightOutcome.readyOffline) item,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${report.readyCount} of ${report.total} tracks ready offline',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          report.announcementsMissing == 0
              ? 'All ${report.announcementsRendered} announcements rendered.'
              : '${report.announcementsRendered} announcements rendered, '
                  '${report.announcementsMissing} could not be.',
          style: const TextStyle(color: SayawColors.onSurfaceVariant),
        ),
        if (problems.isEmpty) ...[
          const SizedBox(height: 16),
          const Text('Nothing in this set needs a connection.'),
        ],
        for (final group in _grouped(problems).entries) ...[
          const SizedBox(height: 16),
          Text(
            '${group.value.length} ${_headline(group.key)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          for (final item in group.value)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                item.detail == null
                    ? item.title
                    : '${item.title} — ${item.detail}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: SayawColors.onSurfaceVariant),
              ),
            ),
        ],
      ],
    );
  }

  /// Grouped by what to do about them, which is not the same as grouped by
  /// what went wrong: two missing files are one trip to plug a drive in.
  static Map<PreflightOutcome, List<PreflightItem>> _grouped(
      List<PreflightItem> items) {
    final grouped = <PreflightOutcome, List<PreflightItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.outcome, () => []).add(item);
    }
    return grouped;
  }

  static String _headline(PreflightOutcome outcome) => switch (outcome) {
        PreflightOutcome.streamingOnly =>
          'streaming only — will be skipped without internet',
        PreflightOutcome.missingFile => 'missing files',
        PreflightOutcome.notDownloaded => 'could not be downloaded',
        PreflightOutcome.notPlayable => 'rows the player cannot handle yet',
        PreflightOutcome.readyOffline => 'ready',
      };
}

/// Opens the pre-flight from the app bar.
class EventModeButton extends ConsumerWidget {
  const EventModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventMode = ref.watch(eventModeProvider);
    final enabled = eventMode?.openPlaylistId != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Prepare this set for offline',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: IconButton(
          icon: const Icon(Icons.cloud_download_outlined),
          onPressed: !enabled
              ? null
              : () => showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => EventModeDialog(eventMode: eventMode!),
                  ),
        ),
      ),
    );
  }
}
