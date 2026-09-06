import 'package:sayaw/ui/state/library_access.dart';

/// Tagging with no set and no database behind it.
class FakeCueTag implements CueTagAccess {
  /// Every tag written, as `(itemId, cueId)`. A null cue is a tag cleared.
  final List<(String, String?)> tagged = [];

  @override
  Future<void> tagSoundCue({
    required String itemId,
    required String? cueId,
  }) async =>
      tagged.add((itemId, cueId));
}
