import "dart:math";

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

/// The colours of the Yivi card ([yiviCardColors]): its gradient from [top]
/// to [bottom], the [facets] down its right side, and its [text] and
/// [accent].
typedef YiviCardColours = ({
  Color top,
  Color bottom,
  List<Color> facets,
  Color text,
  Color accent,
});

/// The colours of the Yivi card, the card a credential gets when it has no
/// design of its own: a deep gradient in the hue of the issuer's logo (grey
/// when the logo has none), the Yivi facets down the right side in darker
/// shades of it, white text and a pale accent for the name, labels and
/// issuer. The same in light and dark mode, like the built-in cards.
///
/// [background] is the issuer's own card colour (SD-JWT VC `simple`
/// rendering), which takes the place of the logo's hue; a light one gets
/// dark text.
YiviCardColours yiviCardColors(Color? tint, {Color? background}) {
  if (background != null) {
    final hsl = HSLColor.fromColor(background);
    final light = background.computeLuminance() > 0.45;
    Color darker(double by) =>
        hsl.withLightness((hsl.lightness - by).clamp(0.0, 1.0)).toColor();
    final text = light ? const Color(0xFF1C1C1E) : Colors.white;
    return (
      top: background,
      bottom: darker(0.06),
      facets: [darker(0.05), darker(0.08), darker(0.12)],
      text: text,
      accent: text.withValues(alpha: 0.72),
    );
  }
  final hsl = tint == null ? null : HSLColor.fromColor(tint);
  final hue = hsl?.hue ?? 220;
  final saturation = hsl == null ? 0.08 : hsl.saturation.clamp(0.35, 0.62);
  Color shade(double s, double l) =>
      HSLColor.fromAHSL(1, hue, s.clamp(0.0, 1.0), l).toColor();
  return (
    top: shade(saturation, 0.37),
    bottom: shade(saturation, 0.28),
    facets: [
      shade(saturation * 0.92, 0.32),
      shade(saturation * 0.90, 0.29),
      shade(saturation * 0.88, 0.25),
    ],
    text: Colors.white,
    accent: shade(min(saturation, 0.5) * 0.6, 0.84),
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

const _hiddenStart = "\uE000", _hiddenEnd = "\uE001";
final _hiddenMark = RegExp("$_hiddenStart(\\d+)$_hiddenEnd");

/// What a template is filled with for a value that must not show: a mark
/// that [obscureHiddenValues] turns into a smear about as long as [value].
/// The value itself never goes into the picture.
String hiddenValueMark(String value) =>
    "$_hiddenStart${value.length.clamp(4, 14)}$_hiddenEnd";

/// Draws each value of a filled template that was [hiddenValueMark]ed as a
/// blurred-looking smear in its place: in text, a word of that length drawn
/// only as a thick, faint, round stroke of the text's own colour, so it
/// reads as a soft band; a photo becomes a faint block of its size.
String obscureHiddenValues(String svg) {
  // A photo: its <image> becomes a faint rounded block.
  var out = svg.replaceAllMapped(
    RegExp(
      r"<image\b[^>]*?"
      "$_hiddenStart"
      r"\d+"
      "$_hiddenEnd"
      r"[^>]*>(\s*</image>)?",
    ),
    (m) {
      final tag = m[0]!
          .replaceFirst(RegExp(r"</image>$"), "")
          .replaceAll(RegExp(r'\s(xlink:)?href="[^"]*"'), "")
          .replaceFirst(RegExp(r"^<image"), "<rect")
          .replaceFirst(RegExp(r"\s*/?>$"), "");
      return '$tag rx="6" fill="#8A8F98" fill-opacity="0.35"/>';
    },
  );
  // Text: per <text>, in its own colour and size.
  out = out.replaceAllMapped(
    RegExp(r"<text\b([^>]*)>(.*?)</text>", dotAll: true),
    (m) {
      final attributes = m[1]!, content = m[2]!;
      if (!_hiddenMark.hasMatch(content)) return m[0]!;
      final fill =
          RegExp(r'\bfill="([^"]*)"').firstMatch(attributes)?[1] ?? "#808080";
      final size =
          double.tryParse(
            RegExp(r'font-size="([\d.]+)').firstMatch(attributes)?[1] ?? "",
          ) ??
          14;
      final smeared = content.replaceAllMapped(
        _hiddenMark,
        (h) =>
            // Only the stroke, so thick that the letters run together into
            // one soft band: no letter shapes left.
            '<tspan fill-opacity="0" stroke="$fill" stroke-opacity="0.32" '
            'stroke-width="${size * 0.8}" stroke-linejoin="round" '
            'stroke-linecap="round">${"o" * int.parse(h[1]!)}</tspan>',
      );
      return "<text$attributes>$smeared</text>";
    },
  );
  // Anywhere else (an attribute): nothing.
  return out.replaceAll(_hiddenMark, "");
}

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
