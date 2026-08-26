import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/library_access.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// How many songs the set plays, and how much of each.
///
/// Both off by default, which is a playlist played as written. Turning either
/// on is what a rotation, a competition round or a five-song showcase needs,
/// and it is one setting for the night rather than an override on every row.
class SetShapeDialog extends ConsumerStatefulWidget {
  const SetShapeDialog({super.key, required this.access});

  final SetShapeAccess access;

  @override
  ConsumerState<SetShapeDialog> createState() => _SetShapeDialogState();
}

class _SetShapeDialogState extends ConsumerState<SetShapeDialog> {
  /// Sensible starting points for someone who has just switched each on,
  /// rather than a blank field and a shrug.
  static const _defaultSongs = 5;
  static const _defaultSeconds = 120;

  /// Long enough to find a partner across a busy floor, short enough that the
  /// room does not go flat. Ten is what a caller usually gives.
  static const _defaultGap = 10;

  bool _limitSongs = false;
  bool _limitLength = false;
  bool _rotate = false;
  int _songs = _defaultSongs;
  int _seconds = _defaultSeconds;
  int _gap = _defaultGap;

  bool _loaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final shape = await widget.access.readSetShape();
    if (!mounted) return;

    setState(() {
      _limitSongs = shape.songLimit != null;
      _songs = shape.songLimit ?? _defaultSongs;
      _limitLength = shape.songDuration != null;
      _seconds = shape.songDuration?.inSeconds ?? _defaultSeconds;
      _rotate = shape.isRotation;
      _gap = shape.isRotation ? shape.rotationGap.inSeconds : _defaultGap;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    // Both taken before the await, and before the pop. Afterwards this
    // dialog's element is deactivated and neither lookup can climb out of it,
    // which is how the message below came to never appear.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);

    final full = await widget.access.writeSetShape(SetShape(
      songLimit: _limitSongs ? _songs : null,
      songDuration: _limitLength ? Duration(seconds: _seconds) : null,
      rotationGap: _rotate ? Duration(seconds: _gap) : Duration.zero,
    ));

    if (!mounted) return;
    navigator.pop();

    // Said out loud rather than left to be noticed: the operator changed a
    // number, watched the dialog close, and would otherwise have no way to
    // know half of it is waiting for the next set.
    if (!full) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Song length and rotation apply the next time this set '
            'is opened — the one playing keeps what it started with.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Set shape'),
      content: SizedBox(
        width: 420,
        child: !_loaded
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row(
                      label: 'Stop after',
                      unit: _songs == 1 ? 'song' : 'songs',
                      enabled: _limitSongs,
                      value: _songs,
                      min: 1,
                      max: 200,
                      semanticsLabel: 'Number of songs in the set',
                      onToggled: (on) => setState(() => _limitSongs = on),
                      onChanged: (v) => setState(() => _songs = v),
                    ),
                    const SizedBox(height: 8),
                    _Row(
                      label: 'Play',
                      unit: 'sec each',
                      enabled: _limitLength,
                      value: _seconds,
                      min: 10,
                      max: 900,
                      step: 15,
                      semanticsLabel: 'Seconds of each song',
                      onToggled: (on) => setState(() => _limitLength = on),
                      onChanged: (v) => setState(() => _seconds = v),
                    ),
                    const SizedBox(height: 8),
                    _Row(
                      label: 'Rotate after',
                      unit: 'sec gap',
                      enabled: _rotate,
                      value: _gap,
                      min: 2,
                      max: 120,
                      step: 5,
                      semanticsLabel: 'Seconds of silence for partner rotation',
                      onToggled: (on) => setState(() => _rotate = on),
                      onChanged: (v) => setState(() => _gap = v),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _summary(),
                      style: const TextStyle(
                        color: SayawColors.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: !_loaded || _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// The setting read back as a sentence, because two numbers and two
  /// switches do not say what the night will do.
  String _summary() {
    if (!_limitSongs && !_limitLength && !_rotate) {
      return 'Plays the set as written: every row, each track to its end.';
    }

    final of = _limitLength
        ? '${_describeSeconds(_seconds)} of each track'
        : 'each track in full';
    final times = _limitSongs
        ? ', $_songs ${_songs == 1 ? 'time' : 'times'},'
        : ',';
    final ending = _limitSongs ? ' then fades out and stops.' : '';

    if (_rotate) {
      // The whole shape of The Mixer, said in one sentence, because this is
      // the setting a caller has to be sure of before a floor is waiting.
      return 'Plays $of$times fading out and holding '
          '${_describeSeconds(_gap)} of silence between them for the floor to '
          'change partners.${ending.isEmpty ? '' : ' Stops after $_songs.'}';
    }

    if (!_limitLength) {
      return 'Plays $_songs ${_songs == 1 ? 'song' : 'songs'} in full, then '
          'fades out and stops.';
    }
    if (!_limitSongs) {
      return 'Plays ${_describeSeconds(_seconds)} of every track, then '
          'crossfades to the next.';
    }
    return 'Plays ${_describeSeconds(_seconds)} of each track, $_songs '
        '${_songs == 1 ? 'time' : 'times'}, then fades out and stops.';
  }

  static String _describeSeconds(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    final m = '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    return rest == 0 ? m : '$m $rest sec';
  }
}

/// A switch, a number, and the two buttons that change it.
///
/// Stepper buttons rather than a bare text field: this gets used in a dark
/// booth, often on a tablet, and summoning a keyboard to change 5 to 6 is the
/// wrong interaction. The field is still typable for the operator who wants
/// 137 and does not want to press a button 132 times.
class _Row extends StatefulWidget {
  const _Row({
    required this.label,
    required this.unit,
    required this.enabled,
    required this.value,
    required this.min,
    required this.max,
    required this.semanticsLabel,
    required this.onToggled,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final String unit;
  final bool enabled;
  final int value;
  final int min;
  final int max;
  final int step;
  final String semanticsLabel;
  final ValueChanged<bool> onToggled;
  final ValueChanged<int> onChanged;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.value}');

  @override
  void didUpdateWidget(_Row old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && _controller.text != '${widget.value}') {
      _controller.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nudge(int by) {
    final next = (widget.value + by).clamp(widget.min, widget.max);
    _controller.text = '$next';
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;

    return Row(
      children: [
        Semantics(
          label: widget.semanticsLabel,
          toggled: on,
          child: Switch(value: on, onChanged: widget.onToggled),
        ),
        const SizedBox(width: 8),
        // Expanded rather than a Spacer: everything to the right of this is
        // a fixed width the layout cannot give up — two 64dp touch targets
        // and a number — so the label is the only thing that may shrink, and
        // it has to be allowed to rather than overflowing the dialog.
        Expanded(
          child: Text(
            widget.label,
            style: TextStyle(
              color: on ? SayawColors.onSurface : SayawColors.onSurfaceVariant,
            ),
          ),
        ),
        _Step(
          icon: Icons.remove,
          label: 'Fewer',
          onPressed: on && widget.value > widget.min
              ? () => _nudge(-widget.step)
              : null,
        ),
        SizedBox(
          width: 56,
          child: ExcludeSemantics(
            child: TextField(
              controller: _controller,
              enabled: on,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed == null) return;
                widget.onChanged(parsed.clamp(widget.min, widget.max));
              },
            ),
          ),
        ),
        _Step(
          icon: Icons.add,
          label: 'More',
          onPressed: on && widget.value < widget.max
              ? () => _nudge(widget.step)
              : null,
        ),
        SizedBox(
          width: 72,
          child: Text(
            widget.unit,
            style: TextStyle(
              color: on ? SayawColors.onSurfaceVariant : SayawColors.outline,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, this.onPressed});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: IconButton(icon: Icon(icon, size: 20), onPressed: onPressed),
      ),
    );
  }
}

/// Opens the set-shape dialog.
///
/// Beside Event Mode in the app bar: both are things an operator sets before
/// doors open, and both are about the night rather than about one track.
class SetShapeButton extends ConsumerWidget {
  const SetShapeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(setShapeProvider);
    final enabled = access?.openPlaylistId != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Set shape: songs and length',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: IconButton(
          icon: const Icon(Icons.timelapse_outlined),
          onPressed: !enabled
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (_) => SetShapeDialog(access: access!),
                  ),
        ),
      ),
    );
  }
}
