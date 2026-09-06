import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format/track_title.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';

/// What comes after the loaded decks, drawn in the space below them.
///
/// That space used to sit empty once both decks were loaded — nothing to look
/// at, and nothing telling a first-time operator what to do next. This gives
/// it a job: preview the next row, or say what to do when there isn't one.
class UpNextCard extends ConsumerWidget {
  const UpNextCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final currentIndex =
        ref.watch(playbackProvider.select((s) => s.currentIndex));

    if (queue.isEmpty) {
      return const _UpNextShell(
        label: 'Nothing queued',
        child: Text(
          'Add tracks from the library to build a set.',
          style: TextStyle(color: SayawColors.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    final upcomingIndex = currentIndex < 0 ? 0 : currentIndex + 1;
    if (upcomingIndex >= queue.length) {
      return const _UpNextShell(
        label: 'End of set',
        child: Text(
          'This is the last track queued.',
          style: TextStyle(color: SayawColors.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    final next = queue[upcomingIndex];
    return _UpNextShell(
      label: currentIndex < 0 ? 'Up first' : 'Up next',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayTitle(next.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: SayawColors.onSurface,
                  ),
                ),
                Text(
                  next.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: SayawColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (next.danceType != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SayawColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                next.danceType!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: SayawColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UpNextShell extends StatelessWidget {
  const _UpNextShell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SayawColors.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SayawColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: SayawColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
