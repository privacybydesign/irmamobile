import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/date_formatter.dart";
import "../../../util/nfc_credentials.dart";
import "../../../widgets/card_pile.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
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
    final steps =
        widget.forRequest?.disclosurePlan?.issueDuringDisclosure?.steps ??
        const <IssuanceStep>[];
    final mismatches = issuanceMismatches(_cards, steps);

    // Tablets: the card or pile on the left, the values and buttons on the
    // right.
    if (useSessionColumns(context)) {
      return SessionScaffold(
        appBarTitle: "issuance.title",
        wide: true,
        scrollsUnderBars: true,
        onDismiss: widget.onDismiss,
        body: SessionColumns(
          start: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              _title(title),
              ..._overview(context, steps, mismatches, cardWidth: 460),
            ],
          ),
          end: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _receives(context, mismatches),
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
            ..._overview(
              context,
              steps,
              mismatches,
              cardWidth: (constraints.maxWidth - 32).clamp(0.0, 460.0),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _receives(context, mismatches),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String title) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        header: true,
        child: Text(
          title,
          key: const Key("large_title"),
          style: palette
              .display(22)
              .copyWith(height: 30 / 22, color: palette.heading),
        ),
      ),
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

  /// The card (or the pile), its chips and the mismatch note.
  List<Widget> _overview(
    BuildContext context,
    List<IssuanceStep> steps,
    List<IssuanceMismatch> mismatches, {
    required double cardWidth,
  }) {
    final many = _cards.length > 1;
    final issuers = _cards.map((c) => c.issuer.name).toSet();
    final first = _cards.firstOrNull;
    final until = first == null || many ? null : _validUntil(first);

    final chips = [
      InfoChip(
        label: issuers.length > 1
            ? _t("issuance.from_issuers", {"count": "${issuers.length}"})
            : _t("credential.issued_by", {"issuer": issuers.firstOrNull ?? ""}),
      ),
      if (many)
        InfoChip(
          label: _t("issuance.card_count", {"count": "${_cards.length}"}),
        ),
      if (until != null) InfoChip(label: until),
      if (!many && (first?.display?.svgTemplates.isNotEmpty ?? false))
        InfoChip(
          label: _t("credential_card.source.issuer_design"),
          tinted: true,
        ),
      if (_context(steps) case final label?)
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
      if (_mismatchText(mismatches) case final text?)
        _Note(key: const Key("issuance_mismatch"), text: text),
    ];
  }

  /// "For {requestor} · step n of m" inside a request, "Back from the
  /// website of {issuer}" after the user went there from the app.
  String? _context(List<IssuanceStep> steps) {
    final request = widget.forRequest;
    if (request != null) {
      final step = stepNumberFor(_cards, steps);
      final requestor = request.requestor.name;
      return step == null
          ? _t("issuance.for_request", {"requestor": requestor})
          : _t("issuance.for_request_step", {
              "requestor": requestor,
              "step": "$step",
              "total": "${steps.length}",
            });
    }
    final issuer = widget.returnedFromIssuer;
    return issuer == null
        ? null
        : _t("issuance.returned_from", {"issuer": issuer});
  }

  String? _mismatchText(List<IssuanceMismatch> mismatches) {
    final miss = mismatches.firstOrNull;
    final request = widget.forRequest;
    if (miss == null || request == null) return null;
    final offered = attributeText(miss.offered);
    return _t(
      offered == null ? "issuance.mismatch_none" : "issuance.mismatch",
      {
        "requestor": request.requestor.name,
        "attribute": miss.attributeName,
        "value": attributeText(miss.required) ?? "",
        "offered": ?offered,
      },
    );
  }

  String? _validUntil(schemaless.Credential card) {
    final expiry = card.expiryDate ?? 0;
    if (expiry <= 0) return null;
    final lang = FlutterI18n.currentLocale(context)?.languageCode ?? "en";
    return _t("wallet.detail.valid_until", {
      "date": printableDate(
        DateTime.fromMillisecondsSinceEpoch(expiry * 1000),
        lang,
      ),
    });
  }

  /// "You will receive" and every value: one list for one card, a group
  /// per card for several.
  List<Widget> _receives(
    BuildContext context,
    List<IssuanceMismatch> mismatches,
  ) {
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

    final heading = Text(
      _t("issuance.you_will_receive"),
      style: palette.display(16),
    );

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
                        _t("issuance.all_together"),
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
      if (!many)
        for (final card in _cards)
          _Group(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: values(card),
            ),
          )
      else
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
                    _GroupHeader(card: card, until: _validUntil(card)),
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
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
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
          if (until != null)
            Text(
              until!,
              style: palette.body(12).copyWith(color: palette.secondaryText),
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
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
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
