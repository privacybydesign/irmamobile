import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/large_title_scroll_view.dart";
import "../../../widgets/signature_message.dart";
import "../models/disclosure_view_model.dart";
import "change_choice_sheet.dart";
import "empty_card_spot.dart";
import "session_columns.dart";
import "session_requestor_header.dart";
import "session_scaffold.dart";
import "shared_card_tile.dart";

/// The share screen: the question as a large title, who asks, one card per
/// requested item with only the values that are shared, optional data, the
/// message to sign or the card offered in return, and one button.
///
/// A required card that is not in the app yet is an empty spot: tapping it
/// adds the card in the Change sheet, and the new card flies into the spot.
///
/// The button is the consent: there is no confirmation dialog after it. It
/// is disabled with the reason above it while a selected card cannot be
/// shared, and closes the session when such a card cannot be renewed in Yivi.
///
/// Everything comes from [session] and the user's selection
/// ([sessionUserChoicesProvider]); the rules live in
/// `disclosure_view_model.dart`.
class DisclosureShareScreen extends ConsumerStatefulWidget {
  final SessionState session;

  /// The close button: asks whether to stop without sharing.
  final VoidCallback onDismiss;

  /// Ends the session without asking, for "Close" when a card cannot be
  /// renewed.
  final VoidCallback onClose;
  final ValueChanged<List<DisclosureDisconSelection>> onShare;

  const DisclosureShareScreen({
    super.key,
    required this.session,
    required this.onDismiss,
    required this.onClose,
    required this.onShare,
  });

  @override
  ConsumerState<DisclosureShareScreen> createState() =>
      _DisclosureShareScreenState();
}

class _DisclosureShareScreenState extends ConsumerState<DisclosureShareScreen> {
  final _barTitleVisible = ValueNotifier(false);

  /// Per pick-one, where a card added for it in the sheet lands.
  final _landingKeys = <int, GlobalKey>{};

  GlobalKey _landingKey(int i) =>
      _landingKeys[i] ??= GlobalKey(debugLabel: "share_landing_$i");

  int get _sessionId => widget.session.id;

  List<DisclosurePickOne> get _pickOnes =>
      widget.session.disclosurePlan?.disclosureChoicesOverview ?? const [];

  @override
  void dispose() {
    _barTitleVisible.dispose();
    super.dispose();
  }

  /// "Change", or "Add" on optional data: the choice sheet for pick-one
  /// [i]. With [addNew] it opens on adding that type (the fix of a card that
  /// cannot be shared).
  void _openChoice(int i, {CredentialDescriptor? addNew}) =>
      showChangeChoiceSheet(
        context: context,
        sessionId: _sessionId,
        index: i,
        addNew: addNew,
        landingKey: _landingKey(i),
      );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final session = widget.session;
    final requestor = session.requestor.name;
    final choices = ref.watch(sessionUserChoicesProvider(_sessionId));
    final pickOnes = _pickOnes;
    final selections = selectionsFrom(
      pickOnes,
      choices.disclosureChoices,
      choices.addedOptionalIndices,
    );
    final button = shareButton(session, selections);
    final offered = session.offeredCredentials ?? const [];
    final isSignature = session.type == SessionType.signature;
    final kind = isSignature
        ? "sign"
        : offered.isNotEmpty
        ? "share_receive"
        : "share";
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);

    final required = [
      for (final (i, p) in pickOnes.indexed)
        if (!p.optional) _requiredTile(i, p, selections),
    ];
    final optional = [
      for (final (i, p) in pickOnes.indexed)
        if (p.optional) _optionalItem(i, p, selections),
    ];
    final anyShared = selections.values.any((k) => k >= 0);

    final requestorPart = <Widget>[
      SessionRequestorHeader(requestor: session.requestor),
      if (isSignature && session.messageToSign != null)
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                t("share.message_label"),
                style: palette
                    .body(13, weight: FontWeight.w700)
                    .copyWith(color: palette.secondaryText),
              ),
              SignatureMessage(message: session.messageToSign!),
            ],
          ),
        ),
    ];

    final requestedPart = <Widget>[
      if (required.isNotEmpty) ...[
        _SectionLabel(
          title: t(
            isSignature
                ? "share.section.with_signature"
                : "share.section.you_share",
          ),
        ),
        ...required,
      ],
      if (optional.isNotEmpty) ...[
        _SectionLabel(
          title: t("share.section.optional"),
          aside: required.isEmpty
              ? t("share.section.nothing_required")
              : t("share.section.you_choose"),
        ),
        if (required.isEmpty)
          Text(
            t("share.section.nothing_required_text", {"requestor": requestor}),
            textAlign: TextAlign.center,
            style: palette.body(13.5).copyWith(color: palette.secondaryText),
          ),
        ...optional,
      ],
      if (offered.isNotEmpty) ...[
        _SectionLabel(
          title: t("share.section.you_receive"),
          aside: t("share.section.from", {"issuer": requestor}),
        ),
        for (final card in offered) _OfferedCard(card: card),
      ],
    ];
    final footnote = _Footnote(
      text: anyShared
          ? t("share.footnote", {"requestor": requestor})
          : t("share.footnote_none"),
    );

    final bar = _ShareBar(
      reason: switch (button) {
        ShareButtonState(cannotAdd: final p?) =>
          _issuersOf(p).isEmpty
              ? t("share.reason.cant_add_unknown", {
                  "name": _inSentence(_spotName(p)),
                })
              : t("share.reason.cant_add", {
                  "name": _inSentence(_spotName(p)),
                  "issuer": _issuersOf(p),
                }),
        ShareButtonState(missing: final p?) => t("share.reason.missing", {
          "name": _inSentence(_spotName(p)),
        }),
        ShareButtonState(cannotRenewFrom: final issuer?) => t(
          "share.reason.cant_renew",
          {"requestor": requestor, "issuer": issuer},
        ),
        ShareButtonState(blockedBy: final p?) => t(
          "share.reason.${_problemName(p)}",
        ),
        _ => null,
      },
      label: t("share.button.${_labelName(button.label)}"),
      primary: button.label != ShareLabel.close,
      onPressed: !button.enabled
          ? null
          : button.label == ShareLabel.close
          ? widget.onClose
          : () => widget.onShare(disclosureChoicesFor(pickOnes, selections)),
    );

    // Tablets: the question, who asks and what it means on the left; what
    // is shared and the button on the right.
    if (useSessionColumns(context)) {
      return SessionScaffold(
        appBarTitle: "share.bar.$kind",
        onDismiss: widget.onDismiss,
        wide: true,
        scrollsUnderBars: true,
        barTitleVisibility: hiddenBarTitle,
        body: SessionColumns(
          startWidth: 400,
          endWidth: 520,
          gap: 56,
          start: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              SessionColumnsTitle(t("share.title.$kind")),
              ...requestorPart,
              footnote,
            ],
          ),
          end: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: requestedPart,
          ),
          actions: bar,
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "share.bar.$kind",
      onDismiss: widget.onDismiss,
      scrollsUnderBars: true,
      barTitleVisibility: _barTitleVisible,
      bottomNavigationBar: bar,
      body: Builder(
        builder: (context) => LargeTitleScrollView(
          key: const Key("share_scroll_view"),
          title: t("share.title.$kind"),
          barTitleVisible: _barTitleVisible,
          padding: BarInsets.of(
            context,
            const EdgeInsets.fromLTRB(16, 16, 16, 24),
          ),
          spacing: 12,
          children: [...requestorPart, ...requestedPart, footnote],
        ),
      ),
    );
  }

  String _spotName(DisclosurePickOne p) => spotName(
    p,
    FlutterI18n.translate(context, "share.or"),
    together: spotTogether(
      p,
      widget.session.disclosurePlan?.issueDuringDisclosure,
    ),
  );

  String _inSentence(String name) => inSentence(
    name,
    language: FlutterI18n.currentLocale(context)?.languageCode,
  );

  static String _issuersOf(DisclosurePickOne p) => {
    for (final d in p.obtainableOptions ?? const <CredentialDescriptor>[])
      if (d.issuer.name.isNotEmpty) d.issuer.name,
  }.join(", ");

  Widget _requiredTile(int i, DisclosurePickOne p, Map<int, int> selections) {
    final tile = _requiredContent(i, p, selections);
    if (!useSessionColumns(context)) return tile;
    // On a tablet the Change sheet is a dialog and nothing flies: the card
    // that was added fades into its spot.
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey((i, selectionOf(p, selections[i]) < 0)),
        child: tile,
      ),
    );
  }

  Widget _requiredContent(
    int i,
    DisclosurePickOne p,
    Map<int, int> selections,
  ) {
    final k = selectionOf(p, selections[i]);
    if (k < 0) return _emptySpot(i, p);
    final bundle = p.ownedOptions![k];
    final tile = _filledTile(i, p, bundle);
    if (!addedDuringRequest(
      p,
      bundle,
      widget.session.disclosurePlan?.issueDuringDisclosure,
    )) {
      return tile;
    }
    final palette = YiviPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        tile,
        _Note(
          key: Key("share_added_$i"),
          text: FlutterI18n.translate(
            context,
            "share.added_selected",
            translationParams: {
              "name": bundle.credentials.map((c) => c.name).join(" + "),
            },
          ),
          icon: Icons.check_rounded,
          background: palette.successSurface,
          foreground: palette.successText,
        ),
      ],
    );
  }

  /// A required card that is not in the app yet. With one way to get it,
  /// tapping goes straight to adding it; with more, to the choice first.
  Widget _emptySpot(int i, DisclosurePickOne p) {
    String t(String key, [Map<String, String>? params]) =>
        FlutterI18n.translate(context, key, translationParams: params);
    final addable = addableOptions(p);
    final plan = widget.session.disclosurePlan?.issueDuringDisclosure;
    final mismatch = spotMismatch(p, plan);
    final together = spotTogether(p, plan);
    final issuers = _issuersOf(p);
    final subtitle = addable.isEmpty
        ? issuers.isEmpty
              ? t("share.spot.cant_unknown")
              : t("share.spot.cant", {"issuer": issuers})
        : together
        ? t("share.spot.together")
        : addable.length == 1
        ? t("share.spot.one", {"issuer": addable.single.issuer.name})
        : t("share.spot.many");
    // With one card to add, its rows show what the request asks for, as the
    // card will once it is there.
    final single = addable.length == 1 && !together ? addable.single : null;
    final rows = single == null
        ? const <(String, String)>[]
        : emptySpotRows(context, single);
    return EmptyCardSpot(
      key: Key("share_spot_$i"),
      rows: rows,
      // Where the added card flies to; on a tablet it fades in instead, and
      // the spot fading out must not hold the key the card then has.
      landingKey: useSessionColumns(context) ? null : _landingKey(i),
      title: spotName(p, t("share.or"), together: together),
      subtitle: subtitle,
      // Without rows the values it must have go below the name.
      requirements: [
        if (rows.isEmpty)
          for (final (field, value) in spotRequiredValues(p))
            t("share.spot.must_be", {
              "field": field,
              "value": localizedAttributeText(context, value) ?? "",
            }),
      ],
      wrong: mismatch == null
          ? null
          : t("share.spot.wrong", {
              "offered":
                  localizedAttributeText(context, mismatch.offered) ?? "–",
              "needed":
                  localizedAttributeText(context, mismatch.required) ?? "",
            }),
      onTap: addable.isEmpty
          ? null
          : () => _openChoice(
              i,
              addNew: addable.length == 1 && !together ? addable.single : null,
            ),
    );
  }

  Widget _filledTile(int i, DisclosurePickOne p, DisclosureBundle bundle) {
    final fix = problemOfBundle(bundle) == null ? null : fixFor(p, bundle);
    final tile = SharedCardTile(
      key: Key("share_slot_$i"),
      bundle: bundle,
      landingKey: _landingKey(i),
      trailing: canChange(p)
          ? _ChangePill(
              key: Key("share_change_$i"),
              onTap: () => _openChoice(i),
            )
          : null,
      fixLabel: fix == null
          ? null
          : FlutterI18n.translate(
              context,
              "share.add_new",
              translationParams: {
                "name": inSentence(
                  fix.name,
                  language: FlutterI18n.currentLocale(context)?.languageCode,
                ),
              },
            ),
      onFix: fix == null ? null : () => _openChoice(i, addNew: fix),
    );
    if (!canChange(p)) return tile;
    // Flies into the Change sheet, where the same card is the checked one.
    return Hero(
      tag: choiceHeroTag(_sessionId, i, bundle),
      flightShuttleBuilder: choiceHeroShuttle,
      // Also back into the overview when the sheet is dragged closed.
      transitionOnUserGestures: true,
      child: tile,
    );
  }

  Widget _optionalItem(int i, DisclosurePickOne p, Map<int, int> selections) {
    final k = selectionOf(p, selections[i]);
    if (k >= 0) {
      final bundle = p.ownedOptions![k];
      final name = bundle.credentials.map((c) => c.name).join(" + ");
      final tile = SharedCardTile(
        key: Key("share_slot_$i"),
        bundle: bundle,
        landingKey: _landingKey(i),
        trailing: _RemoveButton(
          key: Key("share_remove_$i"),
          label: FlutterI18n.translate(
            context,
            "share.leave_out",
            translationParams: {"name": name},
          ),
          onTap: () => ref
              .read(sessionUserChoicesProvider(_sessionId).notifier)
              .removeOptional(i),
        ),
      );
      // A card picked for it in the sheet flies into its place, as a
      // required card does.
      return Hero(
        tag: choiceHeroTag(_sessionId, i, bundle),
        flightShuttleBuilder: choiceHeroShuttle,
        transitionOnUserGestures: true,
        child: tile,
      );
    }
    final owned = p.ownedOptions ?? const [];
    final names = {
      for (final b in owned) b.credentials.map((c) => c.name).join(" + "),
      for (final d in addableOptions(p)) d.name,
    };
    return _AddRow(
      key: Key("share_add_optional_$i"),
      title: names.join(FlutterI18n.translate(context, "share.or")),
      subtitle: FlutterI18n.translate(
        context,
        owned.isNotEmpty ? "share.in_your_app" : "share.not_in_app_yet",
      ),
      onTap: () => _openChoice(i),
    );
  }

  static String _problemName(CardProblem p) => switch (p) {
    CardProblem.revoked => "revoked",
    CardProblem.usedUp => "used_up",
    CardProblem.expired => "expired",
  };

  static String _labelName(ShareLabel l) => switch (l) {
    ShareLabel.share => "share",
    ShareLabel.signAndShare => "sign_and_share",
    ShareLabel.shareAndAdd => "share_and_add",
    ShareLabel.shareWithoutData => "share_without_data",
    ShareLabel.close => "close",
  };
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? aside;

  const _SectionLabel({required this.title, this.aside});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: palette
                    .body(12.5, weight: FontWeight.w700)
                    .copyWith(letterSpacing: 0.6, color: palette.secondaryText),
              ),
            ),
          ),
          if (aside != null)
            Text(
              aside!,
              style: palette.body(12.5).copyWith(color: palette.secondaryText),
            ),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  final Widget child;

  const _Surface({required this.child});

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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: child,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _Note({
    super.key,
    required this.text,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ShapeDecoration(
          color: background,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        child: Row(
          spacing: 8,
          children: [
            Icon(icon, size: 16, color: foreground),
            Expanded(
              child: Text(
                text,
                style: palette
                    .body(13, weight: FontWeight.w600)
                    .copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  final VoidCallback onTap;

  const _ChangePill({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: palette.tint,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              FlutterI18n.translate(context, "share.change"),
              style: palette
                  .body(13, weight: FontWeight.w600)
                  .copyWith(color: palette.link),
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RemoveButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return IconButton(
      onPressed: onTap,
      tooltip: label,
      style: IconButton.styleFrom(
        backgroundColor: palette.background,
        minimumSize: const Size(36, 36),
      ),
      icon: Icon(Icons.close_rounded, size: 16, color: palette.heading),
    );
  }
}

/// An optional item that is not included: what can be added, and "Add".
class _AddRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: GlassSurface(
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(22)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            spacing: 12,
            children: [
              ExcludeSemantics(
                child: Container(
                  width: SharedCardTile.miniWidth,
                  height: SharedCardTile.miniWidth * 226 / 358,
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(9)),
                      side: BorderSide(color: palette.outline, width: 1.5),
                    ),
                  ),
                  child: Icon(Icons.add_rounded, size: 18, color: palette.link),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: palette
                          .body(15, weight: FontWeight.w600)
                          .copyWith(color: palette.text),
                    ),
                    Text(
                      subtitle,
                      style: palette
                          .body(12.5)
                          .copyWith(color: palette.secondaryText),
                    ),
                  ],
                ),
              ),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  color: palette.tint,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  FlutterI18n.translate(context, "share.add"),
                  style: palette
                      .body(13, weight: FontWeight.w600)
                      .copyWith(color: palette.link),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card the requestor gives in return (an issuance with disclosure).
class _OfferedCard extends StatelessWidget {
  final schemaless.Credential card;

  const _OfferedCard({required this.card});

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            CredentialCardArt(credential: card, width: constraints.maxWidth),
            YiviCredentialCardAttributeList(
              card.attributes,
              credentialId: card.credentialId,
              showDividers: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  final String text;

  const _Footnote({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.shield_outlined,
              size: 16,
              color: palette.secondaryText,
            ),
          ),
          Expanded(
            child: Text(
              text,
              key: const Key("share_footnote"),
              style: palette
                  .body(13)
                  .copyWith(height: 19 / 13, color: palette.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}

/// The button at the bottom, with why it cannot be pressed above it.
class _ShareBar extends StatelessWidget {
  final String? reason;
  final String label;
  final bool primary;
  final VoidCallback? onPressed;

  const _ShareBar({
    required this.reason,
    required this.label,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    // Floats over the page with the same fade as the other bottom bars.
    return IrmaBottomBarBase(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (reason != null)
            Text(
              reason!,
              key: const Key("share_reason"),
              textAlign: TextAlign.center,
              style: palette
                  .body(13.5)
                  .copyWith(height: 19 / 13.5, color: palette.heading),
            ),
          KeyedSubtree(
            key: const Key("share_button"),
            child: primary
                ? FancyPillButton(label: label, onPressed: onPressed)
                : PillButton(label: label, onPressed: onPressed),
          ),
        ],
      ),
    );
  }
}
