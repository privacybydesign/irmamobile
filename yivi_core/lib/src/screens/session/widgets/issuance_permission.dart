import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/date_formatter.dart";
import "../../../util/i18n.dart";
import "../../../util/nfc_credentials.dart";
import "../../../widgets/centred_max_width.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/floating_bar_placement.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_layout.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/press_scale.dart";
import "../../../widgets/status_chip.dart";
import "../../../widgets/surface_card.dart";
import "../models/disclosure_view_model.dart";
import "../models/technical_details.dart";
import "document_issuance_permission.dart";
import "requestor_card.dart";
import "requestor_trust_sheet.dart";
import "session_columns.dart";
import "session_scaffold.dart";

/// The button that adds an offer of [count] cards.
String issuanceAddLabel(BuildContext context, int count) => count > 1
    ? context.tr("issuance.add_many", {"count": "$count"})
    : context.tr("issuance.add");

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
  final _barTitleVisible = ValueNotifier(false);

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
    final question = issuer == null
        ? null
        : IssuerQuestion(
            issuer: issuer,
            question: note != null
                ? context.tr("issuance.question.anyway")
                : count > 1
                ? context.tr("issuance.question.many", {"count": "$count"})
                : context.tr("issuance.question.one"),
            onTrust: () => _openIssuer(issuer),
          );
    final values = [
      ?note,
      if (isDocument)
        for (final card in _cards) DocumentIssuanceData(credential: card)
      else
        ...offer.receives(context, headingKey: null),
    ];
    final reason = risky
        ? Text(
            context.tr("issuance.question.risky_reason", {
              "issuer": issuer.name,
            }),
            key: const Key("issuance_risky_reason"),
            textAlign: useSheetColumns(context)
                ? TextAlign.start
                : TextAlign.center,
            style: palette
                .body(13.5, weight: FontWeight.w600)
                .copyWith(color: palette.errorText, height: 19 / 13.5),
          )
        : null;
    final button = _button(risky: risky);

    // A phone held sideways: the issuer and the question at the left with
    // the button at its foot; the cards at the right, at most 420 wide.
    if (!useSessionColumns(context) && useSheetColumns(context)) {
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
                  16,
                  cornerContentTop(context),
                  0,
                  FloatingBarPlacement.buttonBottom(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: SingleChildScrollView(child: question)),
                    const SizedBox(height: 16),
                    if (reason != null) ...[reason, const SizedBox(height: 10)],
                    button,
                  ],
                ),
              ),
              content: SingleChildScrollView(
                key: const Key("issuance_scroll_view"),
                padding: EdgeInsets.fromLTRB(
                  0,
                  cornerContentTop(context),
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: SheetSplit.endMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: values,
                    ),
                  ),
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

    // Tablets: the issuer and the question on the left, the cards and the
    // button on the right.
    if (useSessionColumns(context)) {
      return SessionScaffold(
        wide: true,
        scrollsUnderBars: true,
        onDismiss: widget.onDismiss,
        body: IssuanceTrustWash(
          on: risky,
          child: SessionColumns(
            start: question ?? const SizedBox.shrink(),
            end: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: values,
            ),
            actions: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [?reason, button],
            ),
          ),
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "issuance.title",
      scrollsUnderBars: true,
      // The bar's title once the issuer and the question have scrolled
      // under it, as in the sheet.
      barTitleVisibility: _barTitleVisible,
      edgeShown: _barTitleVisible,
      bottomNavigationBar: bar,
      onDismiss: widget.onDismiss,
      body: IssuanceTrustWash(
        on: risky,
        child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.depth == 0) _barTitleVisible.value = n.metrics.pixels > 150;
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
                  spacing: 12,
                  children: [?question, const SizedBox(height: 8), ...values],
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

  /// The tag of [card] inside a request: what the request uses ("For
  /// {requestor}"), what doesn't count, or what comes along ("Comes too").
  String? _tagOf(
    BuildContext context,
    schemaless.Credential card, {
    required bool mismatched,
  }) {
    final request = forRequest;
    if (request == null) return null;
    if (mismatched) return context.tr("share.offer.tag_not_counted");
    final used = {
      for (final step in _steps)
        for (final b in step.options)
          for (final d in b.credentials) d.credentialId,
    };
    if (used.contains(card.credentialId) || cards.length == 1) {
      return context.tr("issuance.for_request", {
        "requestor": request.requestor.name,
      });
    }
    return context.tr("share.offer.tag_extra");
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

  /// "You will receive" and every value: a group per card, with the card's
  /// mini art, name and validity on top.
  /// [headingKey]: what the heading says ("You will receive"; "In your
  /// app" once added).
  /// No heading when [headingKey] is null (the question above says what
  /// they are).
  List<Widget> receives(
    BuildContext context, {
    String? headingKey = "issuance.you_will_receive",
  }) {
    final mismatches = issuanceMismatches(cards, _steps);
    // Per card: a value the request waiting underneath cannot use.
    final bad = [
      for (final card in cards) issuanceMismatches([card], _steps).isNotEmpty,
    ];
    final palette = YiviPalette.of(context);
    final many = cards.length > 1;

    Set<String> mismatchedIn(schemaless.Credential card) => {
      for (final m in mismatches)
        if (m.credentialId == card.credentialId) claimPathKey(m.claimPath),
    };

    Widget values(schemaless.Credential card) =>
        YiviCredentialCardAttributeList(
          card.attributes,
          credentialId: card.credentialId,
          namespaced: card.isMdoc,
          showDividers: true,
          mismatched: mismatchedIn(card),
        );

    final key = headingKey;
    final heading = key == null
        ? null
        : Text(context.tr(key), style: palette.display(16));

    return [
      if (heading != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: Semantics(
            header: true,
            child: many
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 8,
                    children: [
                      Expanded(child: heading),
                      Flexible(
                        child: Text(
                          context.tr("issuance.all_together"),
                          textAlign: TextAlign.end,
                          style: palette
                              .body(13)
                              .copyWith(color: palette.secondaryText),
                        ),
                      ),
                    ],
                  )
                : heading,
          ),
        ),
      // One card looks like each of several: its name above its values.
      for (final (i, card) in cards.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: SurfaceCard(
            key: Key("issuance_card_$i"),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupHeader(
                    card: card,
                    until: _validUntil(context, card),
                    tag: _tagOf(context, card, mismatched: bad[i]),
                    tagBad: bad[i],
                  ),
                  Divider(height: 1, color: palette.divider),
                  values(card),
                ],
              ),
            ),
          ),
        ),
    ];
  }
}

/// A card's mini art, name and validity above its values.
class _GroupHeader extends StatelessWidget {
  final schemaless.Credential card;
  final String? until;

  /// Inside a request: what it is for ("For {requestor}", "Comes too",
  /// "Doesn't count", the last in red when [tagBad]).
  final String? tag;
  final bool tagBad;

  const _GroupHeader({
    required this.card,
    required this.until,
    this.tag,
    this.tagBad = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Row(
        spacing: 10,
        children: [
          ExcludeSemantics(
            child: CredentialCardArt(credential: card, width: 34),
          ),
          Expanded(
            child: Text(
              card.name,
              style: palette.display(14).copyWith(color: palette.heading),
            ),
          ),
          if (tag != null)
            StatusChip(
              key: const Key("issuance_card_tag"),
              label: tag!,
              tone: tagBad ? DialogTone.danger : DialogTone.info,
            )
          // Wraps rather than pushing the name off at a large text size.
          else if (until != null)
            Flexible(
              child: Text(
                until!,
                textAlign: TextAlign.end,
                style: palette.body(12).copyWith(color: palette.secondaryText),
              ),
            ),
        ],
      ),
    );
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

/// The top of the page that asks whether to add a card: who issues it (the
/// logo with its trust badge, the name, and the trust label, which opens
/// the issuer's details, [onTrust]) and the [question] as the page's
/// heading. Upright all centred; sideways (the left column of a sheet) the
/// issuer as one row, logo at the left, name and label stacked beside it,
/// and the question under it, left-aligned.
class IssuerQuestion extends StatelessWidget {
  final schemaless.TrustedParty issuer;
  final String question;
  final VoidCallback? onTrust;

  const IssuerQuestion({
    super.key,
    required this.issuer,
    required this.question,
    this.onTrust,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final style = RequestorTrustStyle.of(context, issuer);
    final sideways = useSheetColumns(context);
    final logo = RequestorLogo(requestor: issuer, style: style, size: 64);
    final name = Text(
      issuer.name,
      key: const Key("issuance_issuer_name"),
      textAlign: sideways ? TextAlign.start : TextAlign.center,
      style: palette.display(17).copyWith(height: 23 / 17, color: palette.text),
    );
    final label = style.label == null
        ? null
        : IssuerTrustLabel(style: style, onTap: onTrust);
    final heading = Semantics(
      header: true,
      child: Text(
        question,
        key: const Key("issuance_question"),
        textAlign: sideways ? TextAlign.start : TextAlign.center,
        style: palette
            .display(22, weight: FontWeight.w700)
            .copyWith(height: 30 / 22, color: palette.heading),
      ),
    );
    if (sideways) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 14,
            children: [
              logo,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [name, ?label],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          heading,
        ],
      );
    }
    return Column(
      key: const Key("issuance_issuer_question"),
      children: [
        const SizedBox(height: 8),
        logo,
        const SizedBox(height: 12),
        name,
        if (label != null) ...[const SizedBox(height: 10), label],
        const SizedBox(height: 20),
        heading,
      ],
    );
  }
}

/// The issuer's trust in one label, in the tier's colours (as on the share
/// screen), with ⓘ: a tap opens what it means.
class IssuerTrustLabel extends StatelessWidget {
  final RequestorTrustStyle style;
  final VoidCallback? onTap;

  const IssuerTrustLabel({super.key, required this.style, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final label = style.label ?? "";
    return Semantics(
      button: onTap != null,
      label: label,
      hint: onTap == null ? null : context.tr("issuance.trust.label_hint"),
      excludeSemantics: true,
      child: PressScale(
        enabled: onTap != null,
        child: GestureDetector(
          key: const Key("issuance_trust_label"),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 10, 0),
            decoration: BoxDecoration(
              color: style.pillFill,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: palette
                        .body(13.5, weight: FontWeight.w700)
                        .copyWith(color: style.pillInk),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: style.pillInk,
                  ),
              ],
            ),
          ),
        ),
      ),
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
