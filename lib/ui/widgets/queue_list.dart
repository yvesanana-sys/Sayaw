import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../layout/breakpoints.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// The set list, reorderable by drag.
///
/// Reordering writes a single fractional position (see
/// `lib/data/fractional_order.dart`), so dragging one track in a 400-song event
/// playlist is one row write rather than four hundred.
class QueueList extends ConsumerWidget {
  const QueueList({super.key, this.scrollController});

  /// Owned by the screen, not by this widget, so the scroll offset survives a
  /// breakpoint change. Resizing the window mid-set must not fling the
  /// operator back to the top of the list.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playbackProvider.select((s) => s.queue));
    final currentIndex =
        ref.watch(playbackProvider.select((s) => s.currentIndex));
    final controller = ref.read(playbackProvider.notifier);
    final breakpoint = SayawLayout.of(context);

    if (queue.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Queue is empty.\nAdd tracks from the library.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SayawColors.onSurfaceVariant),
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      // A stable storage key, not just a retained ScrollController. Crossing a
      // breakpoint rebuilds this list at a different position in the tree,
      // which creates a fresh ScrollPosition; without a fixed key the offset
      // is derived from the tree path and is silently lost. The controller
      // alone is not enough.
      key: const PageStorageKey<String>('sayaw.queue'),
      scrollController: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: queue.length,
      // Default handles are placed by the framework and sized for a mouse.
      // We supply our own so the target is 48dp and the gesture is right for
      // the input the current layout implies.
      buildDefaultDragHandles: false,
      onReorderItem: controller.reorderQueue,
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black,
        child: child,
      ),
      itemBuilder: (context, index) {
        final item = queue[index];
        return _QueueRow(
          key: ValueKey(item.id),
          item: item,
          index: index,
          isCurrent: index == currentIndex,
          breakpoint: breakpoint,
        );
      },
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    super.key,
    required this.item,
    required this.index,
    required this.isCurrent,
    required this.breakpoint,
  });

  final QueueItemUi item;
  final int index;
  final bool isCurrent;
  final SayawBreakpoint breakpoint;

  @override
  Widget build(BuildContext context) {
    final unavailable = !item.isPlayable;

    final title = Text(
      item.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
        color: unavailable
            ? SayawColors.onSurfaceVariant
            : SayawColors.onSurface,
        decoration: unavailable ? TextDecoration.lineThrough : null,
      ),
    );

    final subtitle = Text(
      // The reason replaces the artist line rather than hiding behind a hover
      // tooltip: a track that will not play has to say so where it is read.
      unavailable ? item.unavailable!.message : item.artist,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        color:
            unavailable ? SayawColors.error : SayawColors.onSurfaceVariant,
      ),
    );

    return Semantics(
      container: true,
      label: unavailable
          ? '${item.title} by ${item.artist}. Unavailable: '
              '${item.unavailable!.message}'
          : '${item.title} by ${item.artist}'
              '${item.danceType == null ? '' : ', ${item.danceType}'}'
              '${isCurrent ? ', now playing' : ''}',
      child: Container(
        constraints: const BoxConstraints(minHeight: kMinTouchTarget + 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? SayawColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isCurrent ? SayawColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SayawColors.onSurfaceVariant,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [title, subtitle],
                ),
              ),
            ),
            if (item.danceType != null && !breakpoint.isCompact) ...[
              _DanceChip(item.danceType!),
              const SizedBox(width: 8),
            ],
            QueueDragHandle(index: index, breakpoint: breakpoint, item: item),
          ],
        ),
      ),
    );
  }
}

/// The grab area for a reorder.
///
/// Compact layouts imply a finger, so the drag starts on a long-press: an
/// explicit handle plus a delay means a flick to scroll the set list can never
/// be misread as picking a track up mid-event. Wider layouts imply a mouse,
/// where waiting half a second before a drag begins just feels broken, so the
/// drag starts on press.
@visibleForTesting
class QueueDragHandle extends StatelessWidget {
  const QueueDragHandle({
    super.key,
    required this.index,
    required this.breakpoint,
    required this.item,
  });

  final int index;
  final SayawBreakpoint breakpoint;
  final QueueItemUi item;

  @override
  Widget build(BuildContext context) {
    final handle = Semantics(
      button: true,
      label: 'Reorder ${item.title}',
      child: const SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: Icon(
          Icons.drag_handle,
          color: SayawColors.onSurfaceVariant,
        ),
      ),
    );

    return breakpoint.isCompact
        ? ReorderableDelayedDragStartListener(index: index, child: handle)
        : ReorderableDragStartListener(index: index, child: handle);
  }
}

class _DanceChip extends StatelessWidget {
  const _DanceChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SayawColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: SayawColors.onSurfaceVariant,
        ),
      ),
    );
  }
}
