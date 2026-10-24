import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_shadows.dart";
import "../../../util/i18n.dart";
import "../../../widgets/compact_bar.dart";
import "../../../widgets/corner_badge.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/party_avatar.dart";

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
    return switch (trust) {
      RequestorTrust.yivi => RequestorTrustStyle._(
        trust: trust,
        badge: palette.successText,
        pillFill: palette.successSurface,
        pillInk: palette.successText,
        label: context.tr("share.trust.pill.yivi"),
      ),
      RequestorTrust.elsewhere => RequestorTrustStyle._(
        trust: trust,
        badge: palette.link,
        pillFill: palette.infoSurface,
        pillInk: palette.noteText,
        label: switch (elsewhereSourceOf(party)) {
          ElsewhereSource.euTrustedList => context.tr("share.trust.pill.eu"),
          ElsewhereSource.namedAnchor => context.tr("share.trust.pill.anchor", {
            "anchor": party.trustAnchor!,
          }),
          ElsewhereSource.unspecified => context.tr(
            "share.trust.pill.confirmed",
          ),
        },
      ),
      RequestorTrust.unknown => RequestorTrustStyle._(
        trust: trust,
        badge: palette.dangerFill,
        pillFill: palette.errorSurface,
        pillInk: palette.errorText,
        label: context.tr("share.trust.pill.unknown"),
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
      child: CornerBadge(
        icon: style.trust.vouched
            ? Icons.check_rounded
            : Icons.priority_high_rounded,
        fill: fill,
        size: size,
        iconSize: size * 0.55,
        ring: palette.surface,
        ringWidth: size / 10,
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

  /// The trust badge on the corner. The trust sheet keeps it; the share
  /// screen's card shows a vouched party's check in its pill instead.
  final bool showBadge;

  const RequestorLogo({
    super.key,
    required this.requestor,
    required this.style,
    required this.size,
    this.showBadge = true,
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
                  requestorAvatar(requestor, size: _drawn),
                  if (showBadge)
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

/// [requestor]'s logo, or its initial on a coloured disc when it has none
/// (not the pale grey placeholder: this is the subject of the screen).
Widget requestorAvatar(TrustedParty requestor, {double size = 46}) =>
    PartyAvatar(
      name: requestor.name,
      image: requestor.image,
      imagePath: requestor.imagePath,
      size: size,
    );

/// Who is asking, at the top of the share screen and the pairing screen:
/// the party as the subject of the page. A centred card with a 64 pt logo,
/// the name, a pill saying who vouches with ⓘ next to it, and [ask] under
/// it ("is asking for your data"). The whole card is a button that explains
/// what the pill means ([onInfo], the trust sheet).
///
/// One mark of trust: a party someone vouches for has its check in the pill
/// only, not on the logo. A party nobody vouches for gets a red ! on its
/// logo and a red "Not checked" pill. An unevaluated party gets neither, and
/// the card is not a button.
class RequestorCard extends StatelessWidget {
  final TrustedParty requestor;

  /// "is asking for your data", under the pill; none on the pairing screen.
  final String? ask;

  /// Opens the trust sheet.
  final VoidCallback? onInfo;

  /// The landscape form, for the panel at the left: the logo (52) beside the
  /// name and [ask], the pill with ⓘ under them.
  final bool compact;

  const RequestorCard({
    super.key,
    required this.requestor,
    this.ask,
    this.onInfo,
  }) : compact = false;

  const RequestorCard.compact({
    super.key,
    required this.requestor,
    this.ask,
    this.onInfo,
  }) : compact = true;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = RequestorTrustStyle.of(context, requestor);
    final risky = style.trust.risky;
    final label = risky
        ? FlutterI18n.translate(context, "share.trust.pill.unchecked")
        : style.label;
    final tap = style.trust == RequestorTrust.unevaluated ? null : onInfo;
    final pillRow = label == null
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Flexible(
                child: RequestorTrustPill(
                  key: const Key("session_requestor_trust"),
                  style: style,
                  label: label,
                ),
              ),
              if (tap != null)
                ToneDisc(
                  key: const Key("session_requestor_info"),
                  icon: Icons.info_outline_rounded,
                  tone: risky ? DialogTone.danger : DialogTone.info,
                  size: 32,
                  iconSize: 18,
                ),
            ],
          );
    final decoration = YiviShadows.surfaceCard(palette);

    final card = compact
        ? DecoratedBox(
            key: const Key("session_requestor_header"),
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      RequestorLogo(
                        requestor: requestor,
                        style: style,
                        size: 52,
                        showBadge: !style.trust.vouched,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requestor.name,
                              key: const Key("session_requestor_name"),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: palette
                                  .display(17, weight: FontWeight.w700)
                                  .copyWith(
                                    height: 22 / 17,
                                    color: palette.text,
                                  ),
                            ),
                            if (ask != null)
                              Text(
                                ask!,
                                key: const Key("session_requestor_ask"),
                                style: palette
                                    .body(13.5)
                                    .copyWith(
                                      height: 18 / 13.5,
                                      color: palette.heading,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ?pillRow,
                ],
              ),
            ),
          )
        : DecoratedBox(
            key: const Key("session_requestor_header"),
            decoration: decoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  RequestorLogo(
                    requestor: requestor,
                    style: style,
                    size: 64,
                    // The check of a vouched party is in the pill, once.
                    showBadge: !style.trust.vouched,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    requestor.name,
                    key: const Key("session_requestor_name"),
                    textAlign: TextAlign.center,
                    style: palette
                        .display(22, weight: FontWeight.w700)
                        .copyWith(height: 28 / 22, color: palette.text),
                  ),
                  if (pillRow != null) ...[const SizedBox(height: 8), pillRow],
                  if (ask != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      ask!,
                      key: const Key("session_requestor_ask"),
                      textAlign: TextAlign.center,
                      style: palette
                          .body(16)
                          .copyWith(height: 23 / 16, color: palette.heading),
                    ),
                  ],
                ],
              ),
            ),
          );

    final status = [label, ask].nonNulls.join(", ");
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
        scale: PressScale.card,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: card,
        ),
      ),
    );
  }
}

/// [RequestorCard] in one line, for the glass bar once the card has
/// scrolled away, as on the activity and credential detail pages: the logo
/// with a small check (vouched) or red ! (nobody vouches), the name, and
/// [subtitle] ("is asking for your data").
class RequestorCompactBar extends StatelessWidget {
  final TrustedParty requestor;
  final String subtitle;
  final double opacity;

  const RequestorCompactBar({
    super.key,
    required this.requestor,
    required this.subtitle,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    final style = RequestorTrustStyle.of(context, requestor);
    return GlassCompactBar(
      key: const Key("requestor_compact_bar"),
      opacity: opacity,
      leading: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              requestorAvatar(requestor, size: 32),
              Positioned(
                right: -3,
                bottom: -3,
                child: RequestorTrustBadge(
                  key: const Key("requestor_compact_badge"),
                  style: style,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
      title: requestor.name,
      subtitle: TextSpan(text: subtitle),
    );
  }
}

/// The one-line pill under the name. A label too long for the line ends in
/// "…": the trust sheet spells it out.
class RequestorTrustPill extends StatelessWidget {
  final RequestorTrustStyle style;
  final String label;

  const RequestorTrustPill({
    super.key,
    required this.style,
    required this.label,
  });

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
