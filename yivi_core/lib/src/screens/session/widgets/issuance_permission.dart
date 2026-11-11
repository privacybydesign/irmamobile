import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../util/nfc_credentials.dart";
import "../../../widgets/caps_label.dart";
import "../../../widgets/centred_max_width.dart";
import "../../../widgets/compact_bar.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/floating_bar_placement.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/status_chip.dart";
import "../models/disclosure_view_model.dart";
import "../models/technical_details.dart";
import "document_issuance_permission.dart";
import "requestor_card.dart";
import "requestor_trust_sheet.dart";
import "session_columns.dart";
import "session_scaffold.dart";

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
  final VoidCallback? onDismiss;
  final VoidCallback? onGivePermission;
  final List<schemaless.Credential> issuedCredentials;

  /// The request waiting underneath this issuance, if any.
  final SessionState? forRequest;

  /// The issuance itself, for the technical details under the issuer's
  /// details; none without it.
  final SessionState? session;

  const IssuancePermission({
    super.key,
    this.onDismiss,
    this.onGivePermission,
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

  List<schemaless.Credential> get _cards => widget.issuedCredentials;

  IssuanceOffer get _offer => IssuanceOffer(
    cards: widget.issuedCredentials,
    forRequest: widget.forRequest,
  );

  @override
  void dispose() {
    _barTitleVisible.dispose();
    super.dispose();
  }

  void _openIssuer(schemaless.TrustedParty issuer) {
    final session = widget.session;
    showRequestorTrustSheet(
      context: context,
      requestor: issuer,
      issuer: true,
      logoHero: true,
      technicalDetails: session == null
          ? null
          : issuanceTechnicalDetailsOf(
              session,
              _cards,
              (key, [params]) => context.tr(key, params ?? const {}),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = _offer;
    final palette = YiviPalette.of(context);
    final isDocument =
        _cards.isNotEmpty &&
        _cards.every((c) => credentialRequiresNfc(c.credentialId));
    final note = offer.note(context);
    final issuer = _cards.firstOrNull?.issuer;
    final risky =
        note == null &&
        issuer != null &&
        requestorTrustOf(issuer) == RequestorTrust.unknown;
    final count = _cards.length;
    final heading = issuer == null
        ? null
        : IssuerHeading(
            issuer: issuer,
            count: count,
            onTrust: () => _openIssuer(issuer),
            cardKey: _issuerCardKey,
            logoHero: true,
          );
    final values = [
      const YouGetLabel(),
      ?note,
      if (isDocument)
        for (final card in _cards) DocumentIssuanceData(credential: card)
      else
        ...offer.receives(context),
    ];
    final reason = risky
        ? Text(
            context.tr("issuance.question.risky_reason", {
              "issuer": issuer.name,
            }),
            key: const Key("issuance_risky_reason"),
            textAlign: TextAlign.center,
            style: palette
                .body(13.5, weight: FontWeight.w600)
                .copyWith(color: palette.errorText, height: 19 / 13.5),
          )
        : null;
    final button = _button(risky: risky);

    // Held sideways, and on a tablet: who gives it at the left with the
    // button at its foot; the cards at the right.
    if (useSessionColumns(context) || useSheetColumns(context)) {
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
              panel: Padding(
                key: const Key("issuance_panel"),
                padding: EdgeInsets.fromLTRB(
                  0,
                  sidewaysPanelTop(context),
                  0,
                  FloatingBarPlacement.buttonBottom(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: SingleChildScrollView(child: heading)),
                    const SizedBox(height: 16),
                    if (reason != null) ...[reason, const SizedBox(height: 10)],
                    button,
                  ],
                ),
              ),
              content: SingleChildScrollView(
                key: const Key("issuance_scroll_view"),
                padding: EdgeInsets.fromLTRB(
                  4,
                  sidewaysContentTop(context),
                  0,
                  56 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: values,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final bar = IrmaBottomBarBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [?reason, button],
      ),
    );

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
              padding: insets + const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
  /// issuer), or back when there is nothing to add. No Cancel: the close
  /// button at the top declines.
  Widget _button({required bool risky}) {
    if (widget.onGivePermission == null) {
      return PillButton(
        key: const Key("bottom_bar_primary"),
        label: context.tr("session.navigation_bar.back"),
        size: PillSize.large,
        onPressed: () => widget.onDismiss?.call(),
      );
    }
    if (risky) {
      return PillButton(
        key: const Key("bottom_bar_primary"),
        label: context.tr("issuance.question.add_anyway"),
        style: PillStyle.neutral,
        size: PillSize.large,
        onPressed: () => widget.onGivePermission?.call(),
      );
    }
    return FancyPillButton(
      key: const Key("bottom_bar_primary"),
      label: issuanceAddLabel(context, _cards.length),
      onPressed: () => widget.onGivePermission?.call(),
    );
  }
}

/// What an issuer offers, for the screens that ask whether to add it: the
/// mismatch note ([note]) and every value, a group per card ([receives]).
/// The permission screen lays them out full-screen; the Change sheet shows
/// them as the last step of adding a card.
class IssuanceOffer {
  final List<schemaless.Credential> cards;

  /// The request waiting underneath this issuance, if any.
  final SessionState? forRequest;

  const IssuanceOffer({required this.cards, this.forRequest});

  List<IssuanceStep> get _steps =>
      forRequest?.disclosurePlan?.issueDuringDisclosure?.steps ??
      const <IssuanceStep>[];

  /// "This card doesn't count for {requestor}": inside a request, when an
  /// offered card won't do for it, what they ask next to what the card has.
  Widget? note(BuildContext context) {
    final miss = issuanceMismatches(cards, _steps).firstOrNull;
    final request = forRequest;
    if (miss == null || request == null) return null;
    final requestor = request.requestor.name;
    return _MismatchBox(
      key: const Key("issuance_mismatch"),
      head: context.tr("share.offer.not_counted", {"requestor": requestor}),
      asks: context.tr("share.offer.asks", {"requestor": requestor}),
      asked:
          "${miss.attributeName} ${localizedAttributeText(context, miss.required) ?? ""}",
      has: context.tr("share.offer.has"),
      got:
          "${miss.attributeName} ${localizedAttributeText(context, miss.offered) ?? "–"}",
    );
  }

  /// The chip of [card] inside a request: what doesn't count, and with
  /// several cards which one the request asks for ("Asked") and which comes
  /// along ("Comes too"). One card that counts has none.
  (String, DialogTone)? _tagOf(
    BuildContext context,
    schemaless.Credential card, {
    required bool mismatched,
  }) {
    final request = forRequest;
    if (request == null) return null;
    if (mismatched) {
      return (context.tr("share.offer.tag_not_counted"), DialogTone.danger);
    }
    if (cards.length == 1) return null;
    final used = {
      for (final step in _steps)
        for (final b in step.options)
          for (final d in b.credentials) d.credentialId,
    };
    return used.contains(card.credentialId)
        ? (context.tr("share.spot.asked"), DialogTone.info)
        : (context.tr("share.offer.tag_extra"), DialogTone.neutral);
  }

  String? _validUntil(BuildContext context, schemaless.Credential card) {
    final expiry = card.expiryDate ?? 0;
    if (expiry <= 0) return null;
    final lang = context.lang;
    return context.tr("wallet.detail.valid_until", {
      "date": printableDate(
        DateTime.fromMillisecondsSinceEpoch(expiry * 1000),
        lang,
      ),
    });
  }

  /// What comes in the app: a tile per card, as on the share screen (its
  /// picture, name, and how long it is valid, or who gives it), with every
  /// value under it and a chip in its head when it matters ([_tagOf]).
  List<Widget> receives(BuildContext context) {
    final mismatches = issuanceMismatches(cards, _steps);
    Set<String> mismatchedIn(schemaless.Credential card) => {
      for (final m in mismatches)
        if (m.credentialId == card.credentialId) claimPathKey(m.claimPath),
    };
    return [
      for (final (i, card) in cards.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Builder(
            builder: (context) {
              final bad = issuanceMismatches([card], _steps).isNotEmpty;
              final tag = _tagOf(context, card, mismatched: bad);
              return CardTile(
                key: Key("issuance_card_$i"),
                art: CredentialCardArt(
                  credential: card,
                  width: CardTile.miniWidth,
                ),
                title: card.name,
                subtitle: _validUntil(context, card) ?? card.issuer.name,
                chip: tag == null
                    ? null
                    : StatusChip(label: tag.$1, tone: tag.$2),
                body: [
                  YiviCredentialCardAttributeList(
                    card.attributes,
                    credentialId: card.credentialId,
                    namespaced: card.isMdoc,
                    disclosure: true,
                    showDividers: true,
                    mismatched: mismatchedIn(card),
                  ),
                ],
              );
            },
          ),
        ),
    ];
  }
}

/// An issuance permission on a phone held sideways: a panel at the left
/// with [overview] (the card or pile and its chips) in the middle of the
/// room above [actions]; the [title] question, the [note] and [receives] at
/// the right, scrolling.
class IssuanceLandscape extends StatelessWidget {
  final String title;
  final List<Widget> overview;
  final Widget? note;
  final List<Widget> receives;
  final Widget? actions;

  const IssuanceLandscape({
    super.key,
    required this.title,
    required this.overview,
    this.note,
    required this.receives,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final insets = MediaQuery.paddingOf(context);
    // The bar holds only the close button, in the corner beside the column.
    final top = cornerContentTop(context);
    return SidewaysLayout(
      panel: Padding(
        key: const Key("issuance_panel"),
        padding: EdgeInsets.fromLTRB(
          16,
          top,
          0,
          FloatingBarPlacement.buttonBottom(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: overview,
                  ),
                ),
              ),
            ),
            if (actions case final actions?) ...[
              const SizedBox(height: 16),
              actions,
            ],
          ],
        ),
      ),
      content: SingleChildScrollView(
        key: const Key("issuance_scroll_view"),
        padding: EdgeInsets.fromLTRB(0, top, 16, 16 + insets.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  key: const Key("issuance_question"),
                  style: palette
                      .display(24, weight: FontWeight.w700)
                      .copyWith(height: 30 / 24, color: palette.heading),
                ),
              ),
            ),
            if (note != null) ...[const SizedBox(height: 16), note!],
            const SizedBox(height: 12),
            ...receives,
          ],
        ),
      ),
    );
  }
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
    super.key,
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
      spacing: 12,
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: ShapeDecoration(
        color: palette.errorSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
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
/// the share screen's requestor ([RequestorCard.compact]): its logo and
/// badge, its name, who vouches for it, and an ⓘ ([onTrust], the issuer's
/// page).
class IssuerHeading extends StatelessWidget {
  final schemaless.TrustedParty issuer;
  final int count;
  final VoidCallback onTrust;

  /// The heading, for the bar's title once it has scrolled under the bar.
  final GlobalKey? titleKey;

  /// Where the issuer's logo is: it flies into the issuer's page.
  final GlobalKey? logoKey;

  /// The issuer's card, to see when it goes under the bar.
  final GlobalKey? cardKey;

  /// The logo is a hero into the trust sheet ([RequestorLogo.hero]), on the
  /// permission as a screen of its own.
  final bool logoHero;

  const IssuerHeading({
    super.key,
    required this.issuer,
    required this.count,
    required this.onTrust,
    this.titleKey,
    this.logoKey,
    this.cardKey,
    this.logoHero = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Column(
      key: const Key("issuance_heading"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            header: true,
            child: Text(
              count > 1
                  ? context.tr("issuance.heading.many", {"count": "$count"})
                  : context.tr("issuance.heading.one"),
              key: titleKey ?? const Key("issuance_question"),
              style: palette
                  .display(24, weight: FontWeight.w700)
                  .copyWith(height: 30 / 24, color: palette.text),
            ),
          ),
        ),
        const SizedBox(height: 18),
        KeyedSubtree(
          key: cardKey,
          child: RequestorCard.compact(
            requestor: issuer,
            onInfo: onTrust,
            logoKey: logoKey,
            logoHero: logoHero,
          ),
        ),
      ],
    );
  }
}

/// "This goes in your app", above the cards of an offer.
class YouGetLabel extends StatelessWidget {
  const YouGetLabel({super.key});

  @override
  Widget build(BuildContext context) => CapsLabel(
    context.tr("data.add.details.you_get"),
    padding: const EdgeInsets.fromLTRB(6, 24, 6, 8),
  );
}

/// A red wash behind the top of the page when nobody vouches for the
/// issuer, as the share screen has for a requestor nobody vouches for.
class IssuanceTrustWash extends StatelessWidget {
  final bool on;
  final Widget child;

  const IssuanceTrustWash({super.key, required this.on, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    final palette = YiviPalette.of(context);
    return Stack(
      children: [
        Positioned(
          key: const Key("issuance_trust_wash"),
          left: 0,
          right: 0,
          top: 0,
          height: 460,
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
        child,
      ],
    );
  }
}
