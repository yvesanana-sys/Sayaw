import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'playback_ui_state.dart';

/// How many tracks the library holds, or null when there is no library to ask.
///
/// Null rather than zero for "cannot tell". They are not the same answer and
/// treating them alike is what would put a first-run screen in front of an
/// operator mid-set the moment a provider was not wired.
final libraryCountProvider = FutureProvider<int?>((ref) async {
  final library = ref.watch(libraryAccessProvider);
  if (library == null) return null;
  try {
    return await library.libraryCount();
  } on Object {
    // A database that will not answer is not an empty one.
    return null;
  }
});

/// Whether this is somebody's first time here — no music, nothing to play.
///
/// Deliberately conservative. It is true only when the library answered and
/// answered zero: while the count is still loading, and whenever there is no
/// library to ask, the app shows what it always showed. The cost of being
/// wrong in one direction is a first-time operator staring at four empty panes;
/// the cost in the other is a set screen replaced by a wizard in front of a
/// floor, which is far worse.
final isFirstRunProvider = Provider<bool>((ref) {
  return ref.watch(libraryCountProvider).maybeWhen(
        data: (count) => count == 0,
        orElse: () => false,
      );
});
