import 'package:flutter/material.dart';

import '../theme/sayaw_theme.dart';

/// The title row atop a column pane.
///
/// Library already carries its own header — a search field. This is for the
/// panes beside it that had none, so all three read as one interface instead
/// of three unrelated lists dropped next to each other.
class PaneHeader extends StatelessWidget {
  const PaneHeader({super.key, required this.icon, required this.title, this.trailing});

  final IconData icon;
  final String title;

  /// A count or action drawn at the far edge — e.g. how many tracks are queued.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: SayawColors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: SayawColors.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
