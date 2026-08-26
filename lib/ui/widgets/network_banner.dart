import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/media_resolver.dart' show NetworkMode;
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';

/// One line across the top of the screen when the network is not what the set
/// was built against.
///
/// A single banner rather than an error per track — see ARCHITECTURE.md
/// §Graceful degradation. A forty-row set losing its Plex server would
/// otherwise throw forty identical toasts over the transport controls at the
/// worst possible moment.
///
/// Not dismissable, deliberately. The rows it explains stay greyed for as long
/// as the condition lasts, and an operator who had swiped it away would be
/// looking at a set that is skipping tracks with nothing on screen saying why.
class NetworkBanner extends ConsumerWidget {
  const NetworkBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(networkModeProvider);
    if (mode == NetworkMode.online) return const SizedBox.shrink();

    final services =
        ref.watch(playbackProvider.select((s) => s.offlineServices));

    final offline = mode == NetworkMode.localOnly;
    final colour = offline ? SayawColors.error : SayawColors.tertiary;
    final message = _message(mode, services);

    return Semantics(
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        color: SayawColors.surfaceContainerHigh,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              offline ? Icons.cloud_off : Icons.cloud_queue,
              size: 20,
              color: colour,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colour, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Says what stopped working and what still does, in that order.
  ///
  /// "Local files and downloads still play" is the half that matters at 11pm:
  /// the operator needs to know within one glance whether the night is over or
  /// merely narrower.
  static String _message(NetworkMode mode, List<String> services) {
    if (mode == NetworkMode.degraded) {
      return '${_list(services)} not reachable. Everything else plays normally.';
    }

    if (services.isEmpty) {
      return 'Offline. Local files and downloads still play.';
    }
    return 'Offline — ${_list(services)} not reachable. '
        'Local files and downloads still play.';
  }

  static String _list(List<String> names) => switch (names.length) {
        0 => 'The network is',
        1 => '${names.first} is',
        2 => '${names[0]} and ${names[1]} are',
        _ => '${names.length} servers are',
      };
}
