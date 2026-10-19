import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/base64_image.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/irma_avatar.dart";

/// The colours and words of a [RequestorTrust] tier, in one place: the badge
/// on the logo, the pill under the name, and the trust sheet.
class RequestorTrustStyle {
  final RequestorTrust trust;

  /// Fill of the badge on the logo; null for no badge (unevaluated).
  final Color? badge;
  final Color pillFill;
  final Color pillInk;

  /// The one-line label under the name; null for none (unevaluated).
  final String? label;

  const RequestorTrustStyle._({
    required this.trust,
    required this.badge,
    required this.pillFill,
    required this.pillInk,
    required this.label,
  });

  factory RequestorTrustStyle.of(BuildContext context, TrustedParty party) {
    final palette = YiviPalette.of(context);
    final trust = requestorTrustOf(party);
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);
    return switch (trust) {
      RequestorTrust.yivi => RequestorTrustStyle._(
        trust: trust,
        badge: palette.successText,
        pillFill: palette.successSurface,
        pillInk: palette.successText,
        label: t("share.trust.pill.yivi"),
      ),
      RequestorTrust.elsewhere => RequestorTrustStyle._(
        trust: trust,
        badge: palette.link,
        pillFill: palette.infoSurface,
        pillInk: palette.noteText,
        label: switch (elsewhereSourceOf(party)) {
          ElsewhereSource.euTrustedList => t("share.trust.pill.eu"),
          ElsewhereSource.namedAnchor => t("share.trust.pill.anchor", {
            "anchor": party.trustAnchor!,
          }),
          ElsewhereSource.unspecified => t("share.trust.pill.confirmed"),
        },
      ),
      RequestorTrust.unknown => RequestorTrustStyle._(
        trust: trust,
        badge: palette.dangerFill,
        pillFill: palette.errorSurface,
        pillInk: palette.errorText,
        label: t("share.trust.pill.unknown"),
      ),
      RequestorTrust.unevaluated => RequestorTrustStyle._(
        trust: trust,
        badge: null,
        pillFill: palette.surface,
        pillInk: palette.secondaryText,
        label: null,
      ),
    };
  }
}

/// The round badge on a requestor's logo: a check when someone vouches, an
/// exclamation mark when nobody does, nothing when it was not evaluated.
class RequestorTrustBadge extends StatelessWidget {
  final RequestorTrustStyle style;
  final double size;

  const RequestorTrustBadge({super.key, required this.style, this.size = 26});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final fill = style.badge;
    if (fill == null) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: palette.surface, width: size / 10),
        ),
        child: Icon(
          style.trust.vouched
              ? Icons.check_rounded
              : Icons.priority_high_rounded,
          size: size * 0.55,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// The hero tag of [requestor]'s logo: the card's logo flies into the trust
/// sheet and back.
Object requestorLogoHeroTag(TrustedParty requestor) =>
    ("requestor_logo", requestor.id, requestor.name);

/// A requestor's logo with its trust badge on the corner, at [size]. It is
/// drawn at one size and scaled, so the badge keeps its place at any size
/// and the logo can fly between the card (60 pt) and the trust sheet
/// (84 pt) as one hero.
class RequestorLogo extends StatelessWidget {
  final TrustedParty requestor;
  final RequestorTrustStyle style;
  final double size;

  const RequestorLogo({
    super.key,
    required this.requestor,
    required this.style,
    required this.size,
  });

  static const double _drawn = 84;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: requestorLogoHeroTag(requestor),
      // Also back into the card when the sheet is dragged closed.
      transitionOnUserGestures: true,
      flightShuttleBuilder: (_, _, _, _, to) => Material(
        type: MaterialType.transparency,
        child: (to.widget as Hero).child,
      ),
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: FittedBox(
            child: SizedBox.square(
              dimension: _drawn,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SessionRequestorHeader.avatarOf(requestor, size: _drawn),
                  Positioned(
                    right: -8,
                    bottom: -8,
                    child: RequestorTrustBadge(style: style, size: 36),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Who is asking, at the top of the share screen and the pairing screen:
/// the party as the subject of the page. A 60 pt logo with a trust badge on
/// its corner, the name, and a one-line pill saying who vouches. The whole
/// card is a button that explains what that means ([onTap], the trust
/// sheet).
///
/// When nobody vouches the card gets a red ring and a tinted fill; the
/// share screen adds the banner under it.
class SessionRequestorHeader extends StatelessWidget {
  final TrustedParty requestor;

  /// Opens the trust sheet. Without it (or for an unevaluated party) the
  /// card is not a button.
  final VoidCallback? onTap;

  const SessionRequestorHeader({
    super.key,
    required this.requestor,
    this.onTap,
  });

  /// The fills of a requestor without a logo, picked by its name: deep
  /// enough that a white initial reads well, in both light and dark mode.
  static const _initialFills = [
    Color(0xFF2F5D8A),
    Color(0xFF7A1F2E),
    Color(0xFF3D6B4F),
    Color(0xFF6B4E8A),
    Color(0xFF8A5A2F),
  ];

  /// [requestor]'s logo, or its initial on a coloured disc when it has none
  /// (not the pale grey placeholder: this is the subject of the screen).
  static Widget avatarOf(TrustedParty requestor, {double size = 46}) {
    final image = requestor.image;
    if (image == null && requestor.imagePath == null) {
      final name = requestor.name.trim();
      final fill =
          _initialFills[name.codeUnits.fold(0, (a, c) => a + c) %
              _initialFills.length];
      return Semantics(
        label: requestor.name,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: ExcludeSemantics(
            child: Text(
              name.isEmpty ? "?" : name.characters.first.toUpperCase(),
              style: TextStyle(
                fontFamily: "Alexandria",
                fontWeight: FontWeight.w700,
                fontSize: size * 0.44,
                height: 1,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return IrmaAvatar(
      size: size,
      logoImage: image == null
          ? null
          : Base64Image(base64: image.base64, mimeType: image.mimeType),
      logoPath: image == null ? requestor.imagePath : null,
      logoSemanticsLabel: requestor.name,
      initials: requestor.name.isEmpty ? "?" : requestor.name.characters.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = RequestorTrustStyle.of(context, requestor);
    final risky = style.trust.risky;
    final label = style.label;
    final tap = style.trust == RequestorTrust.unevaluated ? null : onTap;

    final card = GlassSurface(
      key: const Key("session_requestor_header"),
      shape: RoundedSuperellipseBorder(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        side: risky
            ? BorderSide(color: palette.danger, width: 2)
            : BorderSide.none,
      ),
      fill: risky ? palette.errorSurface.withValues(alpha: 0.55) : null,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        spacing: 14,
        children: [
          RequestorLogo(requestor: requestor, style: style, size: 60),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  requestor.name,
                  key: const Key("session_requestor_name"),
                  style: palette
                      .display(20, weight: FontWeight.w700)
                      .copyWith(height: 26 / 20, color: palette.text),
                ),
                if (label != null)
                  _TrustPill(
                    key: const Key("session_requestor_trust"),
                    style: style,
                    label: label,
                  ),
              ],
            ),
          ),
          if (tap != null)
            ExcludeSemantics(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: palette.tint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: palette.link,
                ),
              ),
            ),
        ],
      ),
    );

    final status = label ?? "";
    if (tap == null) {
      return Semantics(
        container: true,
        label: [requestor.name, status].where((s) => s.isNotEmpty).join(", "),
        excludeSemantics: true,
        child: card,
      );
    }
    return Semantics(
      button: true,
      label: FlutterI18n.translate(
        context,
        "share.trust.card_semantics",
        translationParams: {"name": requestor.name, "status": status},
      ),
      excludeSemantics: true,
      child: PressScale(
        scale: 0.98,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: card,
        ),
      ),
    );
  }
}

/// The one-line pill under the name. A label too long for the line ends in
/// "…": the trust sheet spells it out.
class _TrustPill extends StatelessWidget {
  final RequestorTrustStyle style;
  final String label;

  const _TrustPill({super.key, required this.style, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      height: 26,
      padding: const EdgeInsetsDirectional.fromSTEB(6, 0, 10, 0),
      decoration: ShapeDecoration(
        color: style.pillFill,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(
            style.trust.vouched
                ? Icons.check_circle_rounded
                : Icons.warning_rounded,
            size: 16,
            color: style.badge ?? style.pillInk,
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: palette
                  .body(12.5, weight: FontWeight.w700)
                  .copyWith(color: style.pillInk),
            ),
          ),
        ],
      ),
    );
  }
}
