import 'package:flutter/material.dart';

import '../touch/touch_targets.dart';

/// A single transport control.
///
/// The hit region is [size] square regardless of how big the glyph is, and the
/// semantics label is required rather than optional — a control a screen reader
/// announces as "button" is not operable, and the target-size guardrail test
/// finds these nodes by label.
///
/// Note there is no [Tooltip]. Tooltips on desktop appear on hover, which does
/// not exist on a tablet, so anything a tooltip would have said has to be in
/// the label (read aloud) or in the optional [caption] (drawn on screen).
class TransportButton extends StatelessWidget {
  const TransportButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = kTransportTouchTarget,
    this.color,
    this.background,
    this.caption,
    this.isActive = false,
  });

  final IconData icon;

  /// Announced by assistive tech and used as the widget's semantic identity.
  final String label;

  final VoidCallback? onPressed;
  final double size;
  final Color? color;
  final Color? background;

  /// Optional visible text under the glyph. On touch this replaces the hover
  /// tooltip a desktop app would have used.
  final String? caption;

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;

    final foreground = !enabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
        : color ?? scheme.onSurface;

    final fill = isActive
        ? (background ?? scheme.primary).withValues(alpha: 0.24)
        : background ?? scheme.surfaceContainerHigh;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: enabled ? fill : fill.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size / 4),
            side: isActive
                ? BorderSide(color: background ?? scheme.primary, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: size * 0.42, color: foreground),
                if (caption != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    caption!,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.1,
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
