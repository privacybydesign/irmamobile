import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/widgets/credential_card/card_art/builtin_card_svgs.dart";
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
        fillSvgTemplate("<text>{{name}} {{ card_no }} {{missing}}</text>", {
          "name": "Ann & <Bob>",
          "card_no": "42",
        }),
        "<text>Ann &amp; &lt;Bob&gt; 42 </text>",
      );
    });
  });

  group("pickSvgTemplate", () {
    final portraitLight = SvgCardTemplate(
      svg: "pl",
      orientation: "portrait",
      colorScheme: "light",
    );
    final landscapeLight = SvgCardTemplate(
      svg: "ll",
      orientation: "landscape",
      colorScheme: "light",
    );
    final landscapeDark = SvgCardTemplate(
      svg: "ld",
      orientation: "landscape",
      colorScheme: "dark",
    );

    test("prefers landscape, then the matching colour scheme", () {
      final all = [portraitLight, landscapeLight, landscapeDark];
      expect(
        pickSvgTemplate(
          all,
          brightness: Brightness.light,
          highContrast: false,
        )!.svg,
        "ll",
      );
      expect(
        pickSvgTemplate(
          all,
          brightness: Brightness.dark,
          highContrast: false,
        )!.svg,
        "ld",
      );
    });

    test("returns null without templates", () {
      expect(
        pickSvgTemplate(
          const [],
          brightness: Brightness.light,
          highContrast: false,
        ),
        isNull,
      );
    });
  });

  test("yiviCardColors gives a deep card in the logo's hue, white text", () {
    const tint = Color(0xFFE12747);
    final c = yiviCardColors(tint);
    final top = HSLColor.fromColor(c.top);

    expect(top.hue, closeTo(HSLColor.fromColor(tint).hue, 1));
    expect(top.lightness, closeTo(0.37, 0.01));
    expect(HSLColor.fromColor(c.bottom).lightness, closeTo(0.28, 0.01));
    expect(c.facets, hasLength(3));
    expect(c.text, Colors.white);
    // Readable on the darkest part of the card: at least 4.5:1.
    double ratio(Color a, Color b) =>
        (a.computeLuminance() + 0.05) / (b.computeLuminance() + 0.05);
    expect(ratio(c.text, c.top), greaterThanOrEqualTo(4.5));
    expect(ratio(c.accent, c.top), greaterThanOrEqualTo(4.5));
  });

  test("yiviCardColors is grey without a tint", () {
    final c = yiviCardColors(null);
    expect(HSLColor.fromColor(c.top).saturation, lessThan(0.1));
  });

  test(
    "yiviCardColors takes the issuer's colour, dark text on a light one",
    () {
      const light = Color(0xFFF2E6C8);
      final c = yiviCardColors(const Color(0xFFE12747), background: light);
      expect(c.top, light);
      expect(c.text, const Color(0xFF1C1C1E));
      expect(
        yiviCardColors(null, background: const Color(0xFF103060)).text,
        Colors.white,
      );
    },
  );

  group("svgTopColour", () {
    test("a plain fill", () {
      expect(
        svgTopColour(
          '<svg><rect width="10" height="10" fill="#1E5B46"/></svg>',
        ),
        const Color(0xFF1E5B46),
      );
    });

    test(
      "the first stop of the gradient the fill names, not a shape in defs",
      () {
        const svg =
            '<svg><defs><clipPath id="c"><rect width="4" height="4" fill="#FF0000"/></clipPath>'
            '<linearGradient id="g"><stop offset="0" stop-color="#E8F2FB"/>'
            '<stop offset="1" stop-color="#000000"/></linearGradient></defs>'
            '<rect width="10" height="10" fill="url(#g)"/></svg>';
        expect(svgTopColour(svg), const Color(0xFFE8F2FB));
      },
    );

    test("null when there is no colour to read", () {
      expect(svgTopColour('<svg><image href="x.png"/></svg>'), isNull);
    });

    test("every built-in card has one, and the light ones read light", () {
      for (final MapEntry(key: key, value: svg) in builtinCardSvgs.entries) {
        expect(svgTopColour(svg), isNotNull, reason: key);
      }
      expect(
        svgTopColour(builtinCardSvgs["ivido"]!)!.computeLuminance(),
        greaterThan(0.5),
      );
      expect(
        svgTopColour(builtinCardSvgs["passport"]!)!.computeLuminance(),
        lessThan(0.5),
      );
    });
  });
}
