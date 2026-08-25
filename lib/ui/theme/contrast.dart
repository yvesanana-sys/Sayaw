import 'dart:math' as math;
import 'dart:ui' show Color;

/// WCAG 2.1 relative luminance of an opaque sRGB colour.
///
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double relativeLuminance(Color color) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// WCAG 2.1 contrast ratio between two opaque colours, in `[1, 21]`.
///
/// Order does not matter. Alpha is ignored: composite the colour against its
/// real background before calling this, or the number is a fiction.
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// AA threshold for body text (and any text below 18pt / 14pt-bold).
const double kWcagAaNormalText = 4.5;

/// AA threshold for large text — 18pt regular or 14pt bold and up.
const double kWcagAaLargeText = 3.0;

/// AA threshold for the visual boundary of an interactive control.
const double kWcagAaNonText = 3.0;
