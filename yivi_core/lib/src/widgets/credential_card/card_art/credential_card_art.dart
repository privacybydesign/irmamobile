import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/yivi_edges.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../util/instance_hint.dart";
import "../../base64_image.dart";
import "builtin_card_svgs.dart";
import "builtin_card_templates.dart";
import "card_art_support.dart";

/// The text form of an [InstanceHint], e.g. an email address or
/// "Added 12-03-2025".
String instanceHintText(BuildContext context, InstanceHint hint) {
  return switch (hint) {
    ValueHint(:final text) => text,
    AddedHint(:final date) => FlutterI18n.translate(
      context,
      "credential_card.added_on",
      translationParams: {"date": _date(context, date)},
    ),
    NoHint() => "",
  };
}

/// [instanceHintText] of each of [cards], by hash.
Map<String, String> instanceHintTexts(
  BuildContext context,
  Iterable<schemaless.Credential> cards,
  Map<String, InstanceHint> hints,
) => {
  for (final c in cards)
    c.hash: instanceHintText(context, hints[c.hash] ?? const NoHint()),
};

String _date(BuildContext context, DateTime date) =>
    printableDate(date, context.lang);

/// The picture of a credential as a card, at any width (the height follows
/// the ID-1 card ratio). It is decorative: screen readers get the same
/// information from the text next to it.
///
/// Where the art comes from, in order:
/// 1. the issuer's SVG template (SD-JWT VC `svg_templates`), filled with the
///    claim values;
/// 2. a template Yivi ships for its own credentials (the PbDF scheme, see
///    [builtinCardTemplate]), filled with the attribute values;
/// 3. the Yivi card, in the issuer's colours (SD-JWT VC `simple` rendering);
/// 4. the Yivi card, tinted with the colour of the logo (IRMA credentials and
///    anything without colours).
class CredentialCardArt extends StatelessWidget {
  static const double designWidth = 358;
  static const double designHeight = 226;
  static const double aspectRatio = designWidth / designHeight;

  /// The corner radius at the design width.
  static const double cornerRadius = 13;

  final schemaless.Credential credential;

  /// Text shown under the name on the Yivi card, usually the instance hint.
  final String? hintText;
  final double width;

  /// Shows the card washed out, e.g. in a notification about expired data.
  final bool greyedOut;

  /// How strongly the light top edge shows, 0 to 1: the thickness of the
  /// card catching the light, so the cards in the stack read as stacked.
  /// Light theme only: in dark the card's hairline sets it off (see
  /// [_hairline]).
  final double edge;

  const CredentialCardArt({
    super.key,
    required this.credential,
    required this.width,
    this.hintText,
    this.greyedOut = false,
    this.edge = 0,
  });

  /// The corner shape of a card of [width]: plain round corners of
  /// [cornerRadius] at the design width, like a real ID-1 card (a 3.18 mm corner on 85.6 mm).
  static ShapeBorder shapeFor(double width) =>
      RoundedRectangleBorder(borderRadius: radiusFor(width));

  /// The corner radius of a card of [width], for shapes that follow it.
  static BorderRadius radiusFor(double width) =>
      BorderRadius.circular(cornerRadius * width / designWidth);

  @override
  Widget build(BuildContext context) {
    final height = width / aspectRatio;
    final shape = shapeFor(width);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (template, builtin) = _template(context);

    Widget art = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.fill,
              child: MediaQuery.withNoTextScaling(
                child: SizedBox(
                  width: designWidth,
                  height: designHeight,
                  child: _art(context, template, builtin),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: radiusFor(width),
                    // With Increase Contrast the outline of any block.
                    side: MediaQuery.highContrastOf(context)
                        ? YiviEdges.block(context)
                        : BorderSide(color: _hairline(context, dark, template)),
                  ),
                ),
              ),
            ),
            // Light only: on a dark card the white edge reads as a shine.
            if (edge > 0 && !dark)
              IgnorePointer(
                child: CustomPaint(
                  painter: _EdgePainter(
                    scale: width / designWidth,
                    opacity: edge.clamp(0.0, 1.0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (greyedOut) {
      art = Opacity(
        opacity: 0.6,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0.2126, 0.7152, 0.0722, 0, 0, //
            0, 0, 0, 1, 0,
          ]),
          child: art,
        ),
      );
    }

    // No shadow: like a printed card, only the fine edge above sets it off.
    return ExcludeSemantics(child: art);
  }

  /// The fine line just inside the card's edge. Light: a faint dark line.
  /// Dark: a light line, so the card stands off the black page and off the
  /// card it overlaps in the stack; on a light card a dark one, where a light
  /// line would vanish.
  Color _hairline(
    BuildContext context,
    bool dark,
    schemaless.SvgCardTemplate? template,
  ) {
    if (!dark) return const Color(0x1A000000);
    final top = _topColour(context, template);
    return top != null && top.computeLuminance() > 0.5
        ? const Color(0x33000000)
        : const Color(0x3DFFFFFF);
  }

  /// The colour at the top of the card (see [svgTopColour]), or null when
  /// that is not known.
  Color? _topColour(
    BuildContext context,
    schemaless.SvgCardTemplate? template,
  ) {
    if (template != null) return svgTopColour(template.svg);
    final display = credential.display;
    return parseCssColor(display?.backgroundColor) ??
        yiviCardColors(parseCssColor(display?.logoTint)).top;
  }

  /// The SVG template the card is drawn from, and whether it is one of
  /// Yivi's own; null when it is the Yivi card.
  (schemaless.SvgCardTemplate?, bool) _template(BuildContext context) {
    final issuerTemplate = pickSvgTemplate(
      credential.display?.svgTemplates ?? const [],
      brightness: Theme.of(context).brightness,
      highContrast: MediaQuery.highContrastOf(context),
    );
    if (issuerTemplate != null) return (issuerTemplate, false);
    final builtin = builtinCardTemplateFor(credential);
    return (builtin, builtin != null);
  }

  Widget _art(
    BuildContext context,
    schemaless.SvgCardTemplate? template,
    bool builtin,
  ) {
    final yiviCard = _YiviCard(credential: credential, hintText: hintText);
    if (template == null) return yiviCard;

    final yes = FlutterI18n.translate(context, "credential.boolean_yes");
    final no = FlutterI18n.translate(context, "credential.boolean_no");
    String text(schemaless.Attribute a) =>
        imageDataUri(a.value) ?? attributeText(a.value, yes: yes, no: no) ?? "";
    final values = !builtin
        // An issuer template names its slots with `svg_id`.
        ? {
            for (final a in credential.attributes)
              if (a.svgId != null) a.svgId!: text(a),
          }
        // Ours use the attribute ids of the scheme, plus their names.
        : builtinTemplateValues(credential, text);
    return SvgPicture.string(
      fillSvgTemplate(template.svg, values),
      width: designWidth,
      height: designHeight,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => yiviCard,
    );
  }
}

/// The card Yivi draws for credentials without an issuer template.
/// The card Yivi draws for a credential without a design of its own, in
/// the frame of the built-in cards: the issuer's logo on a white tile, the
/// credential's name and main value next to it, the issuer and the Yivi
/// mark at the bottom, on a deep gradient in the logo's
/// hue with the Yivi facets down the right side (see [yiviCardColors]).
class _YiviCard extends StatelessWidget {
  final schemaless.Credential credential;
  final String? hintText;

  const _YiviCard({required this.credential, this.hintText});

  @override
  Widget build(BuildContext context) {
    final display = credential.display;
    final colours = yiviCardColors(
      parseCssColor(display?.logoTint),
      background: parseCssColor(display?.backgroundColor),
    );
    final text = parseCssColor(display?.textColor) ?? colours.text;
    final accent = display?.textColor == null
        ? colours.accent
        : text.withValues(alpha: 0.72);
    final image = display?.backgroundImage;
    final hint = hintText ?? "";

    TextStyle style(
      double size,
      FontWeight weight,
      Color color, {
      bool display = false,
      double spacing = 0,
    }) => TextStyle(
      package: display ? packageName : null,
      fontFamily: display ? "Alexandria" : "Open Sans",
      fontSize: size,
      height: 1.2,
      fontWeight: weight,
      letterSpacing: spacing,
      color: color,
    );
    Widget line(String value, TextStyle style) =>
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (image != null)
          Image(
            // Decoded once, so a rebuilt card finds it in the cache.
            image: MemoryImage(decodeBase64Cached(image.base64)),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          )
        else
          CustomPaint(painter: _FacetsPainter(colours)),
        Positioned(
          left: 18.5,
          top: 16.5,
          child: _Logo(credential: credential, colour: colours.top),
        ),
        Positioned(
          left: 62,
          top: 17,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line(
                credential.name,
                style(10.5, FontWeight.w700, accent, spacing: 0.4),
              ),
              if (hint.isNotEmpty)
                line(hint, style(19, FontWeight.w600, text, display: true)),
            ],
          ),
        ),
        Positioned(
          left: 20,
          right: 60,
          bottom: 9,
          child: line(
            credential.issuer.name,
            style(10, FontWeight.w600, accent),
          ),
        ),
        Positioned(
          left: 318.5,
          top: 205.5,
          child: SvgPicture.string(
            '<svg xmlns="http://www.w3.org/2000/svg" '
            'viewBox="212.686 199.928 765.355 425.197">'
            '<g fill="${_hex(text)}" fill-opacity="0.8">$builtinYiviMark</g>'
            "</svg>",
            width: 765.355 * _markScale,
            height: 425.197 * _markScale,
          ),
        ),
      ],
    );
  }

  /// The Yivi mark at the size the built-in cards draw it.
  static const _markScale = 0.0233;

  static String _hex(Color c) =>
      "#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, "0")}";
}

/// The ground of the Yivi card: a vertical gradient, and the faceted shards
/// of the Yivi buttons (`assets/ui/btn-bg.svg`) down the right side.
class _FacetsPainter extends CustomPainter {
  _FacetsPainter(this.colours);

  final ({
    Color top,
    Color bottom,
    List<Color> facets,
    Color text,
    Color accent,
  })
  colours;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colours.top, colours.bottom],
        ).createShader(rect),
    );
    // btn-bg.svg's shards (343 × 124), scaled onto the card's right side.
    final sx = size.width / CredentialCardArt.designWidth;
    final sy = size.height / CredentialCardArt.designHeight;
    double x(double v) => (358 - (343 - v) * 0.62) * sx;
    double y(double v) => v * 226 / 124 * sy;
    Path shard(List<(double, double)> points) =>
        Path()..addPolygon([for (final (a, b) in points) Offset(a, b)], true);
    final f = colours.facets;
    final shards = [
      (
        shard([
          (x(253.6), y(124)),
          (x(240.7), y(124)),
          (x(195), 0),
          (x(299.3), 0),
        ]),
        f[0],
      ),
      (shard([(x(299.3), y(124)), (x(253.6), y(124)), (x(299.3), 0)]), f[1]),
      (
        shard([
          (x(305.3), y(124)),
          (x(299.3), y(124)),
          (x(299.3), 0),
          (size.width, 0),
          (size.width, y(21.7)),
        ]),
        f[2],
      ),
      (
        shard([
          (x(305.3), y(124)),
          (size.width, y(124)),
          (size.width, y(21.7)),
        ]),
        f[1],
      ),
    ];
    for (final (path, colour) in shards) {
      canvas.drawPath(path, Paint()..color = colour);
    }
  }

  @override
  bool shouldRepaint(_FacetsPainter old) => old.colours != colours;
}

/// The issuer's logo, fitted whole into a white tile; the issuer's initial
/// when there is no logo.
class _Logo extends StatelessWidget {
  final schemaless.Credential credential;

  /// The card's colour, for the initial.
  final Color colour;

  const _Logo({required this.credential, required this.colour});

  @override
  Widget build(BuildContext context) {
    final logo = credential.image;
    final source = credential.issuer.name.isNotEmpty
        ? credential.issuer.name
        : credential.name;
    return Container(
      width: 31,
      height: 31,
      padding: const EdgeInsets.all(3),
      alignment: Alignment.center,
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      child: logo != null
          // Decoded at the size it is laid out at (the card scales down
          // from there, so a thumbnail needs no more).
          ? Base64Image(base64: logo.base64, mimeType: logo.mimeType, size: 25)
          : Text(
              source.isEmpty ? "?" : source.characters.first.toUpperCase(),
              style: TextStyle(
                package: packageName,
                fontFamily: "Alexandria",
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: colour,
              ),
            ),
    );
  }
}

/// The light top edge of a card: a fine line just inside the outline, even
/// along the top and round the corners, fading out down the sides. It fades
/// only once the corner has turned: fading inside the curve made a plain
/// corner look like a squircle.
class _EdgePainter extends CustomPainter {
  _EdgePainter({required this.scale, required this.opacity});

  /// The card's width over the design width.
  final double scale;
  final double opacity;

  /// In design points: the corner radius, and how far down the sides the
  /// edge fades out after it.
  static const _radius = CredentialCardArt.cornerRadius;
  static const _fade = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = 0.5 * scale;
    final radius = Radius.circular((_radius - 0.5) * scale);
    final end = (_radius + _fade) * scale;
    final colour = Colors.white.withValues(alpha: 0.3 * opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius((Offset.zero & size).deflate(inset), radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = scale
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colour, colour, colour.withValues(alpha: 0)],
          stops: [0, _radius / (_radius + _fade), 1],
        ).createShader(Rect.fromLTWH(0, 0, size.width, end)),
    );
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.scale != scale || old.opacity != opacity;
}
