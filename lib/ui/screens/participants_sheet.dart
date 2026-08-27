import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../state/jack_and_jill_provider.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// The people in the room.
///
/// Typed at a door, usually one-handed, usually while somebody is talking. The
/// field keeps focus after each name so a queue of arrivals goes in without
/// reaching for it again between them.
class ParticipantsSheet extends ConsumerStatefulWidget {
  const ParticipantsSheet({super.key, required this.access});

  final JackAndJillAccess access;

  @override
  ConsumerState<ParticipantsSheet> createState() => _ParticipantsSheetState();
}

class _ParticipantsSheetState extends ConsumerState<ParticipantsSheet> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    try {
      await widget.access.addParticipant(name);
      if (!mounted) return;
      setState(() => _error = null);
      _controller.clear();
    } on ArgumentError {
      if (!mounted) return;
      setState(() => _error = 'That needs a name.');
    }

    // Straight back to the field: the next person is already waiting.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(_participantsProvider).value ?? const [];
    final here = people.where((p) => p.isPresent).length;

    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Participants'),
      content: SizedBox(
        width: 420,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: InputDecoration(
                      labelText: 'Name',
                      isDense: true,
                      errorText: _error,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: kMinTouchTarget,
                  child: FilledButton(
                    onPressed: _add,
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              people.isEmpty
                  ? 'Nobody signed in yet.'
                  : '$here of ${people.length} here',
              style: const TextStyle(
                color: SayawColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: people.isEmpty
                  ? const SizedBox.shrink()
                  : ListView.builder(
                      itemCount: people.length,
                      itemBuilder: (context, index) => _PersonRow(
                        person: people[index],
                        onPresent: (present) => widget.access
                            .setPresent(people[index].id, present),
                        onRemove: () =>
                            widget.access.removeParticipant(people[index].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        if (people.any((p) => p.drawCount > 0))
          TextButton(
            onPressed: widget.access.resetDraws,
            child: const Text('Reset draws'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.onPresent,
    required this.onRemove,
  });

  final Participant person;
  final ValueChanged<bool> onPresent;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          label: '${person.name} is here',
          toggled: person.isPresent,
          child: Checkbox(
            value: person.isPresent,
            onChanged: (value) => onPresent(value ?? false),
          ),
        ),
        Expanded(
          child: Text(
            person.name,
            style: TextStyle(
              color: person.isPresent
                  ? SayawColors.onSurface
                  : SayawColors.onSurfaceVariant,
            ),
          ),
        ),
        if (person.drawCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              // Shown because a caller watching one number climb while
              // another stays at zero is the whole reason the count exists.
              '${person.drawCount}',
              style: const TextStyle(
                color: SayawColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        Semantics(
          button: true,
          label: 'Remove ${person.name}',
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

final _participantsProvider = StreamProvider<List<Participant>>((ref) {
  final access = ref.watch(jackAndJillProvider);
  return access?.watchParticipants() ?? const Stream.empty();
});
