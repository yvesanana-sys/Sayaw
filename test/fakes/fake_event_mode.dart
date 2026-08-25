import 'dart:async';

import 'package:sayaw/data/event_mode.dart';
import 'package:sayaw/ui/state/library_access.dart';

/// A pre-flight that reports whatever a test tells it to.
class FakeEventMode implements EventModeAccess {
  FakeEventMode({this.openPlaylistId = 'set-1', PreflightReport? report})
      : report = report ?? readySet();

  @override
  final String? openPlaylistId;

  PreflightReport report;

  /// Progress reported before the run finishes.
  List<PreflightProgress> progress = const [];

  /// Set to make the run fail.
  Object? failure;

  /// Set to hold the run open, so a test can look at the dialog mid-flight.
  Completer<void>? gate;

  int runs = 0;

  @override
  Future<PreflightReport> prepareForOffline({
    void Function(PreflightProgress)? onProgress,
  }) async {
    runs++;
    for (final step in progress) {
      onProgress?.call(step);
    }
    if (gate case final gate?) await gate.future;
    if (failure case final failure?) {
      this.failure = null;
      throw failure;
    }
    return report;
  }
}

/// Everything ready, nothing to worry about.
PreflightReport readySet({int tracks = 3, int announcements = 2}) =>
    PreflightReport(
      items: [
        for (var i = 0; i < tracks; i++)
          PreflightItem(
            itemId: 'item-$i',
            title: 'Track $i',
            outcome: PreflightOutcome.readyOffline,
          ),
      ],
      announcementsRendered: announcements,
      announcementsMissing: 0,
    );

/// The report the architecture document uses as its example: mostly ready,
/// with a handful of things the operator has to decide about.
PreflightReport mixedSet() => const PreflightReport(
      items: [
        PreflightItem(
          itemId: 'ok',
          title: 'Kiss of Fire',
          outcome: PreflightOutcome.readyOffline,
        ),
        PreflightItem(
          itemId: 'stream-1',
          title: 'Obsesion',
          outcome: PreflightOutcome.streamingOnly,
          detail: 'Streaming only — will be skipped without a connection',
        ),
        PreflightItem(
          itemId: 'stream-2',
          title: 'Propuesta Indecente',
          outcome: PreflightOutcome.streamingOnly,
        ),
        PreflightItem(
          itemId: 'gone',
          title: 'Sway',
          outcome: PreflightOutcome.missingFile,
          detail: '/Volumes/DJ is not mounted',
        ),
      ],
      announcementsRendered: 47,
      announcementsMissing: 0,
    );
