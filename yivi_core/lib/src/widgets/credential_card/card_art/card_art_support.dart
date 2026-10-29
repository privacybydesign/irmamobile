import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;

/// Parses the CSS colours issuers put in their metadata: `#rgb`, `#rgba`,
/// `#rrggbb`, `#rrggbbaa`, `rgb()`/`rgba()` and a few names. Returns null for
/// anything else, so callers fall back to the Yivi colours.
Color? parseCssColor(String? input) {
  if (input == null) return null;
  final s = input.trim().toLowerCase();
  if (s.isEmpty) return null;

  const named = {
    "white": Color(0xFFFFFFFF),
    "black": Color(0xFF000000),
    "transparent": Color(0x00000000),
  };
  if (named.containsKey(s)) return named[s];

  if (s.startsWith("#")) {
    var hex = s.substring(1);
    if (hex.length == 3 || hex.length == 4) {
      hex = hex.split("").map((c) => "$c$c").join();
    }
    if (hex.length == 6) hex = "${hex}ff";
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    // CSS puts alpha last, Flutter first.
    return Color(((value & 0xFF) << 24) | (value >> 8));
  }

  final fn = RegExp(r"^rgba?\(([^)]*)\)$").firstMatch(s);
  if (fn != null) {
    final parts = fn
        .group(1)!
        .split(RegExp(r"[\s,/]+"))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length < 3) return null;
    int channel(String p) {
      if (p.endsWith("%")) {
        return ((double.tryParse(p.substring(0, p.length - 1)) ?? 0) * 2.55)
            .round()
            .clamp(0, 255);
      }
      return (double.tryParse(p) ?? 0).round().clamp(0, 255);
    }

    var alpha = 255;
    if (parts.length >= 4) {
      final a = parts[3];
      alpha = a.endsWith("%")
          ? ((double.tryParse(a.substring(0, a.length - 1)) ?? 100) * 2.55)
                .round()
                .clamp(0, 255)
          : ((double.tryParse(a) ?? 1) * 255).round().clamp(0, 255);
    }
    return Color.fromARGB(
      alpha,
      channel(parts[0]),
      channel(parts[1]),
      channel(parts[2]),
    );
  }
  return null;
}

/// The colour at the top of an SVG card, the part of it that shows in the
/// stack: the fill of its first shape outside `<defs>`, or the first stop
/// of the gradient that fill names. Null when there is none to read (an
/// image, a pattern). Remembered per template.
Color? svgTopColour(String svg) => _topColours.putIfAbsent(svg, () {
  final body = svg.replaceAll(RegExp(r"<defs\b.*?</defs>", dotAll: true), "");
  final fill = RegExp(
    r"""<(?:rect|path)\b[^>]*?\bfill=["']([^"']+)["']""",
  ).firstMatch(body)?.group(1)?.trim();
  if (fill == null) return null;
  final ref = RegExp(r"^url\(#([^)]+)\)$").firstMatch(fill);
  if (ref == null) return parseCssColor(fill);
  final id = RegExp.escape(ref.group(1)!);
  final gradient = RegExp(
    """<(linear|radial)Gradient\\b[^>]*\\bid=["']$id["'][^>]*>(.*?)</\\1Gradient>""",
    dotAll: true,
  ).firstMatch(svg);
  final stop = gradient == null
      ? null
      : RegExp(
          r"""stop-color=["']([^"']+)["']""",
        ).firstMatch(gradient.group(2)!);
  return parseCssColor(stop?.group(1));
});

final _topColours = <String, Color?>{};

/// Background and text colour of the Yivi card template for a credential
/// without its own colours: a pale wash of the logo colour with dark text in
/// the same hue, or a neutral white card when there is no tint.
///
/// In dark mode the card turns dark instead: the logo's hue at 27% lightness
/// with light text in the same hue, or a graphite card when there is no tint.
({Color background, Color foreground}) yiviCardColors(
  Color? tint, {
  Brightness brightness = Brightness.light,
}) {
  if (brightness == Brightness.dark) return _darkYiviCardColors(tint);
  if (tint == null) {
    return (
      background: const Color(0xFFFFFFFF),
      foreground: const Color(0xFF484747),
    );
  }
  final hsl = HSLColor.fromColor(tint);
  final saturation = hsl.saturation.clamp(0.0, 0.85);
  return (
    background: hsl
        .withSaturation(saturation * 0.75)
        .withLightness(0.93)
        .toColor(),
    foreground: hsl
        .withSaturation((saturation * 0.6).clamp(0.0, 0.5))
        .withLightness(0.18)
        .toColor(),
  );
}

({Color background, Color foreground}) _darkYiviCardColors(Color? tint) {
  if (tint == null) {
    return (
      background: const HSLColor.fromAHSL(1, 216, 0.13, 0.18).toColor(),
      foreground: const Color(0xFFE6E8EC),
    );
  }
  final hsl = HSLColor.fromColor(tint);
  final saturation = hsl.saturation.clamp(0.0, 0.45);
  return (
    background: hsl.withSaturation(saturation).withLightness(0.27).toColor(),
    foreground: hsl.withSaturation(saturation).withLightness(0.90).toColor(),
  );
}

/// Picks the issuer template that suits the card best: landscape first (the
/// card is landscape), then a colour scheme matching the app, then the
/// contrast the platform asks for. Returns null when there is none.
schemaless.SvgCardTemplate? pickSvgTemplate(
  List<schemaless.SvgCardTemplate> templates, {
  required Brightness brightness,
  required bool highContrast,
}) {
  if (templates.isEmpty) return null;
  final scheme = brightness == Brightness.dark ? "dark" : "light";
  int score(schemaless.SvgCardTemplate t) {
    var s = 0;
    if (t.orientation == "landscape") s += 8;
    if (t.orientation == "portrait") s -= 8;
    if (t.colorScheme == scheme) s += 4;
    if (t.colorScheme != null && t.colorScheme != scheme) s -= 2;
    if ((t.contrast == "high") == highContrast) s += 1;
    return s;
  }

  final sorted = [...templates]..sort((a, b) => score(b) - score(a));
  return sorted.first;
}

final _placeholder = RegExp(r"\{\{\s*([A-Za-z0-9_.\-]+)\s*\}\}");

/// Replaces each `{{svg_id}}` placeholder with its XML-escaped value. Claims
/// that are missing (or were not disclosed) become empty.
String fillSvgTemplate(String svg, Map<String, String> values) =>
    svg.replaceAllMapped(_placeholder, (m) => _escapeXml(values[m[1]] ?? ""));

String _escapeXml(String s) => s
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&apos;");

/// A `data:image/...;base64,` URI for a base64 image attribute, so an issuer
/// template can show it through `<image href="{{svg_id}}">` (the only kind of
/// link irmago's sanitiser lets through). Null for every other value.
String? imageDataUri(schemaless.AttributeValue? value) {
  if (value == null) return null;
  final data =
      value.base64Image ??
      (value.type == schemaless.AttributeType.base64Image
          ? value.string
          : null);
  if (data == null || data.isEmpty) return null;
  final mime = data.startsWith("/9j/")
      ? "image/jpeg"
      : data.startsWith("iVBOR")
      ? "image/png"
      : data.startsWith("R0lGOD")
      ? "image/gif"
      : data.startsWith("UklGR")
      ? "image/webp"
      : null;
  if (mime == null) return null;
  return "data:$mime;base64,$data";
}

/// [attributeText] with "Yes" and "No" in the app's language.
String? localizedAttributeText(
  BuildContext context,
  schemaless.AttributeValue? value,
) => attributeText(
  value,
  yes: FlutterI18n.translate(context, "credential.boolean_yes"),
  no: FlutterI18n.translate(context, "credential.boolean_no"),
);

/// The plain-text form of an attribute value, or null when it has none that
/// fits on a card (images, missing values).
String? attributeText(
  schemaless.AttributeValue? value, {
  String? yes,
  String? no,
}) {
  if (value == null) return null;
  return switch (value.type) {
    schemaless.AttributeType.string =>
      (value.string?.trim().isEmpty ?? true) ? null : value.string!.trim(),
    schemaless.AttributeType.integer => value.intValue?.toString(),
    schemaless.AttributeType.boolean =>
      value.boolValue == null ? null : (value.boolValue! ? yes : no),
    schemaless.AttributeType.image ||
    schemaless.AttributeType.base64Image => null,
  };
}
