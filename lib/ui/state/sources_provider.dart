import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/sources_access.dart';

/// Connecting and disconnecting services, or null where there is nothing to
/// connect to — every widget test, and the moment before the runtime has
/// finished starting.
///
/// A plain [Provider] in front of the notifier so a test can override it with
/// a value; the notifier behind it is what the bootstrap writes to.
final sourcesProvider =
    Provider<SourcesAccess?>((ref) => ref.watch(sourcesHolderProvider));

final sourcesHolderProvider =
    NotifierProvider<SourcesHolder, SourcesAccess?>(SourcesHolder.new);

class SourcesHolder extends Notifier<SourcesAccess?> {
  @override
  SourcesAccess? build() => null;

  void set(SourcesAccess? sources) => state = sources;
}
