import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/card_art_support.dart";

void main() {
  group("parseCssColor", () {
    test("hex forms", () {
      expect(parseCssColor("#1E5B46"), const Color(0xFF1E5B46));
      expect(parseCssColor("#fff"), const Color(0xFFFFFFFF));
      expect(parseCssColor("#1E5B4680"), const Color(0x801E5B46));
    });
    test("rgb and rgba", () {
      expect(parseCssColor("rgb(30, 91, 70)"), const Color(0xFF1E5B46));
      expect(parseCssColor("rgba(0,0,0,0.5)"), const Color(0x80000000));
    });
    test("names and garbage", () {
      expect(parseCssColor("white"), const Color(0xFFFFFFFF));
      expect(parseCssColor("not a colour"), isNull);
      expect(parseCssColor(null), isNull);
    });
  });

  group("fillSvgTemplate", () {
    test("fills placeholders and escapes XML", () {
      expect(
        fillSvgTemplate(
          "<text>{{name}} {{ card_no }} {{missing}}</text>",
          {"name": "Ann & <Bob>", "card_no": "42"},
        ),
        "<text>Ann &amp; &lt;Bob&gt; 42 </text>",
      );
    });
  });

  group("pickSvgTemplate", () {
    final portraitLight = SvgCardTemplate(svg: "pl", orientation: "portrait", colorScheme: "light");
    final landscapeLight = SvgCardTemplate(svg: "ll", orientation: "landscape", colorScheme: "light");
    final landscapeDark = SvgCardTemplate(svg: "ld", orientation: "landscape", colorScheme: "dark");

    test("prefers landscape, then the matching colour scheme", () {
      final all = [portraitLight, landscapeLight, landscapeDark];
      expect(
        pickSvgTemplate(all, brightness: Brightness.light, highContrast: false)!.svg,
        "ll",
      );
      expect(
        pickSvgTemplate(all, brightness: Brightness.dark, highContrast: false)!.svg,
        "ld",
      );
    });

    test("returns null without templates", () {
      expect(
        pickSvgTemplate(const [], brightness: Brightness.light, highContrast: false),
        isNull,
      );
    });
  });

  test("yiviCardColors gives a pale background and dark text", () {
    final c = yiviCardColors(const Color(0xFFE12747));
    expect(c.background.computeLuminance(), greaterThan(0.7));
    expect(c.foreground.computeLuminance(), lessThan(0.1));
    expect(yiviCardColors(null).background, const Color(0xFFFFFFFF));
  });
}
