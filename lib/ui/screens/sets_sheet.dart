import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../data/db/database.dart';
import '../../data/set_bundle.dart';
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

  /// A copy, now, under a name nobody has to type: the set's own name and
  /// the moment. The end of a night that went well is one tap.
  Future<void> _quickSave() async {
    final openName = ref.read(setNameProvider);
    final now = DateTime.now();
    final stamp = '${now.year}-${_two(now.month)}-${_two(now.day)} '
        '${_two(now.hour)}:${_two(now.minute)}';
    final name = '${openName.isEmpty ? 'Set' : openName} $stamp';

    final messenger = ScaffoldMessenger.maybeOf(context);
    final id = await widget.access.saveSetAs(name);
    if (!mounted) return;
    if (id == null) {
      setState(() => _error = 'No set is open to save.');
      return;
    }
    setState(() => _error = null);
    messenger?.showSnackBar(SnackBar(content: Text('Saved a copy as "$name"')));
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

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

  /// Writes a set to a folder the operator picks — a stick, a cloud folder —
  /// and asks whether the music goes with it. It usually should: the file
  /// alone opens only where the same music already is.
  Future<void> _export(Playlist set) async {
    final folder = await getDirectoryPath();
    if (folder == null || !mounted) return;

    final copy = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SayawColors.surfaceContainer,
        title: Text('Save "${set.name}" to ${p.basename(folder)}'),
        content: const Text(
          'Copy the music and announcer recordings beside it? Then the set '
          'opens on any machine the folder is plugged into. Without them it '
          'opens only where that music is already in the library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Just the set file'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Copy everything'),
          ),
        ],
      ),
    );
    if (copy == null || !mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _error = null);
    try {
      final report = await widget.access
          .exportSet(set.id, into: Directory(folder), copyMedia: copy);
      messenger?.showSnackBar(SnackBar(
        content: Text(
          'Saved ${p.basename(report.file.path)} — ${report.rows} songs'
          '${copy ? ', ${report.copied} files copied' : ''}'
          '${report.skippedRemote == 0 ? '' : '; ${report.skippedRemote} on a server were left out'}',
        ),
      ));
    } on Object catch (e) {
      if (mounted) setState(() => _error = 'Could not save: $e');
    }
  }

  /// Reads a `.sayawset` file the operator picks, and opens the set.
  Future<void> _import() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(label: 'Sayaw set', extensions: [SetBundle.extension]),
    ]);
    if (file == null || !mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    setState(() => _error = null);
    try {
      final report = await widget.access.importSet(File(file.path));
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(
        content: Text(
          'Opened "${report.name}" — ${report.rows} songs'
          '${report.soundsAdded == 0 ? '' : ', ${report.soundsAdded} announcers added'}'
          '${report.missing.isEmpty ? '' : '; ${report.missing.length} not found: ${report.missing.take(3).join(', ')}${report.missing.length > 3 ? '…' : ''}'}',
        ),
      ));
      if (widget.access.isRunning) {
        setState(() => _error =
            '"${report.name}" is saved. Stop the music to put it on the decks.');
        return;
      }
      navigator.pop();
    } on FormatException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on Object catch (e) {
      if (mounted) setState(() => _error = 'Could not open that file: $e');
    }
  }

  Future<void> _rename(Playlist set) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(
        title: 'Rename set',
        hint: set.name,
        action: 'Rename',
        initial: set.name,
      ),
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

  /// File and folder pickers walk `dart:io` paths, which is the desktop.
  static bool get _canUseFiles =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

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
            SizedBox(
              width: double.infinity,
              height: kMinTouchTarget,
              child: FilledButton.icon(
                onPressed: _quickSave,
                icon: const Icon(Icons.bolt, size: 18),
                label: Text(openName.isEmpty
                    ? 'Quick save'
                    : 'Quick save "$openName" now'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              openName.isEmpty
                  ? 'Or save the open set as'
                  : 'Or save a copy of "$openName" as',
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  height: kMinTouchTarget,
                  child: OutlinedButton.icon(
                    onPressed: _newSet,
                    icon: const Icon(Icons.playlist_add, size: 18),
                    label: const Text('New empty set'),
                  ),
                ),
                if (_canUseFiles)
                  SizedBox(
                    height: kMinTouchTarget,
                    child: OutlinedButton.icon(
                      onPressed: _import,
                      icon: const Icon(Icons.file_open_outlined, size: 18),
                      label: const Text('Open a .sayawset file'),
                    ),
                  ),
              ],
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
                  onExport: _canUseFiles ? () => _export(sets[index]) : null,
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
    required this.onExport,
    required this.onDelete,
  });

  final Playlist set;
  final bool isOpen;
  final VoidCallback onOpen;
  final VoidCallback onRename;

  /// Null where there is no folder picker to save into.
  final VoidCallback? onExport;
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
        if (onExport case final export?)
          _IconAction(
            icon: Icons.drive_file_move_outlined,
            label: 'Save ${set.name} to a folder or USB stick',
            onPressed: export,
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

/// Asks for a name and saves a copy of the open set under it.
///
/// The one thing an operator does most, on its own button rather than inside
/// the sheet: at the end of a night that went well, "save this" should be
/// one tap and a name.
Future<void> showSaveSetDialog(BuildContext context, SetsAccess access) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final name = await showDialog<String>(
    context: context,
    builder: (_) => const _NameDialog(
      title: 'Save a copy of this set as',
      hint: 'Saturday social',
      action: 'Save',
    ),
  );
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return;
  final id = await access.saveSetAs(trimmed);
  messenger?.showSnackBar(SnackBar(
    content: Text(id == null
        ? 'No set is open to save.'
        : 'Saved a copy as "$trimmed"'),
  ));
}

/// A name, and nothing else.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.hint,
    required this.action,
    this.initial = '',
  });

  final String title;
  final String hint;
  final String action;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
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
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(hintText: widget.hint),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.action),
        ),
      ],
    );
  }
}

/// Opens the sets sheet from the queue's toolbar.
class SetsButton extends ConsumerWidget {
  const SetsButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(setsProvider);
    return QueueToolbarButton(
      icon: Icons.folder_special_outlined,
      text: 'Sets',
      label: 'Sets: open, rename or remove one',
      onPressed: access == null ? null : () => showSetsSheet(context, access),
    );
  }
}

/// Saves a copy of the open set, from the queue's toolbar.
class SaveSetButton extends ConsumerWidget {
  const SaveSetButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(setsProvider);
    return QueueToolbarButton(
      icon: Icons.save_outlined,
      text: 'Save',
      label: 'Save a copy of this set',
      onPressed:
          access == null ? null : () => showSaveSetDialog(context, access),
    );
  }
}

/// One of the buttons across the top of the queue: an icon and a word, a
/// fingertip tall, and its own label because a word on a button is not the
/// whole of what it does.
class QueueToolbarButton extends StatelessWidget {
  const QueueToolbarButton({
    super.key,
    required this.icon,
    required this.text,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.color,
  });

  final IconData icon;
  final String text;
  final String label;
  final VoidCallback? onPressed;

  /// Drawn as "on": the mixer with every row joined.
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? SayawColors.primary;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: kMinTouchTarget,
        child: FilledButton.tonal(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: active
                ? accent.withValues(alpha: 0.24)
                : SayawColors.surfaceContainerHigh,
            foregroundColor: active ? accent : SayawColors.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            side: active ? BorderSide(color: accent, width: 1.5) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(text),
            ],
          ),
        ),
      ),
    );
  }
}
