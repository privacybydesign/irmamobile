import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/date_formatter.dart";
import "../../../util/nfc_credentials.dart";
import "../../../widgets/card_pile.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/glass/floating_bar_placement.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/info_chips.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar.dart";
import "../../../widgets/large_title_scroll_view.dart";
import "../models/disclosure_view_model.dart";
import "document_issuance_permission.dart";
import "session_columns.dart";
import "session_scaffold.dart";

/// "Do you want to add this data to your Yivi app?": the card an issuer
/// offers, or a pile of them, with every value it holds.
///
/// Several cards are added together (an issuance is all or nothing), so
/// the button says how many. When the issuance runs inside a request
/// ([forRequest]), a tinted chip says which request and step it is for, and
/// a note warns before adding a card whose value that request cannot use.
class IssuancePermission extends StatefulWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onGivePermission;
  final List<schemaless.Credential> issuedCredentials;

  /// Name of the issuer whose website the user just came back from, if any.
  final String? returnedFromIssuer;

  /// The request waiting underneath this issuance, if any.
  final SessionState? forRequest;

  const IssuancePermission({
    super.key,
    this.onDismiss,
    this.onGivePermission,
    this.returnedFromIssuer,
    this.forRequest,
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
    returnedFromIssuer: widget.returnedFromIssuer,
  );

  @override
  void dispose() {
    _barTitleVisible.dispose();
    super.dispose();
  }

  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  @override
  Widget build(BuildContext context) {
    final isDocument =
        _cards.isNotEmpty &&
        _cards.every((c) => credentialRequiresNfc(c.credentialId));
    if (isDocument) {
      return DocumentIssuancePermission(
        issuedCredentials: _cards,
        returnedFromIssuer: widget.returnedFromIssuer,
        onDismiss: widget.onDismiss,
        onGivePermission: widget.onGivePermission,
      );
    }

    final many = _cards.length > 1;
    final title = many
        ? _t("issuance.question_many", {"count": "${_cards.length}"})
        : _t("issuance.description");
    final offer = _offer;

    // A phone held sideways: the card or pile at the left with its chips,
    // and the buttons under them; the question and the values at the right.
    if (!useSessionColumns(context) && useSheetColumns(context)) {
      return SessionScaffold(
        appBarTitle: "issuance.title",
        wide: true,
        scrollsUnderBars: true,
        cornerClose: true,
        onDismiss: widget.onDismiss,
        body: Builder(
          builder: (context) => IssuanceLandscape(
            title: title,
            overview: offer.overview(context, cardWidth: 220, withNote: false),
            note: offer.note(context),
            receives: offer.receives(context),
            actions: _landscapeActions(),
          ),
        ),
      );
    }

    // Tablets: the card or pile on the left, the values and buttons on the
    // right.
    if (useSessionColumns(context)) {
      return SessionScaffold(
        appBarTitle: "issuance.title",
        wide: true,
        scrollsUnderBars: true,
        barTitleVisibility: hiddenBarTitle,
        onDismiss: widget.onDismiss,
        body: SessionColumns(
          start: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              SessionColumnsTitle(title),
              ...offer.overview(context, cardWidth: 460),
            ],
          ),
          end: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: offer.receives(context),
            ),
          ),
          actions: _bar(),
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "issuance.title",
      scrollsUnderBars: true,
      barTitleVisibility: _barTitleVisible,
      bottomNavigationBar: _bar(),
      onDismiss: widget.onDismiss,
      body: LayoutBuilder(
        builder: (context, constraints) => LargeTitleScrollView(
          key: const Key("issuance_scroll_view"),
          title: title,
          barTitleVisible: _barTitleVisible,
          padding: BarInsets.of(
            context,
            const EdgeInsets.fromLTRB(16, 16, 16, 24),
          ),
          spacing: 16,
          children: [
            ...offer.overview(
              context,
              cardWidth: (constraints.maxWidth - 32).clamp(0.0, 460.0),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: offer.receives(context),
            ),
          ],
        ),
      ),
    );
  }

  /// "Cancel" as text and the way on beside it, at the bottom of the panel.
  Widget _landscapeActions() {
    if (widget.onGivePermission == null) {
      return PillButton(
        label: _t("session.navigation_bar.back"),
        size: PillSize.regular,
        onPressed: () => widget.onDismiss?.call(),
      );
    }
    return Row(
      spacing: 10,
      children: [
        PillButton(
          key: const Key("bottom_bar_secondary"),
          label: _t("issuance.cancel"),
          style: PillStyle.text,
          size: PillSize.regular,
          expand: false,
          onPressed: () => widget.onDismiss?.call(),
        ),
        Expanded(
          child: FancyPillButton(
            key: const Key("bottom_bar_primary"),
            label: _cards.length > 1
                ? _t("issuance.add_many", {"count": "${_cards.length}"})
                : _t("issuance.add"),
            size: PillSize.regular,
            onPressed: () => widget.onGivePermission?.call(),
          ),
        ),
      ],
    );
  }

  Widget _bar() {
    if (widget.onGivePermission == null) {
      return IrmaBottomBar(
        primaryButtonLabel: _t("session.navigation_bar.back"),
        onPrimaryPressed: () => widget.onDismiss?.call(),
      );
    }
    return IrmaBottomBar(
      primaryButtonLabel: _cards.length > 1
          ? _t("issuance.add_many", {"count": "${_cards.length}"})
          : _t("issuance.add"),
      onPrimaryPressed: () => widget.onGivePermission?.call(),
      secondaryButtonLabel: _t("issuance.cancel"),
      onSecondaryPressed: () => widget.onDismiss?.call(),
    );
  }
}

/// What an issuer offers, for the screens that ask whether to add it: the
/// card or the pile with its chips and the mismatch note ([overview]), and
/// "You will receive" with every value ([receives]). The permission screen
/// lays them out full-screen (in two columns on a tablet); the Change sheet
/// shows them as the last step of adding a card for a request.
class IssuanceOffer {
  final List<schemaless.Credential> cards;

  /// The request waiting underneath this issuance, if any.
  final SessionState? forRequest;

  /// Name of the issuer whose website the user just came back from, if any.
  final String? returnedFromIssuer;

  /// The tinted "For {requestor} · step n of m" chip. Off in the Change
  /// sheet, which says who it is for above its pages; the "back from the
  /// website" chip stays.
  final bool showRequestChip;

  const IssuanceOffer({
    required this.cards,
    this.forRequest,
    this.returnedFromIssuer,
    this.showRequestChip = true,
  });

  List<schemaless.Credential> get _cards => cards;

  List<IssuanceStep> get _steps =>
      forRequest?.disclosurePlan?.issueDuringDisclosure?.steps ??
      const <IssuanceStep>[];

  static String t(
    BuildContext context,
    String key, [
    Map<String, String>? params,
  ]) => FlutterI18n.translate(context, key, translationParams: params);

  String? _returnedChip(BuildContext context) {
    final issuer = returnedFromIssuer;
    return issuer == null
        ? null
        : t(context, "issuance.returned_from", {"issuer": issuer});
  }

  /// The card (or the pile), its chips and the mismatch note.
  List<Widget> overview(
    BuildContext context, {
    required double cardWidth,
    bool withNote = true,
  }) {
    final steps = _steps;
    final many = _cards.length > 1;
    final issuers = _cards.map((c) => c.issuer.name).toSet();
    final first = _cards.firstOrNull;

    final chips = [
      InfoChip(
        label: issuers.length > 1
            ? t(context, "issuance.from_issuers", {
                "count": "${issuers.length}",
              })
            : t(context, "credential.issued_by", {
                "issuer": issuers.firstOrNull ?? "",
              }),
      ),
      if (many)
        InfoChip(
          label: t(context, "issuance.card_count", {
            "count": "${_cards.length}",
          }),
        ),
      if (!many && (first?.display?.svgTemplates.isNotEmpty ?? false))
        InfoChip(
          label: t(context, "credential_card.source.issuer_design"),
          tinted: true,
        ),
      if (showRequestChip ? _context(context, steps) : _returnedChip(context)
          case final label?)
        InfoChip(
          key: const Key("issuance_context"),
          label: label,
          tinted: true,
        ),
    ];

    return [
      if (many)
        CardPile(cards: _cards)
      else if (first != null)
        Center(
          child: CredentialCardArt(credential: first, width: cardWidth),
        ),
      InfoChipRow(chips: chips),
      if (withNote) ?note(context),
    ];
  }

  /// "{requestor} needs …; this card has …": inside a request, when an
  /// offered card won't do for it. Part of [overview] unless it is left out
  /// there (landscape shows it with the values).
  Widget? note(BuildContext context) {
    final text = _mismatchText(context, issuanceMismatches(_cards, _steps));
    return text == null
        ? null
        : _Note(key: const Key("issuance_mismatch"), text: text);
  }

  /// "For {requestor} · step n of m" inside a request, "Back from the
  /// website of {issuer}" after the user went there from the app.
  String? _context(BuildContext context, List<IssuanceStep> steps) {
    final request = forRequest;
    if (request != null) {
      final step = stepNumberFor(_cards, steps);
      final requestor = request.requestor.name;
      return step == null
          ? t(context, "issuance.for_request", {"requestor": requestor})
          : t(context, "issuance.for_request_step", {
              "requestor": requestor,
              "step": "$step",
              "total": "${steps.length}",
            });
    }
    final issuer = returnedFromIssuer;
    return issuer == null
        ? null
        : t(context, "issuance.returned_from", {"issuer": issuer});
  }

  String? _mismatchText(
    BuildContext context,
    List<IssuanceMismatch> mismatches,
  ) {
    final miss = mismatches.firstOrNull;
    final request = forRequest;
    if (miss == null || request == null) return null;
    final offered = localizedAttributeText(context, miss.offered);
    return t(
      context,
      offered == null ? "issuance.mismatch_none" : "issuance.mismatch",
      {
        "requestor": request.requestor.name,
        "attribute": miss.attributeName,
        "value": localizedAttributeText(context, miss.required) ?? "",
        "offered": ?offered,
      },
    );
  }

  String? _validUntil(BuildContext context, schemaless.Credential card) {
    final expiry = card.expiryDate ?? 0;
    if (expiry <= 0) return null;
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? "en";
    return t(context, "wallet.detail.valid_until", {
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
  List<Widget> receives(
    BuildContext context, {
    String headingKey = "issuance.you_will_receive",
  }) {
    final mismatches = issuanceMismatches(_cards, _steps);
    final palette = YiviPalette.of(context);
    final many = _cards.length > 1;

    Set<String> mismatchedIn(schemaless.Credential card) => {
      for (final m in mismatches)
        if (m.credentialId == card.credentialId) claimPathKey(m.claimPath),
    };

    Widget values(schemaless.Credential card) =>
        YiviCredentialCardAttributeList(
          card.attributes,
          credentialId: card.credentialId,
          showDividers: true,
          mismatched: mismatchedIn(card),
        );

    final heading = Text(t(context, headingKey), style: palette.display(16));

    return [
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
                        t(context, "issuance.all_together"),
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
      for (final (i, card) in _cards.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: _Group(
            key: Key("issuance_card_$i"),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupHeader(card: card, until: _validUntil(context, card)),
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

/// A white rounded group, as in the rest of the session screens.
class _Group extends StatelessWidget {
  final Widget child;

  const _Group({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x17000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A card's mini art, name and validity above its values.
class _GroupHeader extends StatelessWidget {
  final schemaless.Credential card;
  final String? until;

  const _GroupHeader({required this.card, required this.until});

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
          // Wraps rather than pushing the name off at a large text size.
          if (until != null)
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

class _Note extends StatelessWidget {
  final String text;

  const _Note({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: ShapeDecoration(
        color: palette.errorSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
        ),
      ),
      child: Text(
        text,
        style: palette
            .body(14, weight: FontWeight.w600)
            .copyWith(height: 20 / 14, color: palette.errorText),
      ),
    );
  }
}

/// An issuance permission on a phone held sideways: a panel at the left
/// with [overview] (the card or pile and its chips) in the middle of the
/// room above [actions]; the [title] question, the [note] and [receives] at
/// the right, scrolling.
class IssuanceLandscape extends StatelessWidget {
  /// Wide, from the left safe edge, its 16 of padding included (as the share
  /// screen's panel).
  static const double panelWidth = 324;

  final String title;
  final List<Widget> overview;
  final Widget? note;
  final List<Widget> receives;
  final Widget actions;

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
    // On a wide screen (a tablet, an unfolded phone) at most
    // [sidewaysMaxWidth], centred.
    return Padding(
      padding: EdgeInsets.only(left: insets.left, right: insets.right),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: sidewaysMaxWidth),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: panelWidth,
                child: Padding(
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
                      const SizedBox(height: 16),
                      actions,
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
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
                                .copyWith(
                                  height: 30 / 24,
                                  color: palette.heading,
                                ),
                          ),
                        ),
                      ),
                      if (note != null) ...[const SizedBox(height: 16), note!],
                      const SizedBox(height: 12),
                      ...receives,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
