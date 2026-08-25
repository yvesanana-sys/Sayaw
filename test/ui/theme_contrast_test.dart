import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/theme/contrast.dart';
import 'package:sayaw/ui/theme/sayaw_theme.dart';

/// These rooms have the house lights down and the operator is reading a tablet
/// at arm's length at 1am. Contrast is not a checkbox here.
///
/// Pinning every pair means a Material retune in a future Flutter release
/// cannot quietly push a colour below AA — which is the failure mode of
/// generating a scheme from a seed and trusting it.
void main() {
  group('WCAG maths', () {
    test('known reference ratios', () {
      // The two extremes, from the WCAG definition itself.
      expect(
        contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21.0, 0.01),
      );
      expect(
        contrastRatio(const Color(0xFF808080), const Color(0xFF808080)),
        closeTo(1.0, 0.001),
      );
    });

    test('is symmetric in its arguments', () {
      const a = Color(0xFF1E88E5);
      const b = Color(0xFFECEAF2);
      expect(contrastRatio(a, b), closeTo(contrastRatio(b, a), 1e-12));
    });
  });

  group('dark theme meets WCAG AA', () {
    const surfaces = {
      'background': SayawColors.background,
      'surface': SayawColors.surface,
      'surfaceContainer': SayawColors.surfaceContainer,
      'surfaceContainerHigh': SayawColors.surfaceContainerHigh,
    };

    const bodyText = {
      'onSurface': SayawColors.onSurface,
      'onSurfaceVariant': SayawColors.onSurfaceVariant,
      'primary': SayawColors.primary,
      'secondary': SayawColors.secondary,
      'tertiary': SayawColors.tertiary,
      'error': SayawColors.error,
    };

    for (final text in bodyText.entries) {
      for (final surface in surfaces.entries) {
        test('${text.key} on ${surface.key}', () {
          final ratio = contrastRatio(text.value, surface.value);
          expect(
            ratio,
            greaterThanOrEqualTo(kWcagAaNormalText),
            reason: '${text.key} on ${surface.key} is '
                '${ratio.toStringAsFixed(2)}:1, below AA for body text',
          );
        });
      }
    }

    test('accent fills carry readable labels', () {
      const pairs = [
        ('primary', SayawColors.onPrimary, SayawColors.primary),
        ('secondary', SayawColors.onSecondary, SayawColors.secondary),
        ('tertiary', SayawColors.onTertiary, SayawColors.tertiary),
        ('error', SayawColors.onError, SayawColors.error),
      ];

      for (final (name, on, fill) in pairs) {
        final ratio = contrastRatio(on, fill);
        expect(
          ratio,
          greaterThanOrEqualTo(kWcagAaNormalText),
          reason: 'on$name over $name is ${ratio.toStringAsFixed(2)}:1',
        );
      }
    });

    test('outlines are distinguishable from the surfaces they divide', () {
      final ratio =
          contrastRatio(SayawColors.outline, SayawColors.surfaceContainer);
      expect(
        ratio,
        greaterThanOrEqualTo(kWcagAaNonText),
        reason: 'control borders must clear 3:1 to be visible at all',
      );
    });

    test('the ColorScheme actually uses the audited colours', () {
      // Guards against the theme being rebuilt from a seed later while these
      // tests keep passing against constants nothing renders.
      final theme = sayawDarkTheme();
      expect(theme.colorScheme.surface, SayawColors.surface);
      expect(theme.colorScheme.onSurface, SayawColors.onSurface);
      expect(theme.colorScheme.onSurfaceVariant, SayawColors.onSurfaceVariant);
      expect(theme.colorScheme.primary, SayawColors.primary);
      expect(theme.scaffoldBackgroundColor, SayawColors.background);
      expect(theme.brightness, Brightness.dark);
    });
  });
}
