import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/i18n.dart";
import "../../../widgets/compact_bar.dart";
import "../../../widgets/corner_badge.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/party_avatar.dart";
import "../../../widgets/press_scale.dart";
import "../../../widgets/surface_card.dart";

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

/// The round badge on a requestor's logo: a check when someone vouches, a
/// cross when nobody does, nothing when it was not evaluated.
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
        icon: style.trust.vouched ? Icons.check_rounded : Icons.close_rounded,
        fill: fill,
        size: size,
        iconSize: size * 0.55,
        ring: palette.surface,
        ringWidth: size / 10,
      ),
    );
  }
}

/// The hero tag of [requestor]'s logo ([RequestorLogo.hero]).
Object requestorLogoHeroTag(TrustedParty requestor) =>
    ("requestor_logo", requestor.id, requestor.name);

/// A requestor's logo with its trust badge on the corner, at [size]. It is
/// drawn at one size and scaled, so the badge keeps its place at any size
/// and the logo can fly between the card (52 pt) and the trust sheet (84 pt)
/// as one hero ([hero]), or into the issuer's page in the issuance sheet, a
/// subpage and not a route ([flightKey], see [YiviFlight]).
class RequestorLogo extends StatelessWidget {
  final TrustedParty requestor;
  final RequestorTrustStyle style;
  final double size;

  /// The trust badge on the corner.
  final bool showBadge;

  /// Where it flies from or to ([FlightSpot]).
  final GlobalKey? flightKey;

  /// A hero between the share screen's card and the trust sheet; also back
  /// into the card as the sheet is dragged closed by hand.
  final bool hero;

  const RequestorLogo({
    super.key,
    required this.requestor,
    required this.style,
    required this.size,
    this.showBadge = true,
    this.flightKey,
    this.hero = false,
  });

  static const double _drawn = 84;

  @override
  Widget build(BuildContext context) {
    final logo = ExcludeSemantics(
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
    );
    final key = flightKey;
    if (hero) {
      final flies = Hero(
        tag: requestorLogoHeroTag(requestor),
        // Also back into the card when the sheet is dragged closed.
        transitionOnUserGestures: true,
        flightShuttleBuilder: (_, _, _, _, to) => Material(
          type: MaterialType.transparency,
          child: (to.widget as Hero).child,
        ),
        child: logo,
      );
      // Still found by [flightKey], for the flight into the done screen.
      return key == null ? flies : KeyedSubtree(key: key, child: flies);
    }
    return FlightSpot.maybe(key, logo);
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

/// Who is asking (the share screen, [RequestorCard.compact]) or who gives a
/// card (the question page of adding one), and the pairing screen: the party
/// as the subject of the page.
///
/// The compact form: a white card with the logo (52) and its badge (a green
/// check when Yivi knows the party, blue when someone else vouches, a red
/// cross when nobody does), the name, one line saying who vouches in the
/// badge's colour ("Registered with Yivi", "Not known to Yivi"), and an ⓘ at
/// the right end that opens the trust sheet ([onInfo]). The card itself is
/// not a button. An unevaluated party gets no badge, no line and no ⓘ.
///
/// The centred form (pairing) keeps the pill with ⓘ and the whole card as
/// the button.
class RequestorCard extends StatelessWidget {
  final TrustedParty requestor;

  /// Opens the trust sheet.
  final VoidCallback? onInfo;

  /// Where the logo is: it flies into the trust sheet (or the issuer's page)
  /// and back.
  final GlobalKey? logoKey;

  /// The logo is a hero into the trust sheet ([RequestorLogo.hero]).
  final bool logoHero;

  /// The share screen's form, under its title and in the landscape panel:
  /// the logo (52) beside the name and who vouches, with ⓘ, all aligned to
  /// the left like the title. Without it the centred form of the pairing
  /// screen.
  final bool compact;

  const RequestorCard({super.key, required this.requestor, this.onInfo})
    : compact = false,
      logoKey = null,
      logoHero = false;

  const RequestorCard.compact({
    super.key,
    required this.requestor,
    this.onInfo,
    this.logoKey,
    this.logoHero = false,
  }) : compact = true;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = RequestorTrustStyle.of(context, requestor);
    final risky = style.trust.risky;
    final label = style.label;
    final tap = style.trust == RequestorTrust.unevaluated ? null : onInfo;
    if (compact) return _compact(context, style, label, tap);
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
    final decoration = SurfaceCard.decoration(context);

    final card = DecoratedBox(
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
          ],
        ),
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
        scale: PressScale.card,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tap,
          child: card,
        ),
      ),
    );
  }

  Widget _compact(
    BuildContext context,
    RequestorTrustStyle style,
    String? label,
    VoidCallback? tap,
  ) {
    final palette = YiviPalette.of(context);
    final ink = style.badge ?? palette.secondaryText;
    final status = label ?? "";
    return DecoratedBox(
      key: const Key("session_requestor_header"),
      decoration: SurfaceCard.decoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          spacing: 12,
          children: [
            RequestorLogo(
              requestor: requestor,
              style: style,
              size: 52,
              flightKey: logoKey,
              hero: logoHero,
            ),
            Expanded(
              child: Semantics(
                container: true,
                label: [
                  requestor.name,
                  status,
                ].where((s) => s.isNotEmpty).join(", "),
                excludeSemantics: true,
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
                          .copyWith(height: 22 / 17, color: palette.text),
                    ),
                    if (label != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          label,
                          key: const Key("session_requestor_trust"),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: palette
                              .body(14, weight: FontWeight.w600)
                              .copyWith(height: 19 / 14, color: ink),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (tap != null)
              Semantics(
                button: true,
                label: FlutterI18n.translate(
                  context,
                  "share.trust.card_semantics",
                  translationParams: {"name": requestor.name, "status": status},
                ),
                excludeSemantics: true,
                child: PressScale(
                  child: GestureDetector(
                    key: const Key("session_requestor_info"),
                    behavior: HitTestBehavior.opaque,
                    onTap: tap,
                    // A 44 target around the 32 disc.
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: ToneDisc(
                          icon: Icons.info_outline_rounded,
                          tone: style.trust.risky
                              ? DialogTone.danger
                              : DialogTone.info,
                          size: 32,
                          iconSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
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

  /// Where the logo is, for a flight from it.
  final GlobalKey? logoKey;

  const RequestorCompactBar({
    super.key,
    required this.requestor,
    required this.subtitle,
    this.opacity = 1,
    this.logoKey,
  });

  @override
  Widget build(BuildContext context) {
    final style = RequestorTrustStyle.of(context, requestor);
    return CompactBar(
      key: const Key("requestor_compact_bar"),
      opacity: opacity,
      leading: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 32,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              KeyedSubtree(
                key: logoKey,
                child: requestorAvatar(requestor, size: 32),
              ),
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

/// A red wash behind the top of a page about a party nobody vouches for,
/// [height] down (the wash itself has [washKey]). With [fill] the page
/// fills the wash's stack; without, the stack takes the page's own size
/// (a sheet page, whose height follows its content).
class TrustWash extends StatelessWidget {
  final bool on;
  final Key washKey;
  final double height;
  final bool fill;
  final Widget child;

  const TrustWash({
    super.key,
    required this.on,
    required this.washKey,
    this.height = 460,
    this.fill = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    final palette = YiviPalette.of(context);
    return Stack(
      children: [
        Positioned(
          key: washKey,
          left: 0,
          right: 0,
          top: 0,
          height: height,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    palette.errorSurface,
                    palette.errorSurface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (fill) Positioned.fill(child: child) else child,
      ],
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
