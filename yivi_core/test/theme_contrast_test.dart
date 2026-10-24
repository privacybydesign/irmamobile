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

      test("text on a card on a sheet", () {
        expect(
          contrast(palette.text, palette.raised),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(palette.secondaryText, palette.raised),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(palette.link, palette.raised),
          greaterThanOrEqualTo(aa),
        );
        expect(
          contrast(palette.link, palette.raisedTint),
          greaterThanOrEqualTo(large),
        );
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

  // Dark mode: every layer is lighter than the one it lies on.
  group("dark ladder", () {
    const p = YiviPalette.dark;
    final onSheet = YiviPalette.darkOnSheet;
    double l(Color c) => c.computeLuminance();
    void lighter(Color top, Color under) =>
        expect(l(over(top, under)), greaterThan(l(under)));

    test("pages are black", () {
      expect(p.background, const Color(0xFF000000));
      expect(IrmaThemeData.dark().backgroundPrimary, p.background);
    });

    test("cards on the page, chips on cards", () {
      lighter(p.surface, p.background);
      lighter(p.tint, p.surface);
    });

    test("sheets on the page, cards and chips on sheets", () {
      lighter(p.sheet, p.background);
      lighter(onSheet.surface, p.sheet);
      lighter(onSheet.tint, onSheet.surface);
      expect(onSheet.background, p.sheet);
    });

    test("floating glass above the cards that scroll under it", () {
      lighter(p.glassFill, p.background);
      expect(l(over(p.glassFill, p.background)), greaterThan(l(p.surface)));
      lighter(p.glassFill, p.surface);
    });

    test("dialogs above a sheet", () {
      lighter(p.glassStrongFill, p.sheet);
    });
  });
}
