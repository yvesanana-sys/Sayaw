import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../format/track_title.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';
import 'keyboard_safe_area.dart';

/// Library browser: one search field across local files, Plex and TIDAL.
///
/// The aggregation happened at import time, so this still works with the venue
/// wifi down. Rows are big enough to hit with a thumb and the search field
/// survives the touch keyboard, because this is used mid-set, one-handed, in a
/// dark room.
class LibraryPane extends ConsumerStatefulWidget {
  const LibraryPane({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<LibraryPane> createState() => _LibraryPaneState();
}

class _LibraryPaneState extends ConsumerState<LibraryPane> {
  final _search = TextEditingController();

  Timer? _debounce;
  List<Track> _results = const [];
  bool _scanning = false;

  /// Which search the results on screen belong to. A slow query for "wa"
  /// returning after a fast one for "waltz" would otherwise overwrite it.
  String _shownQuery = '';

  @override
  void initState() {
    super.initState();
    // Whatever arrived most recently, which after importing a folder is the
    // thing the operator is about to go looking for.
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    setState(() {});
    _debounce?.cancel();

    // Long enough to skip the letters of a word being typed, short enough that
    // it still feels like the list is following along.
    _debounce = Timer(const Duration(milliseconds: 180), _runSearch);
  }

  Future<void> _runSearch() async {
    final library = ref.read(libraryAccessProvider);
    final query = _search.text.trim();

    if (library == null) {
      if (mounted) setState(() => _shownQuery = query);
      return;
    }

    final found = query.isEmpty
        ? await library.recentTracks()
        : await library.searchLibrary(query);
    if (!mounted || _search.text.trim() != query) return;

    setState(() {
      _results = found;
      _shownQuery = query;
    });
  }

  bool _addingAll = false;

  /// Adds everything the list is showing — every match for the current
  /// search, or the whole library with the field empty — to the set.
  ///
  /// Asks first, with the real number. The list on screen is capped and the
  /// library is not, so "all" can be four hundred rows, and there is no
  /// taking them back out yet. A confirmation that says "all 412" is the
  /// difference between building a set and burying one.
  Future<void> _addAll() async {
    final library = ref.read(libraryAccessProvider);
    if (library == null) return;
    final query = _search.text.trim();

    final ids = await library.everyTrackMatching(query);
    if (!mounted || ids.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SayawColors.surfaceContainer,
        title: const Text('Add to the set'),
        content: Text(
          query.isEmpty
              ? 'Add all ${ids.length} tracks in the library to the set, '
                  'in title order?'
              : 'Add all ${ids.length} tracks matching "$query" to the set, '
                  'in title order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Add ${ids.length}'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _addingAll = true);
    try {
      await library.addAllToSet(ids);
      messenger?.showSnackBar(
        SnackBar(content: Text('${ids.length} added to the set')),
      );
    } finally {
      if (mounted) setState(() => _addingAll = false);
    }
  }

  Future<void> _addFolder() async {
    final library = ref.read(libraryAccessProvider);
    if (library == null) return;

    final path = await getDirectoryPath();
    if (path == null || !mounted) return;

    setState(() => _scanning = true);
    try {
      final report = await library.scanFolders([Directory(path)]);
      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(
          '${report.added} added, ${report.updated} updated'
          '${report.problems.isEmpty ? '' : ', ${report.problems.length} without tags'}',
        ),
      ));
      await _runSearch();
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(libraryAccessProvider);
    final canAddFolder = library != null && _isDesktop;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => _onQueryChanged(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search library',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: null,
                            onPressed: () {
                              _search.clear();
                              _onQueryChanged();
                            },
                          ),
                  ),
                ),
              ),
              if (library != null && _results.isNotEmpty) ...[
                const SizedBox(width: 8),
                _AddAllButton(
                  busy: _addingAll,
                  query: _shownQuery,
                  onPressed: _addingAll ? null : _addAll,
                ),
              ],
              if (canAddFolder) ...[
                const SizedBox(width: 8),
                _AddFolderButton(
                  busy: _scanning,
                  onPressed: _scanning ? null : _addFolder,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: KeyboardSafeArea(
            child: _results.isEmpty
                ? _EmptyLibrary(
                    query: _shownQuery,
                    hasLibrary: library != null,
                    canAddFolder: canAddFolder,
                    onAddFolder: _addFolder,
                  )
                : ListView.builder(
                    // See the note in QueueList: the offset has to survive
                    // being rebuilt at a different tree position on a
                    // breakpoint change.
                    key: const PageStorageKey<String>('sayaw.library'),
                    controller: widget.scrollController,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final track = _results[index];
                      return _LibraryRow(
                        track: track,
                        onAdd: () => library!.addToSet(track.id),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  /// Folder import walks `dart:io` paths. On Android a folder picker hands
  /// back a SAF tree URI instead, which is a different import route and is not
  /// built yet — so the button is not offered rather than offered and inert.
  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({
    required this.query,
    required this.hasLibrary,
    required this.canAddFolder,
    required this.onAddFolder,
  });

  final String query;
  final bool hasLibrary;
  final bool canAddFolder;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    final message = switch ((hasLibrary, query.isEmpty)) {
      (false, _) => 'The library opens with the app.',
      (true, true) => 'Search your library, or add a folder of music.',
      (true, false) => 'Nothing matching "$query".',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SayawColors.onSurfaceVariant),
            ),
            if (canAddFolder && query.isEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onAddFolder,
                icon: const Icon(Icons.folder_open),
                label: const Text('Add music folder'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({required this.track, required this.onAdd});

  final Track track;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final title = displayTitle(track.title);
    final artist = track.artist ?? '';
    final album = track.album;

    return ListTile(
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        [artist, ?album].where((s) => s.isNotEmpty).join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // One explicit button rather than a hover-revealed overflow menu. There
      // is no hover on a tablet, and "long-press for options" is not
      // discoverable at 1am.
      trailing: _AddButton(
        label: 'Add $title to the set',
        onPressed: onAdd,
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Material(
          color: SayawColors.primary.withValues(alpha: enabled ? 0.16 : 0.06),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Icon(
              Icons.playlist_add,
              color: enabled
                  ? SayawColors.primary
                  : SayawColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

/// Adds everything the list is showing to the set.
///
/// Beside the folder button rather than at the foot of the list, because the
/// list is capped and its foot is not the end of the library. Shown only when
/// there is something to add: with the list empty there is nothing for it to
/// mean.
class _AddAllButton extends StatelessWidget {
  const _AddAllButton({
    required this.busy,
    required this.query,
    required this.onPressed,
  });

  final bool busy;
  final String query;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      label: busy
          ? 'Adding to the set'
          : query.isEmpty
              ? 'Add every track in the library to the set'
              : 'Add every track matching $query to the set',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Material(
          color: SayawColors.primary.withValues(alpha: busy ? 0.06 : 0.16),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add_check,
                      color: SayawColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddFolderButton extends StatelessWidget {
  const _AddFolderButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !busy,
      label: busy ? 'Scanning music folder' : 'Add a music folder',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Material(
          color: SayawColors.secondary.withValues(alpha: busy ? 0.06 : 0.16),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.create_new_folder_outlined,
                      color: SayawColors.secondary),
            ),
          ),
        ),
      ),
    );
  }
}
