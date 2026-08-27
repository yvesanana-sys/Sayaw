import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../audio/soundboard.dart';
import '../state/soundboard_provider.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// Managing the cut-in sounds.
///
/// Nothing ships with the app — a whistle is the operator's own file — so this
/// is where a soundboard comes from at all.
class SoundboardSheet extends ConsumerStatefulWidget {
  const SoundboardSheet({super.key, required this.access});

  final SoundboardAccess access;

  @override
  ConsumerState<SoundboardSheet> createState() => _SoundboardSheetState();
}

class _SoundboardSheetState extends ConsumerState<SoundboardSheet> {
  /// Set once a file is chosen, so the operator can name it before it lands.
  XFile? _picked;
  final _label = TextEditingController();
  bool _ducks = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Audio',
        extensions: ['wav', 'mp3', 'flac', 'm4a', 'aiff', 'ogg', 'opus'],
      ),
    ]);
    if (file == null || !mounted) return;

    setState(() {
      _picked = file;
      _error = null;
      // A sensible name straight away, so the common case is pick-and-save.
      if (_label.text.trim().isEmpty) {
        _label.text = p.basenameWithoutExtension(file.path);
      }
    });
  }

  Future<void> _save() async {
    final file = _picked;
    final label = _label.text.trim();

    if (file == null) {
      setState(() => _error = 'Pick a sound first.');
      return;
    }
    if (label.isEmpty) {
      setState(() => _error = 'Give it a name for the button.');
      return;
    }

    await widget.access.addCue(
      label: label,
      filePath: file.path,
      // A whistle is louder than the mix and cuts through on its own; a spoken
      // cue needs room made for it.
      duckLevel: _ducks ? 0.3 : 1.0,
    );

    if (!mounted) return;
    setState(() {
      _picked = null;
      _ducks = false;
      _error = null;
      _label.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cues = ref.watch(soundCuesProvider).value ?? const <SoundCue>[];

    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Soundboard'),
      content: SizedBox(
        width: 460,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AddCue(
              picked: _picked,
              label: _label,
              ducks: _ducks,
              error: _error,
              onPick: _pick,
              onDucksChanged: (v) => setState(() => _ducks = v),
              onSave: _save,
            ),
            const Divider(height: 28),
            Text(
              cues.isEmpty ? 'No sounds yet.' : '${cues.length} on the bar',
              style: const TextStyle(
                color: SayawColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: cues.length,
                itemBuilder: (context, index) => _CueRow(
                  cue: cues[index],
                  shortcut: index < 9 ? '${index + 1}' : null,
                  onPlay: () => widget.access.fire(cues[index]),
                  onRemove: () => widget.access.removeCue(cues[index].id),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _AddCue extends StatelessWidget {
  const _AddCue({
    required this.picked,
    required this.label,
    required this.ducks,
    required this.error,
    required this.onPick,
    required this.onDucksChanged,
    required this.onSave,
  });

  final XFile? picked;
  final TextEditingController label;
  final bool ducks;
  final String? error;
  final VoidCallback onPick;
  final ValueChanged<bool> onDucksChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              height: kMinTouchTarget,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.audio_file_outlined, size: 18),
                label: const Text('Pick sound'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                picked == null
                    ? 'wav, mp3, flac, m4a, aiff, ogg'
                    : p.basename(picked!.path),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: picked == null
                      ? SayawColors.onSurfaceVariant
                      : SayawColors.onSurface,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: label,
          decoration: InputDecoration(
            labelText: 'Button label',
            isDense: true,
            errorText: error,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Semantics(
              label: 'Dip the music while this plays',
              toggled: ducks,
              child: Switch(value: ducks, onChanged: onDucksChanged),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                // The distinction that decides whether it is usable over
                // vocals, so it is said rather than left as a number.
                'Dip the music under it — for a spoken cue. A whistle cuts '
                'through on its own.',
                style: TextStyle(
                  color: SayawColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: kMinTouchTarget,
              child: FilledButton(onPressed: onSave, child: const Text('Add')),
            ),
          ],
        ),
      ],
    );
  }
}

class _CueRow extends StatelessWidget {
  const _CueRow({
    required this.cue,
    required this.shortcut,
    required this.onPlay,
    required this.onRemove,
  });

  final SoundCue cue;
  final String? shortcut;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Try ${cue.label}',
          excludeSemantics: true,
          child: SizedBox(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
            child: IconButton(
              icon: const Icon(Icons.play_arrow, size: 20),
              onPressed: onPlay,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cue.label,
                  style: const TextStyle(color: SayawColors.onSurface)),
              Text(
                cue.ducks ? 'Dips the music' : 'Plays over the music',
                style: const TextStyle(
                  color: SayawColors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (shortcut case final shortcut?)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              shortcut,
              style: const TextStyle(
                color: SayawColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        Semantics(
          button: true,
          label: 'Remove ${cue.label}',
          excludeSemantics: true,
          child: SizedBox(
            width: kMinTouchTarget,
            height: kMinTouchTarget,
            child: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens the soundboard manager.
class SoundboardButton extends ConsumerWidget {
  const SoundboardButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(soundboardProvider);

    return Semantics(
      button: true,
      enabled: access != null,
      label: 'Soundboard sounds',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: IconButton(
          icon: const Icon(Icons.graphic_eq),
          onPressed: access == null
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (_) => SoundboardSheet(access: access),
                  ),
        ),
      ),
    );
  }
}
