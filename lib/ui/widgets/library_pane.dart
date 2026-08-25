import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';
import 'keyboard_safe_area.dart';

/// Library browser.
///
/// A shell for this phase: the scan, the Plex/TIDAL sources and the real
/// queries land in Phase 4. What is real here is the interaction model — a
/// search field that survives the touch keyboard, and rows big enough to hit
/// with a thumb.
class LibraryPane extends ConsumerStatefulWidget {
  const LibraryPane({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<LibraryPane> createState() => _LibraryPaneState();
}

class _LibraryPaneState extends ConsumerState<LibraryPane> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final controller = ref.read(playbackProvider.notifier);

    final query = _search.text.trim().toLowerCase();
    final results = query.isEmpty
        ? queue
        : [
            for (final item in queue)
              if (item.title.toLowerCase().contains(query) ||
                  item.artist.toLowerCase().contains(query))
                item,
          ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
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
                        setState(() {});
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: KeyboardSafeArea(
            child: ListView.builder(
              // See the note in QueueList: the offset has to survive being
              // rebuilt at a different tree position on a breakpoint change.
              key: const PageStorageKey<String>('sayaw.library'),
              controller: widget.scrollController,
              itemCount: results.length,
              itemBuilder: (context, index) {
                final item = results[index];
                return _LibraryRow(
                  item: item,
                  onLoadA: item.isPlayable
                      ? () => controller.loadToDeck(DeckSlot.a, item)
                      : null,
                  onLoadB: item.isPlayable
                      ? () => controller.loadToDeck(DeckSlot.b, item)
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({
    required this.item,
    required this.onLoadA,
    required this.onLoadB,
  });

  final QueueItemUi item;
  final VoidCallback? onLoadA;
  final VoidCallback? onLoadB;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.isPlayable ? item.artist : item.unavailable!.message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: item.isPlayable
            ? null
            : const TextStyle(color: SayawColors.error),
      ),
      // Two explicit buttons rather than a hover-revealed overflow menu.
      // There is no hover on a tablet, and "long-press for options" is not
      // discoverable at 1am.
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LoadButton(
            label: 'Load ${item.title} to deck A',
            text: 'A',
            color: SayawColors.primary,
            onPressed: onLoadA,
          ),
          const SizedBox(width: 4),
          _LoadButton(
            label: 'Load ${item.title} to deck B',
            text: 'B',
            color: SayawColors.secondary,
            onPressed: onLoadB,
          ),
        ],
      ),
    );
  }
}

class _LoadButton extends StatelessWidget {
  const _LoadButton({
    required this.label,
    required this.text,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String text;
  final Color color;
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
          color: color.withValues(alpha: enabled ? 0.16 : 0.06),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: enabled
                      ? color
                      : SayawColors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
