import 'package:sayaw/data/db/database.dart';
import 'package:sayaw/ui/state/library_access.dart';

/// Removing and restoring with no set behind it.
class FakeQueueEdit implements QueueEditAccess {
  final List<String> removed = [];
  final List<String> restored = [];

  @override
  Future<RemovedRow?> removeFromSet(String itemId) async {
    removed.add(itemId);
    return RemovedRow(
      title: 'Track $itemId',
      item: PlaylistItem(
        id: itemId,
        playlistId: 'set',
        position: 1.0,
        itemType: PlaylistItemType.track,
        startOffsetMs: Duration.zero,
        gainOffsetDb: 0.0,
        pauseAfter: false,
        mergeIntoNext: false,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
  }

  @override
  Future<void> restoreToSet(RemovedRow row) async => restored.add(row.item.id);
}
