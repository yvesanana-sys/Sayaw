import 'package:flutter/widgets.dart';

/// How much room the window has, expressed as intent rather than hardware.
///
/// Deliberately derived from *width alone*, never from `Platform.isWindows` or
/// a device-type guess. A DJ can dock a Surface into a keyboard and drag the
/// window from a quarter of the screen to full-screen mid-set; the same binary
/// has to be right on both sides of that drag. Anything keyed to device type
/// gets that wrong.
enum SayawBreakpoint {
  /// Phone, or a tablet held in portrait, or a deliberately narrow window.
  /// Single pane, bottom navigation, decks stacked with the crossfader between.
  compact,

  /// Small laptop or a tablet in landscape. Two panes and a navigation rail.
  medium,

  /// Desktop. Library, decks and queue all visible at once.
  expanded;

  bool get isCompact => this == SayawBreakpoint.compact;
  bool get isMedium => this == SayawBreakpoint.medium;
  bool get isExpanded => this == SayawBreakpoint.expanded;

  /// True where a navigation rail replaces bottom navigation.
  bool get usesRail => this != SayawBreakpoint.compact;
}

/// Lower bound of [SayawBreakpoint.medium], in logical pixels.
const double kMediumBreakpoint = 700.0;

/// Lower bound of [SayawBreakpoint.expanded], in logical pixels.
const double kExpandedBreakpoint = 1100.0;

/// The whole breakpoint rule, as a pure function so it can be tested without
/// pumping a widget tree.
///
/// Boundaries follow the spec exactly: `< 700` is compact, `700..1100`
/// inclusive is medium, `> 1100` is expanded.
SayawBreakpoint breakpointForWidth(double width) {
  if (width < kMediumBreakpoint) return SayawBreakpoint.compact;
  if (width <= kExpandedBreakpoint) return SayawBreakpoint.medium;
  return SayawBreakpoint.expanded;
}

/// Publishes the current [SayawBreakpoint] to the subtree.
///
/// This is an [InheritedWidget] rather than a plain `LayoutBuilder` callback so
/// that a widget deep in the tree can read the breakpoint without every layer
/// in between having to thread it through — and, more importantly, so that a
/// resize rebuilds only the widgets that actually depend on it. Anything
/// holding playback or scroll state stays put across the transition.
class SayawLayout extends StatelessWidget {
  const SayawLayout({super.key, required this.builder});

  final Widget Function(BuildContext context, SayawBreakpoint breakpoint)
      builder;

  /// The breakpoint for the nearest enclosing [SayawLayout].
  ///
  /// Falls back to the raw window width when there is no [SayawLayout] above —
  /// which keeps isolated widget tests from needing a full shell just to render
  /// one control.
  static SayawBreakpoint of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_BreakpointScope>();
    return scope?.breakpoint ??
        breakpointForWidth(MediaQuery.sizeOf(context).width);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // maxWidth, not MediaQuery: inside a split pane or a dialog the window
        // is wider than the space this subtree actually got, and laying out for
        // the window would overflow.
        final breakpoint = breakpointForWidth(constraints.maxWidth);
        return _BreakpointScope(
          breakpoint: breakpoint,
          child: Builder(builder: (context) => builder(context, breakpoint)),
        );
      },
    );
  }
}

class _BreakpointScope extends InheritedWidget {
  const _BreakpointScope({required this.breakpoint, required super.child});

  final SayawBreakpoint breakpoint;

  @override
  bool updateShouldNotify(_BreakpointScope oldWidget) =>
      oldWidget.breakpoint != breakpoint;
}
