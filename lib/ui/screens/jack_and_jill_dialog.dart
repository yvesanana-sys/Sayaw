import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/jack_and_jill.dart';
import '../state/jack_and_jill_provider.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// The Jack and Jill draw: a song and two names, read out to a room.
///
/// Big type and one thing at a time, because this gets read aloud off a tablet
/// at arm's length with the house lights down. Everything else on this screen
/// is for the operator; this is the one surface whose audience is the floor.
class JackAndJillDialog extends ConsumerStatefulWidget {
  const JackAndJillDialog({super.key, required this.access});

  final JackAndJillAccess access;

  @override
  ConsumerState<JackAndJillDialog> createState() => _JackAndJillDialogState();
}

class _JackAndJillDialogState extends ConsumerState<JackAndJillDialog> {
  String? _danceTypeId;
  Draw? _draw;
  Set<DrawProblem> _problems = const {};
  bool _busy = false;
  bool _committed = false;

  Future<void> _drawNow() async {
    final danceTypeId = _danceTypeId;
    if (danceTypeId == null) return;

    setState(() => _busy = true);
    final problems = await widget.access.problems(danceTypeId);
    final draw = problems.isEmpty ? await widget.access.draw(danceTypeId) : null;

    if (!mounted) return;
    setState(() {
      _problems = problems;
      _draw = draw;
      // A redraw has not been announced yet either.
      _committed = false;
      _busy = false;
    });
  }

  /// Takes the draw: counts it against both dancers and queues the song.
  Future<void> _take() async {
    final draw = _draw;
    if (draw == null || !draw.isComplete) return;

    setState(() => _busy = true);
    await widget.access.commit(draw);
    await widget.access.addToSet(draw.track!.id);

    if (!mounted) return;
    setState(() {
      _committed = true;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final danceTypes = ref.watch(_danceTypesProvider).value ?? const [];

    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Jack and Jill'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DancePicker(
              danceTypes: danceTypes,
              value: _danceTypeId,
              enabled: !_busy,
              onChanged: (id) => setState(() {
                _danceTypeId = id;
                _draw = null;
                _problems = const {};
              }),
            ),
            const SizedBox(height: 20),
            _body(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(_committed ? 'Done' : 'Close'),
        ),
        if (_draw?.isComplete ?? false)
          TextButton(
            onPressed: _busy ? null : _drawNow,
            child: const Text('Draw again'),
          ),
        FilledButton(
          onPressed: _busy || _danceTypeId == null
              ? null
              : (_draw?.isComplete ?? false)
                  ? (_committed ? null : _take)
                  : _drawNow,
          child: Text((_draw?.isComplete ?? false)
              ? (_committed ? 'Taken' : 'Take it')
              : 'Draw'),
        ),
      ],
    );
  }

  Widget _body() {
    if (_problems.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final problem in _problems)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                _describe(problem),
                style: const TextStyle(color: SayawColors.error),
              ),
            ),
        ],
      );
    }

    if (_draw case final draw? when draw.isComplete) {
      return _DrawResult(draw: draw, committed: _committed);
    }

    return const Text(
      'Picks a track from the dance you choose and two people who are '
      'signed in and still here.',
      style: TextStyle(color: SayawColors.onSurfaceVariant),
    );
  }

  static String _describe(DrawProblem problem) => switch (problem) {
        DrawProblem.notEnoughDancers =>
          'Two people have to be signed in and still here. Add them on the '
              'participants list first.',
        DrawProblem.noTracks =>
          'Nothing in the library is filed under this dance yet.',
      };
}

/// Read out to a room, so the names are the biggest thing on it.
class _DrawResult extends StatelessWidget {
  const _DrawResult({required this.draw, required this.committed});

  final Draw draw;
  final bool committed;

  @override
  Widget build(BuildContext context) {
    final names = [for (final dancer in draw.dancers) dancer.name];

    return Semantics(
      liveRegion: true,
      label: '${names.join(' and ')}, dancing ${draw.danceType?.name ?? ''} '
          'to ${draw.track?.title ?? ''}.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            names.join('  &  '),
            style: const TextStyle(
              color: SayawColors.onSurface,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            draw.track!.title,
            style: const TextStyle(color: SayawColors.onSurface, fontSize: 16),
          ),
          if (draw.track!.artist case final artist?)
            Text(
              artist,
              style: const TextStyle(
                color: SayawColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            committed
                // The two halves of "taken", said plainly, because an operator
                // who is not sure whether the song is queued will queue it
                // twice.
                ? 'Counted for both, and added to the end of the set.'
                : 'Not counted yet — draw again if these two just danced.',
            style: TextStyle(
              color: committed
                  ? SayawColors.secondary
                  : SayawColors.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DancePicker extends StatelessWidget {
  const _DancePicker({
    required this.danceTypes,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final List<DanceType> danceTypes;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Dance to draw from',
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Dance',
          isDense: true,
        ),
        items: [
          for (final danceType in danceTypes)
            DropdownMenuItem(value: danceType.id, child: Text(danceType.name)),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

final _danceTypesProvider = StreamProvider<List<DanceType>>((ref) {
  final access = ref.watch(jackAndJillProvider);
  return access?.watchDanceTypes() ?? const Stream.empty();
});

/// Opens the draw.
class JackAndJillButton extends ConsumerWidget {
  const JackAndJillButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(jackAndJillProvider);

    return Semantics(
      button: true,
      enabled: access != null,
      label: 'Jack and Jill draw',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: IconButton(
          icon: const Icon(Icons.casino_outlined),
          onPressed: access == null
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (_) => JackAndJillDialog(access: access),
                  ),
        ),
      ),
    );
  }
}
