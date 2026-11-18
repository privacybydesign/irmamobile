import "package:material_ui/material_ui.dart";

import "../../../models/credential.dart";
import "../../../models/session_state.dart";
import "../../../theme/yivi_palette.dart";
import "../../../theme/yivi_space.dart";
import "../../../util/i18n.dart";
import "../../../widgets/bars/action_bar.dart";
import "../../../widgets/bars/app_bar.dart";
import "../../../widgets/bars/compact_bar.dart";
import "../../../widgets/buttons/pill_buttons.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/layout/centred_max_width.dart";
import "../../../widgets/text/caps_label.dart";
import "../../embedded_issuance_flows/documents/nfc_credentials.dart";
import "../layout/session_heading.dart";
import "../layout/session_layout.dart";
import "../layout/session_scaffold.dart";
import "../models/issuance_view_model.dart";
import "../models/technical_details.dart";
import "../requestor/requestor_card.dart";
import "../requestor/requestor_trust_sheet.dart";
import "document_issuance_permission.dart";
import "received_card_tile.dart";

/// The button that adds an offer of [count] cards.
String issuanceAddLabel(BuildContext context, int count) => count > 1
    ? context.tr("share.offer.add_many", {"count": "$count"})
    : context.tr("share.offer.add");

/// "Do you want to add this card?" as a page of its own: who issues it (the
/// logo with its trust badge, the name, the trust label, which opens the
/// issuer's details in a sheet on top) above the question, the cards with
/// every value they hold under it, one button at the bottom. The same page
/// as the question in the Change sheet, full screen.
///
/// Several cards are added together (an issuance is all or nothing), so
/// the button says how many. Inside a request ([forRequest]), a note warns
/// before adding a card whose value that request cannot use. For an issuer
/// nobody vouches for the top is washed red and the button becomes a
/// neutral "Add anyway", with the reason above it. A document read from its
/// chip shows its data as the document flow does ([DocumentIssuanceData]).
class IssuancePermission extends StatefulWidget {
  final VoidCallback onDismiss;
  final VoidCallback onGivePermission;
  final List<Credential> issuedCredentials;

  /// The request waiting underneath this issuance, if any.
  final SessionState? forRequest;

  /// The issuance itself, for the technical details under the issuer's
  /// details; none without it (tests).
  final SessionState? session;

  const IssuancePermission({
    super.key,
    required this.onDismiss,
    required this.onGivePermission,
    this.forRequest,
    this.session,
    required this.issuedCredentials,
  });

  @override
  State<IssuancePermission> createState() => _IssuancePermissionState();
}

class _IssuancePermissionState extends State<IssuancePermission> {
  /// The issuer's card has scrolled under the bar: the compact bar then
  /// says who gives the card, as the share screen's says who asks.
  final _barTitleVisible = ValueNotifier(false);
  final _headingKey = GlobalKey(debugLabel: "issuance_heading");
  final _issuerCardKey = GlobalKey(debugLabel: "issuance_issuer_card");

  List<Credential> get _cards => widget.issuedCredentials;

  /// The full screen keeps "Add" for a card that does not count: it has
  /// no step to go back to.
  IssuanceOfferState get _offer => issuanceOfferOf(
    widget.issuedCredentials,
    forRequest: widget.forRequest,
    retryOnMismatch: false,
  );

  @override
  void dispose() {
    _barTitleVisible.dispose();
    super.dispose();
  }

  void _openIssuer(TrustedParty issuer) {
    final session = widget.session;
    showRequestorTrustSheet(
      context: context,
      requestor: issuer,
      issuer: true,
      logoHeroTag: requestorLogoHeroTag(issuer),
      technicalDetails: session == null
          ? null
          : issuanceTechnicalDetailsOf(session, _cards, context.tr),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    final isDocument =
        _cards.isNotEmpty &&
        _cards.every((c) => credentialRequiresNfc(c.credentialId));
    final note = IssuanceMismatchNote.maybe(offer);
    final issuer = offer.issuer;
    final risky = offer.risky;
    final count = _cards.length;
    final heading = issuer == null
        ? null
        : issuanceHeading(
            context,
            issuer: issuer,
            count: count,
            onTrust: () => _openIssuer(issuer),
            cardKey: _issuerCardKey,
            logoHeroTag: requestorLogoHeroTag(issuer),
          );
    final values = [
      const YouGetLabel(),
      ?note,
      if (isDocument)
        for (final card in _cards) DocumentIssuanceData(credential: card)
      else
        ...receivedCardTiles(context, offer),
    ];
    final reason = risky ? IssuanceRiskyReason(issuer: issuer!) : null;
    final button = _button(risky: risky);

    // Held sideways, and on a tablet: who gives it at the left with the
    // button at its foot; the cards at the right.
    if (SessionLayout.of(context).split) {
      return SessionScaffold(
        wide: true,
        scrollsUnderBars: true,
        cornerClose: true,
        onDismiss: widget.onDismiss,
        // The body's own context sees the bars.
        body: Builder(
          builder: (context) => IssuanceTrustWash(
            on: risky,
            child: SidewaysLayout(
              panel: SessionPanel(
                key: const Key("issuance_panel"),
                top: heading,
                above: reason,
                action: button,
              ),
              content: SessionPanelContent(
                scrollKey: const Key("issuance_scroll_view"),
                children: values,
              ),
            ),
          ),
        ),
      );
    }

    final bar = ActionBar(above: reason, actions: [button]);

    return SessionScaffold(
      appBarTitle: "issuance.title",
      scrollsUnderBars: true,
      // Once the issuer's name goes under the bar: who gives the card, in
      // the bar (without an issuer, the bar's title).
      barTitleVisibility: issuer == null ? _barTitleVisible : null,
      startBar: issuer == null
          ? null
          : CompactBarDropIn(
              shown: _barTitleVisible,
              bar: (t) => RequestorCompactBar(
                requestor: issuer,
                subtitle: count > 1
                    ? context.tr("issuance.bar_subtitle.many", {
                        "count": "$count",
                      })
                    : context.tr("issuance.bar_subtitle.one"),
                opacity: t,
              ),
            ),
      edgeShown: _barTitleVisible,
      bottomNavigationBar: bar,
      onDismiss: widget.onDismiss,
      body: IssuanceTrustWash(
        on: risky,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0) {
              _barTitleVisible.value =
                  (issuer == null
                      ? headerUnderBar(context, _headingKey)
                      // The top of the name, 12 into the card, as on the
                      // share screen.
                      : headerUnderBar(context, _issuerCardKey, at: 12)) ??
                  false;
            }
            return false;
          },
          child: BarInsetsBuilder(
            builder: (context, insets) => SingleChildScrollView(
              key: const Key("issuance_scroll_view"),
              padding:
                  insets +
                  const EdgeInsets.fromLTRB(
                    YiviSpace.x16,
                    YiviSpace.x16,
                    YiviSpace.x16,
                    YiviSpace.x24,
                  ),
              child: CentredMaxWidth(
                maxWidth: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (heading != null)
                      KeyedSubtree(key: _headingKey, child: heading),
                    ...values,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The way on: add (a neutral "Add anyway" when nobody vouches for the
  /// issuer). No Cancel: the close button at the top declines.
  Widget _button({required bool risky}) {
    if (risky) {
      return PillButton(
        key: const Key("bottom_bar_primary"),
        label: context.tr("issuance.question.add_anyway"),
        style: PillStyle.neutral,
        size: PillSize.large,
        onPressed: widget.onGivePermission,
      );
    }
    return FancyPillButton(
      key: const Key("bottom_bar_primary"),
      label: issuanceAddLabel(context, _cards.length),
      onPressed: widget.onGivePermission,
    );
  }
}

/// "This card doesn't count for {requestor}": inside a request, when an
/// offered card won't do for it, what they ask next to what the card has.
class IssuanceMismatchNote extends StatelessWidget {
  final IssuanceMismatch miss;
  final String requestor;

  const IssuanceMismatchNote({
    super.key,
    required this.miss,
    required this.requestor,
  });

  /// The note of [offer], if a card does not count for its request.
  static Widget? maybe(IssuanceOfferState offer) {
    final miss = offer.note;
    final requestor = offer.requestor;
    if (miss == null || requestor == null) return null;
    return IssuanceMismatchNote(
      key: const Key("issuance_mismatch"),
      miss: miss,
      requestor: requestor.name,
    );
  }

  @override
  Widget build(BuildContext context) => _MismatchBox(
    head: context.tr("share.offer.not_counted", {"requestor": requestor}),
    asks: context.tr("share.offer.asks", {"requestor": requestor}),
    asked:
        "${miss.attributeName} ${localizedAttributeText(context, miss.required) ?? ""}",
    has: context.tr("share.offer.has"),
    got:
        "${miss.attributeName} ${localizedAttributeText(context, miss.offered) ?? "–"}",
  );
}

/// "This card doesn't count for {requestor}", with what they ask and what
/// the card has under it, the card's value in red.
class _MismatchBox extends StatelessWidget {
  final String head;
  final String asks;
  final String asked;
  final String has;
  final String got;

  const _MismatchBox({
    required this.head,
    required this.asks,
    required this.asked,
    required this.has,
    required this.got,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    Widget row(String label, String value, {bool bad = false}) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: YiviSpace.x12,
      children: [
        Expanded(
          child: Text(
            label,
            style: palette
                .body(14)
                .copyWith(height: 20 / 14, color: palette.heading),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: palette
                .body(14, weight: FontWeight.w700)
                .copyWith(
                  height: 20 / 14,
                  color: bad ? palette.errorText : palette.text,
                ),
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(
        YiviSpace.x16,
        YiviSpace.x12,
        YiviSpace.x16,
        YiviSpace.x12,
      ),
      decoration: ShapeDecoration(
        color: palette.errorSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: YiviSpace.x8,
        children: [
          Text(
            head,
            style: palette
                .body(15, weight: FontWeight.w700)
                .copyWith(height: 21 / 15, color: palette.errorText),
          ),
          row(asks, asked),
          row(has, got, bad: true),
        ],
      ),
    );
  }
}

/// Who gives the card, at the top of the question whether to add it: "You
/// get a card from" (or "{n} cards"), and the issuer as a card under it, as
/// the share screen's requestor: its logo and badge, its name, who vouches
/// for it, and an ⓘ ([onTrust], the issuer's page).
Widget issuanceHeading(
  BuildContext context, {
  required TrustedParty issuer,
  required int count,
  required VoidCallback onTrust,
  Key? titleKey,
  GlobalKey? logoKey,
  GlobalKey? cardKey,
  Object? logoHeroTag,
}) => SessionHeading(
  key: const Key("issuance_heading"),
  title: count > 1
      ? context.tr("issuance.heading.many", {"count": "$count"})
      : context.tr("issuance.heading.one"),
  titleKey: titleKey ?? const Key("issuance_question"),
  party: issuer,
  onInfo: onTrust,
  logoKey: logoKey,
  cardKey: cardKey,
  logoHeroTag: logoHeroTag,
);

/// "This goes in your app", above the cards of an offer.
class YouGetLabel extends StatelessWidget {
  const YouGetLabel({super.key});

  @override
  Widget build(BuildContext context) => CapsLabel(
    context.tr("data.add.details.you_get"),
    padding: const EdgeInsets.fromLTRB(
      YiviSpace.x8,
      YiviSpace.x24,
      YiviSpace.x8,
      YiviSpace.x8,
    ),
  );
}

/// Why adding says "anyway": nobody vouches for [issuer]. In red above the
/// button.
class IssuanceRiskyReason extends StatelessWidget {
  final TrustedParty issuer;
  final TextAlign textAlign;

  const IssuanceRiskyReason({
    super.key,
    required this.issuer,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Text(
      context.tr("issuance.question.risky_reason", {"issuer": issuer.name}),
      key: const Key("issuance_risky_reason"),
      textAlign: textAlign,
      style: palette
          .body(15, weight: FontWeight.w600)
          .copyWith(color: palette.errorText, height: 20 / 15),
    );
  }
}

/// A red wash behind the top of the page when nobody vouches for the
/// issuer, as the share screen has for a requestor nobody vouches for.
class IssuanceTrustWash extends StatelessWidget {
  final bool on;
  final Widget child;

  const IssuanceTrustWash({super.key, required this.on, required this.child});

  @override
  Widget build(BuildContext context) => TrustWash(
    on: on,
    washKey: const Key("issuance_trust_wash"),
    child: child,
  );
}
