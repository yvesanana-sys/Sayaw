import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/soundboard.dart';
import '../format/track_title.dart';
import '../state/library_access.dart';
import '../state/playback_ui_state.dart';
import '../state/soundboard_provider.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// Opens the picker for one row of the set.
Future<void> showCueTagDialog(
  BuildContext context, {
  required QueueItemUi item,
  required CueTagAccess access,
}) =>
    showDialog<void>(
      context: context,
      builder: (_) => CueTagDialog(item: item, access: access),
    );

/// Which of the operator's own sounds announces one row of the set.
///
/// The soundboard is already a list of the files they loaded and named, so
/// this picks from that rather than opening a file dialog: a clip reaches a
/// transition without a path being typed anywhere, and one recording can
/// announce forty rows without being loaded forty times.
///
/// Deliberately no preview button. Every cue here plays through the room's
/// PA, and a picker that can put a whistle over a full floor by accident is
/// not worth the confirmation it saves. The bar is one tap away for that.
class CueTagDialog extends ConsumerWidget {
  const CueTagDialog({super.key, required this.item, required this.access});

  final QueueItemUi item;
  final CueTagAccess access;

  Future<void> _tag(BuildContext context, String? cueId) async {
    // Taken before the await: afterwards this dialog's element is deactivated
    // and the lookup cannot climb out of it.
    final navigator = Navigator.of(context);
    await access.tagSoundCue(itemId: item.id, cueId: cueId);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cues = ref.watch(soundCuesProvider).value ?? const <SoundCue>[];

    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Announce with'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle(item.title),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: SayawColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _CueOption(
                    label: 'Nothing',
                    detail: item.danceType == null
                        ? 'Announce this row the way the set does'
                        : 'Announce it the way ${item.danceType} does',
                    selected: !item.hasSoundCue,
                    onTap: () => _tag(context, null),
                  ),
                  for (final cue in cues)
                    _CueOption(
                      label: cue.label,
                      detail: cue.ducks
                          ? 'Music dips underneath it'
                          : 'Plays over the music at full level',
                      selected: cue.id == item.soundCueId,
                      onTap: () => _tag(context, cue.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              // Said here because it is the one thing the picker cannot show:
              // the same tag lands in two different places depending on how
              // the night is shaped, and both of them are right.
              'Plays across the crossfade into this song. In a rotation it '
              'plays cleanly in the gap instead.',
              style: TextStyle(
                fontSize: 11,
                color: SayawColors.onSurfaceVariant,
              ),
            ),
            if (cues.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'No sounds loaded yet — add them on the soundboard.',
                style: TextStyle(fontSize: 11, color: SayawColors.error),
              ),
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

class _CueOption extends StatelessWidget {
  const _CueOption({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label, selected' : label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: kMinTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: selected
                    ? SayawColors.tertiary
                    : SayawColors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: SayawColors.onSurface,
                      ),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: SayawColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
