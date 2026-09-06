import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';

/// What the next transition will say, drawn between the two decks.
///
/// Sits where the announcement is heard: between the deck going out and the
/// deck coming in, on the crossfade it rides over. An announcement belongs to
/// the row being faded *to*, and nothing on screen used to say so — an
/// operator who tagged the song already playing and then pressed crossfade got
/// silence, which looks exactly like a tag that did not work.
///
/// Keeps its height when there is nothing to say. The decks must not move
/// under a hand reaching for them because the next row happens to be untagged.
class AnnouncerStrip extends ConsumerWidget {
  const AnnouncerStrip({super.key});

  /// Tall enough to read at a glance across a booth, and the same whether or
  /// not there is anything in it.
  static const double height = 44.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(nextAnnouncementProvider);

    return Semantics(
      container: true,
      label: announcement == null
          ? 'No announcement on the next transition'
          : 'Next transition announces ${announcement.label}, '
              '${announcement.timing.description}',
      child: ExcludeSemantics(
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: announcement == null
                ? Colors.transparent
                : SayawColors.tertiary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: announcement == null
                  ? SayawColors.outlineVariant
                  : SayawColors.tertiary.withValues(alpha: 0.45),
            ),
          ),
          child: announcement == null
              ? const _Empty()
              : _Announcement(announcement),
        ),
      ),
    );
  }
}

/// Nothing will be said. Deliberately close to blank: an empty slot between
/// the decks reads as "no voice here" faster than a sentence explaining it,
/// and the operator is watching the floor rather than this.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.campaign_outlined,
          size: 18,
          color: SayawColors.onSurfaceVariant.withValues(alpha: 0.35),
        ),
      ],
    );
  }
}

class _Announcement extends StatelessWidget {
  const _Announcement(this.announcement);

  final NextAnnouncementUi announcement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Filled for the operator's own recording, outlined for a synthesised
        // voice — the same distinction the soundboard bar draws, and worth
        // knowing at a glance because only one of them is in their voice.
        Icon(
          announcement.isRecording ? Icons.campaign : Icons.record_voice_over,
          size: 18,
          color: SayawColors.tertiary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            announcement.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SayawColors.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          announcement.timing.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: SayawColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
