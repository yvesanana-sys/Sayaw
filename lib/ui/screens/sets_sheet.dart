import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../state/library_access.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// Opens the sets sheet.
Future<void> showSetsSheet(BuildContext context, SetsAccess access) =>
    showDialog<void>(
      context: context,
      builder: (_) => SetsSheet(access: access),
    );

/// The sets the operator keeps: save the open one under a name, start a new
/// one, put a saved one on the decks.
///
/// "Save" here is a copy. The set being played is already a playlist and
/// every edit lands in it as it is made — a tag, a join, a drag — so there is
/// nothing to save in the sense of "write it down". What an operator means
/// by saving is keeping tonight's arrangement somewhere next week's edits
/// will not reach, and that is a copy under a name.
class SetsSheet extends ConsumerStatefulWidget {
  const SetsSheet({super.key, required this.access});

  final SetsAccess access;

  @override
  ConsumerState<SetsSheet> createState() => _SetsSheetState();
}

class _SetsSheetState extends ConsumerState<SetsSheet> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _saveAs() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the copy a name.');
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    final id = await widget.access.saveSetAs(name);
    if (!mounted) return;
    if (id == null) {
      setState(() => _error = 'No set is open to save.');
      return;
    }
    setState(() {
      _name.clear();
      _error = null;
    });
    messenger?.showSnackBar(SnackBar(content: Text('Saved a copy as "$name"')));
  }

  Future<void> _newSet() async {
    final name = _name.text.trim().isEmpty ? 'New set' : _name.text.trim();
    final navigator = Navigator.of(context);
    await widget.access.newSet(name);
    if (!mounted) return;
    if (widget.access.isRunning) {
      setState(() => _error =
          '"$name" is saved. Stop the music to put it on the decks.');
      return;
    }
    navigator.pop();
  }

  Future<void> _open(Playlist set) async {
    final navigator = Navigator.of(context);
    final opened = await widget.access.openSet(set.id);
    if (!mounted) return;
    if (!opened) {
      setState(() => _error = 'Stop the music before opening another set.');
      return;
    }
    navigator.pop();
  }

  Future<void> _rename(Playlist set) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: set.name),
    );
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == set.name) return;
    await widget.access.renameSet(set.id, trimmed);
  }

  Future<void> _delete(Playlist set) async {
    final isOpen = set.id == widget.access.openPlaylistId;
    if (isOpen && widget.access.isRunning) {
      setState(() => _error = 'Stop the music before removing the open set.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SayawColors.surfaceContainer,
        title: Text('Remove "${set.name}"?'),
        content: const Text(
          'The set and its arrangement go. The music stays in the library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SayawColors.error,
              foregroundColor: SayawColors.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.access.deleteSet(set.id);
  }

  @override
  Widget build(BuildContext context) {
    final sets = ref.watch(_setsListProvider).value ?? const <Playlist>[];
    final openId = widget.access.openPlaylistId;
    final openName = ref.watch(setNameProvider);

    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Sets'),
      content: SizedBox(
        width: 460,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              openName.isEmpty
                  ? 'Save the open set as'
                  : 'Save a copy of "$openName" as',
              style: const TextStyle(
                fontSize: 12,
                color: SayawColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveAs(),
                    decoration: const InputDecoration(
                      hintText: 'Saturday social',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: kMinTouchTarget,
                  child: FilledButton.icon(
                    onPressed: _saveAs,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save copy'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: kMinTouchTarget,
              child: OutlinedButton.icon(
                onPressed: _newSet,
                icon: const Icon(Icons.playlist_add, size: 18),
                label: const Text('New empty set'),
              ),
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style:
                    const TextStyle(fontSize: 12, color: SayawColors.error),
              ),
            ],
            const Divider(height: 28),
            Text(
              sets.isEmpty ? 'No sets yet.' : '${sets.length} saved',
              style: const TextStyle(
                color: SayawColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: sets.length,
                itemBuilder: (context, index) => _SetRow(
                  set: sets[index],
                  isOpen: sets[index].id == openId,
                  onOpen: () => _open(sets[index]),
                  onRename: () => _rename(sets[index]),
                  onDelete: () => _delete(sets[index]),
                ),
              ),
            ),
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

/// Owns its controller, so it is disposed when the dialog is and not a
/// frame before — a dialog animating out still draws its field.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Rename set'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Rename'),
        ),
      ],
    );
  }
}

final _setsListProvider = StreamProvider<List<Playlist>>((ref) {
  final access = ref.watch(setsProvider);
  return access?.watchSets() ?? const Stream.empty();
});

class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.set,
    required this.isOpen,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final Playlist set;
  final bool isOpen;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            button: true,
            selected: isOpen,
            label: isOpen ? '${set.name}, open' : 'Open ${set.name}',
            excludeSemantics: true,
            child: InkWell(
              onTap: isOpen ? null : onOpen,
              child: Container(
                constraints:
                    const BoxConstraints(minHeight: kMinTouchTarget),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Icon(
                      isOpen ? Icons.radio_button_checked : Icons.queue_music,
                      size: 20,
                      color: isOpen
                          ? SayawColors.primary
                          : SayawColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        set.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isOpen ? FontWeight.w700 : FontWeight.w500,
                          color: SayawColors.onSurface,
                        ),
                      ),
                    ),
                    if (isOpen)
                      const Text(
                        'open',
                        style: TextStyle(
                          fontSize: 11,
                          color: SayawColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _IconAction(
          icon: Icons.edit_outlined,
          label: 'Rename ${set.name}',
          onPressed: onRename,
        ),
        _IconAction(
          icon: Icons.close,
          label: 'Remove ${set.name}',
          color: SayawColors.error,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: InkWell(
          onTap: onPressed,
          child: Icon(icon, size: 18, color: color ?? SayawColors.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Opens the sets sheet from the queue's header.
class SetsButton extends ConsumerWidget {
  const SetsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(setsProvider);
    return Semantics(
      button: true,
      label: 'Sets: save, open or start one',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap:
                access == null ? null : () => showSetsSheet(context, access),
            child: const Icon(Icons.folder_special_outlined, size: 20),
          ),
        ),
      ),
    );
  }
}
