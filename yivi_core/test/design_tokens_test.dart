import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/yivi_motion.dart";
import "package:yivi_core/src/theme/yivi_palette.dart";
import "package:yivi_core/src/theme/yivi_space.dart";

void main() {
  group("text roles", () {
    // Role, size, weight, font.
    final roles =
        <(String, TextStyle Function(YiviPalette), double, FontWeight, String)>[
          (
            "titleResult",
            (p) => p.titleResult,
            26,
            FontWeight.w700,
            "Alexandria",
          ),
          ("titleStep", (p) => p.titleStep, 24, FontWeight.w700, "Alexandria"),
          (
            "titleCompact",
            (p) => p.titleCompact,
            22,
            FontWeight.w700,
            "Alexandria",
          ),
          (
            "sectionHeader",
            (p) => p.sectionHeader,
            16,
            FontWeight.w600,
            "Alexandria",
          ),
          ("rowTitle", (p) => p.rowTitle, 16, FontWeight.w400, "Open Sans"),
          ("paragraph", (p) => p.paragraph, 15, FontWeight.w400, "Open Sans"),
          (
            "paragraphSmall",
            (p) => p.paragraphSmall,
            14,
            FontWeight.w400,
            "Open Sans",
          ),
          (
            "rowSubtitle",
            (p) => p.rowSubtitle,
            13,
            FontWeight.w400,
            "Open Sans",
          ),
          ("caption", (p) => p.caption, 12, FontWeight.w400, "Open Sans"),
        ];
    for (final (name, of, size, weight, font) in roles) {
      test("$name is $font $size ${weight.value}", () {
        for (final palette in [YiviPalette.light, YiviPalette.dark]) {
          final style = of(palette);
          expect(style.fontSize, size);
          expect(style.fontWeight, weight);
          expect(style.fontFamily, contains(font));
        }
      });
    }

    test("a step title is 30 high", () {
      final style = YiviPalette.light.titleStep;
      expect(style.fontSize! * style.height!, closeTo(30, 0.001));
    });
  });

  test("spacing roles sit on the scale", () {
    expect(YiviSpace.pageSide, YiviSpace.x16);
    expect(YiviSpace.cardInside, YiviSpace.x16);
    expect(YiviSpace.rowGap, YiviSpace.x12);
    expect(YiviSpace.groupGap, YiviSpace.x24);
    expect(YiviSpace.sectionGap, YiviSpace.x32);
  });

  test("motion durations", () {
    expect(YiviMotion.quick, const Duration(milliseconds: 200));
    expect(YiviMotion.standard, const Duration(milliseconds: 300));
    expect(YiviMotion.page, const Duration(milliseconds: 420));
  });
}
