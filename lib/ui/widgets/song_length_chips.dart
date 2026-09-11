import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/library_access.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// How much of each song plays before the fade or the merge, as a row of
/// choices under the decks.
///
/// The same setting the Set shape dialog holds, brought out to where the
/// operator's hand already is. A social night runs the whole song; a class
/// or a mixer runs two or three minutes of it and moves on. That gets
/// changed between dances, not planned the day before, and a dialog is two
/// taps too far for something that changes between dances.
///
/// Takes effect on the song playing, not the next one opened: an operator
/// who chooses two minutes at 2:10 means "now".
class SongLengthChips extends ConsumerWidget {
  const SongLengthChips({super.key});

  /// The lengths a night is usually run in. A value the set already holds
  /// that is not one of these is shown beside them rather than hidden, so
  /// the row always says what is true.
  static const presets = <Duration>[
    Duration(minutes: 2),
    Duration(minutes: 2, seconds: 30),
    Duration(minutes: 3),
    Duration(minutes: 3, seconds: 30),
    Duration(minutes: 4),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(songLengthProvider);
    final access = ref.watch(setShapeProvider);

    final choices = <Duration?>[
      null,
      ...presets,
      if (current != null && !presets.contains(current)) current,
    ];

    Future<void> choose(Duration? length) async {
      if (access == null) return;
      final shape = await access.readSetShape();
      await access.writeSetShape(SetShape(
        songLimit: shape.songLimit,
        songDuration: length,
        rotationGap: shape.rotationGap,
        continuousFlow: shape.continuousFlow,
        snowballStages: shape.snowballStages,
      ));
    }

    return Semantics(
      container: true,
      label: 'Play each song for',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: ExcludeSemantics(
              child: Text(
                'PLAY EACH SONG FOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: SayawColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final length in choices)
                _LengthChip(
                  length: length,
                  selected: length == current,
                  onPressed: access == null ? null : () => choose(length),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LengthChip extends StatelessWidget {
  const _LengthChip({
    required this.length,
    required this.selected,
    required this.onPressed,
  });

  /// Null is the whole song.
  final Duration? length;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = length == null ? 'Full song' : _clock(length!);
    final spoken = length == null
        ? 'the whole song'
        : '${length!.inMinutes} minutes'
            '${length!.inSeconds % 60 == 0 ? '' : ' ${length!.inSeconds % 60} seconds'}';

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? 'Playing $spoken of each, selected' : 'Play $spoken of each',
      excludeSemantics: true,
      child: SizedBox(
        height: kMinTouchTarget,
        child: Material(
          color: selected
              ? SayawColors.tertiary.withValues(alpha: 0.18)
              : SayawColors.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kMinTouchTarget / 2),
            side: BorderSide(
              color: selected ? SayawColors.tertiary : Colors.transparent,
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: selected
                        ? SayawColors.tertiary
                        : SayawColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _clock(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
