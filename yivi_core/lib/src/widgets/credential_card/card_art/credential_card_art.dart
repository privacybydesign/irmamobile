import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:material_ui/material_ui.dart";

import "../../../../package_name.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../util/date_formatter.dart";
import "../../../util/instance_hint.dart";
import "../../base64_image.dart";
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

String _date(BuildContext context, DateTime date) => printableDate(
  date,
  FlutterI18n.currentLocale(context)?.languageCode ?? "en",
);

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

  final schemaless.Credential credential;

  /// Text shown under the name on the Yivi card, usually the instance hint.
  final String? hintText;
  final double width;

  /// Shows the card washed out, e.g. in a notification about expired data.
  final bool greyedOut;

  /// How strongly the light top edge shows, 0 to 1: the thickness of the
  /// card catching the light, so the cards in the stack read as stacked.
  final double edge;

  const CredentialCardArt({
    super.key,
    required this.credential,
    required this.width,
    this.hintText,
    this.greyedOut = false,
    this.edge = 0,
  });

  /// The corner shape of a card of [width]: plain round corners of 13 points
  /// at the design width, like a real ID-1 card (a 3.18 mm corner on 85.6 mm).
  static ShapeBorder shapeFor(double width) =>
      RoundedRectangleBorder(borderRadius: radiusFor(width));

  /// The corner radius of a card of [width], for shapes that follow it.
  static BorderRadius radiusFor(double width) =>
      BorderRadius.circular(13 * width / designWidth);

  @override
  Widget build(BuildContext context) {
    final height = width / aspectRatio;
    final shape = shapeFor(width);
    final dark = Theme.of(context).brightness == Brightness.dark;

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
                  child: _art(context),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: radiusFor(width),
                    // Light on the dark page, so the card's edge shows.
                    side: BorderSide(
                      color: dark
                          ? const Color(0x1AFFFFFF)
                          : const Color(0x1A000000),
                    ),
                  ),
                ),
              ),
            ),
            if (edge > 0)
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

  Widget _art(BuildContext context) {
    final yiviCard = _YiviCard(credential: credential, hintText: hintText);
    final issuerTemplate = pickSvgTemplate(
      credential.display?.svgTemplates ?? const [],
      brightness: Theme.of(context).brightness,
      highContrast: MediaQuery.highContrastOf(context),
    );
    final builtin = issuerTemplate == null
        ? builtinCardTemplate(
            credential.credentialId,
            attributeIds: credential.attributes
                .where((a) => a.claimPath.isNotEmpty)
                .map((a) => "${a.claimPath.last}"),
          )
        : null;
    final template = issuerTemplate ?? builtin;
    if (template == null) return yiviCard;

    final yes = FlutterI18n.translate(context, "credential.boolean_yes");
    final no = FlutterI18n.translate(context, "credential.boolean_no");
    String text(schemaless.Attribute a) =>
        imageDataUri(a.value) ?? attributeText(a.value, yes: yes, no: no) ?? "";
    final values = builtin == null
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
class _YiviCard extends StatelessWidget {
  final schemaless.Credential credential;
  final String? hintText;

  const _YiviCard({required this.credential, this.hintText});

  @override
  Widget build(BuildContext context) {
    final display = credential.display;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tinted = yiviCardColors(
      parseCssColor(display?.logoTint),
      brightness: Theme.of(context).brightness,
    );
    final issuerBackground = parseCssColor(display?.backgroundColor);
    final background = issuerBackground ?? tinted.background;
    final foreground =
        parseCssColor(display?.textColor) ??
        (issuerBackground == null
            ? tinted.foreground
            : (background.computeLuminance() > 0.45
                  ? const Color(0xFF1C1C1E)
                  : Colors.white));

    final image = display?.backgroundImage;
    final footer = _footerText(context);

    TextStyle text(double size, FontWeight weight, {double alpha = 1}) =>
        TextStyle(
          package: weight.value >= 600 && size >= 16 ? packageName : null,
          fontFamily: weight.value >= 600 && size >= 16
              ? "Alexandria"
              : "Open Sans",
          fontSize: size,
          height: 1.3,
          fontWeight: weight,
          color: foreground.withValues(alpha: alpha),
        );

    return ColoredBox(
      color: background,
      child: Stack(
        children: [
          if (image != null)
            Positioned.fill(
              child: Image(
                // Decoded once, so a rebuilt card finds it in the cache.
                image: MemoryImage(decodeBase64Cached(image.base64)),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          Positioned(
            right: -64,
            bottom: -88,
            child: _Ring(color: foreground, size: 240),
          ),
          Positioned(
            right: -8,
            bottom: -32,
            child: _Ring(color: foreground, size: 128),
          ),
          Positioned(
            left: 20,
            top: 16,
            right: 20,
            child: Row(
              spacing: 16,
              children: [
                _Logo(
                  credential: credential,
                  background: background,
                  foreground: foreground,
                  onTile: dark && issuerBackground == null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        credential.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text(16, FontWeight.w600),
                      ),
                      if ((hintText ?? "").isNotEmpty)
                        Text(
                          hintText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text(14, FontWeight.w400, alpha: 0.85),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 16,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FlutterI18n.translate(
                          context,
                          "credential_card.issued_by",
                        ),
                        style: text(12, FontWeight.w400, alpha: 0.7),
                      ),
                      Text(
                        credential.issuer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text(12, FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (footer != null)
                  // Long translations and large text shrink the date, not
                  // the issuer: it gives way with an ellipsis.
                  Flexible(
                    child: Text(
                      footer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: text(12, FontWeight.w400, alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _footerText(BuildContext context) {
    final expiry = credential.expiryDate;
    if (expiry != null && expiry > 0) {
      return "${FlutterI18n.translate(context, "credential.valid_until")} "
          "${_date(context, DateTime.fromMillisecondsSinceEpoch(expiry * 1000))}";
    }
    final issued = credential.issuanceDate;
    if (issued != null) {
      return FlutterI18n.translate(
        context,
        "credential_card.added_on",
        translationParams: {
          "date": _date(
            context,
            DateTime.fromMillisecondsSinceEpoch(issued * 1000),
          ),
        },
      );
    }
    return null;
  }
}

class _Ring extends StatelessWidget {
  final Color color;
  final double size;

  const _Ring({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.05),
    ),
  );
}

class _Logo extends StatelessWidget {
  final schemaless.Credential credential;
  final Color background;
  final Color foreground;

  /// Puts the issuer's logo on a white tile: logos are drawn for light
  /// backgrounds and can vanish on a dark card.
  final bool onTile;

  const _Logo({
    required this.credential,
    required this.background,
    required this.foreground,
    this.onTile = false,
  });

  @override
  Widget build(BuildContext context) {
    final logo = credential.image;
    if (logo != null) {
      // Decoded at the size it is laid out at (the card scales down from
      // there, so a thumbnail needs no more).
      final image = Base64Image(
        base64: logo.base64,
        mimeType: logo.mimeType,
        size: 40,
      );
      if (!onTile) return SizedBox.square(dimension: 40, child: image);
      return Container(
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(5),
        decoration: const ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        child: image,
      );
    }
    final source = credential.issuer.name.isNotEmpty
        ? credential.issuer.name
        : credential.name;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        source.isEmpty ? "?" : source.characters.first.toUpperCase(),
        style: TextStyle(
          package: packageName,
          fontFamily: "Alexandria",
          fontWeight: FontWeight.w800,
          fontSize: 22,
          color: background,
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
  static const _radius = 13.0;
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
