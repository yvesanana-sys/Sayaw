import 'package:sayaw/ui/state/library_access.dart';

/// Joining rows with no set and no database behind it.
class FakeMerge implements MergeAccess {
  /// Every join written, as `(itemId, merge)`.
  final List<(String, bool)> joins = [];

  @override
  Future<void> setMergeIntoNext({
    required String itemId,
    required bool merge,
  }) async =>
      joins.add((itemId, merge));
}
