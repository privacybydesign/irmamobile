import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";

/// WCAG 2.x contrast ratio of [a] on [b] (both opaque).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// [top] (possibly translucent) painted over [bottom].
Color over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

void main() {
  const aa = 4.5;
  // Large text (24 px, or 18.66 px bold) and icons.
  const large = 3.0;

  for (final theme in [IrmaThemeData(), IrmaThemeData.dark()]) {
    final palette = theme.isDark ? YiviPalette.dark : YiviPalette.light;
    final name = theme.isDark ? "dark" : "light";

    group("IrmaThemeData $name", () {
      test("body text on scaffolds, cards and sheets", () {
        for (final bg in [
          theme.backgroundPrimary,
          theme.backgroundSecondary,
          theme.backgroundTertiary,
          theme.surfacePrimary,
          theme.surfaceSecondary,
        ]) {
          expect(contrast(theme.dark, bg), greaterThanOrEqualTo(aa));
          expect(
            contrast(theme.neutralExtraDark, bg),
            greaterThanOrEqualTo(aa),
          );
        }
      });

      test("secondary text and links on cards", () {
        expect(
          contrast(theme.neutralDark, theme.surfacePrimary),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(theme.link, theme.surfacePrimary),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(theme.link, theme.backgroundPrimary),
          greaterThanOrEqualTo(aa),
        );
      });

      test("error text on the page and on its surface", () {
        expect(
          contrast(theme.error, theme.backgroundPrimary),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(theme.error, theme.errorSurface),
          greaterThanOrEqualTo(large),
        );
      });

      test("a filled button's label on its fill", () {
        expect(
          contrast(theme.light, theme.secondary),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(theme.onPrimary, theme.primary),
          greaterThanOrEqualTo(aa),
        );
      });
    });

    group("YiviPalette $name", () {
      test("dialog text on strong glass over the page", () {
        final card = over(palette.glassStrongFill, palette.background);
        expect(contrast(palette.heading, card), greaterThanOrEqualTo(aa));
        expect(contrast(palette.text, card), greaterThanOrEqualTo(aa));
      });

      test("status screen text on the background", () {
        expect(
          contrast(palette.heading, palette.background),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(palette.secondaryText, palette.background),
          greaterThanOrEqualTo(aa),
        );
      });

      test("tone disc icons on their discs", () {
        for (final (fill, ink) in [
          (palette.tint, palette.heading),
          (palette.tint, palette.link),
          (palette.successSurface, palette.successText),
          (palette.warningSurface, palette.warningText),
          (palette.errorSurface, palette.danger),
        ]) {
          expect(contrast(ink, fill), greaterThanOrEqualTo(large));
        }
      });

      test("field labels, errors and the danger button", () {
        expect(
          contrast(palette.heading, palette.background),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(palette.danger, palette.surface),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(Colors.white, palette.dangerFill),
          greaterThanOrEqualTo(aa),
        );
      });
    });
  }
}
