import 'package:flutter/widgets.dart';

/// Minimum hit region for any interactive element, in logical pixels.
///
/// Matches the Material and WCAG 2.2 target-size floor. This is a *hit region*,
/// not a paint size — a 24dp icon centred in a 48dp box is correct and
/// preferred; a 24dp icon in a 24dp box is a bug.
const double kMinTouchTarget = 48.0;

/// Minimum hit region for transport controls — play, cue, load-to-deck,
/// crossfade-now.
///
/// Larger than the general floor on purpose. These are hit under pressure, in
/// the dark, often without looking, and the cost of missing one is audible to
/// a room full of people. The extra 16dp is cheap insurance.
const double kTransportTouchTarget = 64.0;

/// Gap between adjacent transport buttons. Two 64dp targets flush against each
/// other are easy to mis-hit at the seam.
const double kTransportSpacing = 12.0;

/// Slider thumb radius. 14dp of paint inside a 48dp overlay: visible across a
/// dim booth, and grabbable without precision.
const double kSliderThumbRadius = 14.0;

/// Height of the crossfader's touch strip in compact layouts.
const double kCrossfaderHeight = 72.0;

/// Bottom navigation height in compact layouts.
const double kBottomNavHeight = 72.0;

/// Navigation rail width in medium and expanded layouts.
const double kNavigationRailWidth = 88.0;

/// Wraps [child] in a hit region of at least [size] x [size] without changing
/// how big it paints.
///
/// Use this instead of padding the child: padding grows the visual element too,
/// which is how a tidy 24dp icon becomes a 48dp blob. This keeps the paint and
/// the target independent, which is the entire point.
class MinTouchTarget extends StatelessWidget {
  const MinTouchTarget({
    super.key,
    required this.child,
    this.size = kMinTouchTarget,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    );
  }
}
