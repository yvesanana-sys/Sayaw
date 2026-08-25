import 'package:flutter/material.dart';

import '../touch/touch_targets.dart';

/// The Sayaw palette.
///
/// Hand-tuned rather than generated from a seed. `ColorScheme.fromSeed` is
/// convenient but it optimises for Material's tonal harmony, not for a room
/// with the house lights down — it happily emits mid-tone surfaces that glow,
/// and on-surface variants that land near 4.5:1 and drift below it as Material
/// retunes its algorithm between Flutter releases. Every pair below is pinned
/// and asserted against WCAG AA in `test/ui/theme_contrast_test.dart`, so a
/// framework upgrade cannot silently darken the only text a DJ can read at
/// 1am.
abstract final class SayawColors {
  /// Deepest ground. Almost black, with just enough blue to stop it reading as
  /// a dead pixel next to a real black bezel.
  static const background = Color(0xFF0E0E12);

  static const surface = Color(0xFF17171E);
  static const surfaceContainer = Color(0xFF1F1F28);
  static const surfaceContainerHigh = Color(0xFF2A2A36);

  static const onSurface = Color(0xFFECEAF2);
  static const onSurfaceVariant = Color(0xFFB9B4C7);

  /// Deck A, and the app's primary accent.
  static const primary = Color(0xFFC7A9F5);
  static const onPrimary = Color(0xFF12081F);

  /// Deck B. Distinct in hue *and* in lightness, so the two decks stay
  /// tellable apart for a red-green colour-blind operator.
  static const secondary = Color(0xFF7FD1C1);
  static const onSecondary = Color(0xFF00201A);

  /// Announcement / voice activity.
  static const tertiary = Color(0xFFF2C46B);
  static const onTertiary = Color(0xFF3D1400);

  static const error = Color(0xFFFF9A94);
  static const onError = Color(0xFF3B0906);

  static const outline = Color(0xFF6E6880);
  static const outlineVariant = Color(0xFF3A3648);
}

const ColorScheme sayawDarkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: SayawColors.primary,
  onPrimary: SayawColors.onPrimary,
  primaryContainer: Color(0xFF3A2A55),
  onPrimaryContainer: SayawColors.onSurface,
  secondary: SayawColors.secondary,
  onSecondary: SayawColors.onSecondary,
  secondaryContainer: Color(0xFF1B3D38),
  onSecondaryContainer: SayawColors.onSurface,
  tertiary: SayawColors.tertiary,
  onTertiary: SayawColors.onTertiary,
  tertiaryContainer: Color(0xFF43331A),
  onTertiaryContainer: SayawColors.onSurface,
  error: SayawColors.error,
  onError: SayawColors.onError,
  errorContainer: Color(0xFF4C1512),
  onErrorContainer: SayawColors.onSurface,
  surface: SayawColors.surface,
  onSurface: SayawColors.onSurface,
  surfaceContainerLowest: SayawColors.background,
  surfaceContainerLow: SayawColors.surface,
  surfaceContainer: SayawColors.surfaceContainer,
  surfaceContainerHigh: SayawColors.surfaceContainerHigh,
  surfaceContainerHighest: SayawColors.surfaceContainerHigh,
  onSurfaceVariant: SayawColors.onSurfaceVariant,
  outline: SayawColors.outline,
  outlineVariant: SayawColors.outlineVariant,
  inverseSurface: SayawColors.onSurface,
  onInverseSurface: SayawColors.background,
  inversePrimary: Color(0xFF5B3E8C),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
);

/// Dark is the only theme that gets polish, because it is the only one that
/// gets used. A light theme is offered for the rare daytime rehearsal, but it
/// is a courtesy, not a design target.
ThemeData sayawDarkTheme() {
  final scheme = sayawDarkColorScheme;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: SayawColors.background,
    canvasColor: SayawColors.background,

    // Material's default is `.padded` on desktop, which *shrinks* hit regions
    // to 4dp of padding around the visual bounds. On a touch screen that is
    // exactly wrong. Every tappable gets a real 48dp box.
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,

    splashFactory: InkRipple.splashFactory,

    iconTheme: const IconThemeData(color: SayawColors.onSurface, size: 24),

    dividerTheme: const DividerThemeData(
      color: SayawColors.outlineVariant,
      space: 1,
      thickness: 1,
    ),

    // Track and thumb both sized for a fingertip. The default 4dp track is
    // findable with a mouse and invisible to a thumb in a dark room.
    sliderTheme: SliderThemeData(
      trackHeight: 12,
      activeTrackColor: scheme.primary,
      inactiveTrackColor: SayawColors.surfaceContainerHigh,
      thumbColor: scheme.primary,
      overlayColor: scheme.primary.withValues(alpha: 0.16),
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: kSliderThumbRadius,
        elevation: 2,
      ),
      overlayShape: const RoundSliderOverlayShape(
        overlayRadius: kMinTouchTarget / 2,
      ),
    ),

    listTileTheme: const ListTileThemeData(
      minVerticalPadding: 12,
      minTileHeight: kMinTouchTarget + 8,
      iconColor: SayawColors.onSurfaceVariant,
      textColor: SayawColors.onSurface,
    ),

    navigationBarTheme: NavigationBarThemeData(
      height: kBottomNavHeight,
      backgroundColor: SayawColors.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: SayawColors.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      minWidth: kNavigationRailWidth,
      selectedIconTheme: IconThemeData(color: scheme.primary, size: 26),
      unselectedIconTheme:
          const IconThemeData(color: SayawColors.onSurfaceVariant, size: 26),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(kMinTouchTarget * 2, kMinTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(kMinTouchTarget * 2, kMinTouchTarget),
        side: const BorderSide(color: SayawColors.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: SayawColors.surfaceContainer,
      constraints: BoxConstraints(minHeight: kMinTouchTarget),
      border: OutlineInputBorder(),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: SayawColors.surfaceContainerHigh,
      contentTextStyle: TextStyle(color: SayawColors.onSurface),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
