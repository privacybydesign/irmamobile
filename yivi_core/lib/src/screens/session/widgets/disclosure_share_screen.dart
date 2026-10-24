import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/caps_label.dart";
import "../../../widgets/centred_max_width.dart";
import "../../../widgets/compact_bar.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/fill_scroll_view.dart";
import "../../../widgets/glass/floating_bar_placement.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/signature_message.dart";
import "../../../widgets/surface_card.dart";
import "../models/disclosure_view_model.dart";
import "../models/technical_details.dart";
import "change_choice_sheet.dart";
import "empty_card_spot.dart";
import "requestor_trust_sheet.dart";
import "session_columns.dart";
import "session_requestor_header.dart";
import "session_scaffold.dart";
import "shared_card_tile.dart";

/// The share screen: who asks, as the subject of the page ("Webshop Noord
/// is asking for your data"), one card per requested item with only the
/// values that are shared, optional data, the message to sign or the card
/// offered in return, and one button.
///
/// - A card with other choices has a strip at its foot: "You can also
///   choose …" with "Change choice", which opens the Change sheet.
/// - A required card that is not in the app yet is an empty spot: Add
///   opens the Change sheet on adding it, and the new card flies into the
///   spot. With several types to choose from, the spot shows them as small
///   cards, and the choice is made in the sheet.
/// - Optional data that is not shared is its card, faded in a dashed edge,
///   with "Share too" on that edge; once shared it has "Don't share".
/// - The footnote and Technical details sit at the bottom of the page, also
///   when it does not scroll.
/// - Once the requestor card has scrolled under the bar, a glass pill in the
///   bar says who asks, as on the detail pages.
///
/// The button is the consent: there is no confirmation dialog after it,
/// except for a party nobody vouches for. It is disabled with the reason
/// above it while a card is missing or cannot be shared, and closes the
/// session when such a card cannot be added or renewed in Yivi.
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
  /// The requestor card, and whether it has scrolled under the bar (the
  /// glass pill in the bar then says who asks).
  final _headerKey = GlobalKey(debugLabel: "share_requestor_card");
  final _scrolledPast = ValueNotifier(false);

  /// How far the page is scrolled: the list lets go of the card once it is
  /// far out of view, and then this says it has passed.
  double _scrolled = 0;

  /// Per pick-one, where a card added for it in the sheet lands.
  final _landingKeys = <int, GlobalKey>{};

  GlobalKey _landingKey(int i) =>
      _landingKeys[i] ??= GlobalKey(debugLabel: "share_landing_$i");

  int get _sessionId => widget.session.id;

  List<DisclosurePickOne> get _pickOnes =>
      widget.session.disclosurePlan?.disclosureChoicesOverview ?? const [];

  @override
  void dispose() {
    _scrolledPast.dispose();
    super.dispose();
  }

  /// Whether the bottom of the requestor card is under the bar.
  void _checkHeader() {
    if (!mounted) return;
    _scrolledPast.value = headerUnderBar(context, _headerKey) ?? _scrolled > 0;
  }

  /// "Change choice", "Add" on a spot, and the fix of a card that cannot be
  /// shared: the choice sheet for pick-one [i]. With [addNew] it opens on
  /// adding that type.
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
    final t = context.tr;
    final columns = useSessionColumns(context);
    final landscape = !columns && useSheetColumns(context);
    // The header can change size (rotation, text size): check again after
    // this layout.
    if (!columns && !landscape) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkHeader());
    }

    final required = [
      for (final (i, p) in pickOnes.indexed)
        if (!p.optional) (i, p),
    ];
    final optional = [
      for (final (i, p) in pickOnes.indexed)
        if (p.optional) (i, p),
    ];
    final trust = requestorTrustOf(session.requestor);
    // Who is asking, and at its foot, as a subpage, the technical details
    // of the request: for the curious, well out of the way.
    void openTrust() => showRequestorTrustSheet(
      context: context,
      requestor: session.requestor,
      onDontShare: widget.onClose,
      technicalDetails: technicalDetailsOf(
        session,
        _sharedCredentials(pickOnes, selections),
        t,
      ),
    );

    final ask = t("share.ask.$kind");
    final lead = required.isEmpty && optional.isNotEmpty
        ? t("share.section.nothing_required_text", {"requestor": requestor})
        : t(switch (kind) {
            "sign" => "share.lead_sign",
            "share_receive" => "share.lead_receive",
            _ => "share.lead",
          });

    final message = isSignature && session.messageToSign != null
        ? SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
          )
        : null;

    final requestorPart = <_Spaced>[
      _Spaced(
        0,
        KeyedSubtree(
          key: _headerKey,
          child: RequestorCard(
            requestor: session.requestor,
            ask: ask,
            onInfo: openTrust,
          ),
        ),
      ),
      _Spaced(
        12,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            lead,
            key: const Key("share_lead"),
            style: palette
                .body(15)
                .copyWith(height: 22 / 15, color: palette.secondaryText),
          ),
        ),
      ),
      if (message != null) _Spaced(14, message),
    ];

    final requestedPart = <_Spaced>[
      if (required.isNotEmpty) ...[
        _Spaced(
          24,
          _SectionLabel(
            isSignature
                ? t("share.section.with_signature")
                : t("share.section.you_share"),
          ),
        ),
        for (final (n, (i, p)) in required.indexed)
          _requiredItem(i, p, selections, first: n == 0),
      ],
      if (optional.isNotEmpty) ...[
        _Spaced(24, _SectionLabel(t("share.section.optional"))),
        for (final (n, (i, p)) in optional.indexed)
          _optionalItem(i, p, selections, first: n == 0),
      ],
      if (offered.isNotEmpty) ...[
        _Spaced(24, _SectionLabel(t("share.section.you_receive"))),
        for (final card in offered) _Spaced(12, _OfferedCard(card: card)),
      ],
    ];

    // Only when the button shares something: not while a card is missing,
    // and not when nothing is shared.
    final footnote = showFootnote(button, selections)
        ? _Footnote(text: t("share.footnote", {"requestor": requestor}))
        : null;
    final pageEnd = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [?footnote],
    );

    // Nobody vouches for the requestor: Share becomes "Share anyway", asks
    // once more, and says above it to share only if you trust them.
    final risky =
        trust.risky &&
        button.enabled &&
        button.label != ShareLabel.close &&
        button.label != ShareLabel.shareWithoutData;
    void share() => widget.onShare(disclosureChoicesFor(pickOnes, selections));
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
        ShareButtonState(blockedCard: final b?) => t("share.reason.renew", {
          "name": _inSentence(_bundleName(b)),
        }),
        _ when risky => t("share.trust.risky.reason", {"requestor": requestor}),
        _ => null,
      },
      label: risky
          ? t(
              button.label == ShareLabel.signAndShare
                  ? "share.trust.risky.sign_anyway"
                  : "share.trust.risky.share_anyway",
            )
          : t("share.button.${_labelName(button.label)}", {
              "requestor": requestor,
            }),
      primary: button.label != ShareLabel.close && !risky,
      risky: risky,
      onPressed: !button.enabled
          ? null
          : button.label == ShareLabel.close
          ? widget.onClose
          : risky
          ? () async {
              if (await _confirmShareAnyway(requestor)) share();
            }
          : share,
    );

    // A phone held sideways: who asks, what it means and the button in a
    // panel at the left that stays put; what is shared scrolls at the right.
    if (landscape) {
      // The panel's card starts level with the first card at the right: both
      // have the first section label's room above them (in the panel an
      // invisible copy, so the text size can't move them apart).
      final firstLabel = required.isNotEmpty
          ? (isSignature
                ? t("share.section.with_signature")
                : t("share.section.you_share"))
          : optional.isNotEmpty
          ? t("share.section.optional")
          : offered.isNotEmpty
          ? t("share.section.you_receive")
          : null;
      final column = <_Spaced>[
        if (message != null) ...[
          _Spaced(24, _SectionLabel.room(firstLabel ?? "")),
          _Spaced(12, message),
        ],
        ...requestedPart,
      ];
      // Held sideways one sentence in the panel says both what they get
      // and that nothing else leaves the phone: no footnote under the list.
      final combined = !(required.isEmpty && optional.isNotEmpty);
      final sideLead = !combined
          ? lead
          : t(
              switch (kind) {
                "sign" => "share.lead_side_sign",
                "share_receive" => "share.lead_side_receive",
                _ => "share.lead_side",
              },
              {"requestor": requestor},
            );
      return SessionScaffold(
        appBarTitle: "share.bar.$kind",
        onDismiss: widget.onDismiss,
        wide: true,
        scrollsUnderBars: true,
        // No band under the bar: only its buttons float over the content.
        scrollEdge: false,
        cornerClose: true,
        body: _TrustWash(
          on: trust.risky,
          child: Builder(
            builder: (context) {
              final media = MediaQuery.paddingOf(context);
              // The bar holds only the close button, in the corner beside
              // the column: the content starts at the top of the screen.
              final top = cornerContentTop(context);
              return SidewaysLayout(
                panel: _LandscapePanel(
                  top: top,
                  label: firstLabel,
                  card: RequestorCard.compact(
                    requestor: session.requestor,
                    ask: ask,
                    onInfo: openTrust,
                  ),
                  lead: sideLead,
                  action: bar.inline(),
                ),
                content: FillScrollView(
                  scrollKey: const Key("share_scroll_view"),
                  padding: EdgeInsets.fromLTRB(0, top, 16, 16 + media.bottom),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _laidOut(column),
                      ),
                      if (!combined)
                        Padding(
                          padding: const EdgeInsets.only(top: 28),
                          child: pageEnd,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Tablets: who asks and what it means on the left, with the footnote
    // and the details at its foot; what is shared and the button on the
    // right.
    if (columns) {
      return SessionScaffold(
        appBarTitle: "share.bar.$kind",
        onDismiss: widget.onDismiss,
        wide: true,
        scrollsUnderBars: true,
        // No band under the bar: only its buttons float over the content.
        scrollEdge: false,
        body: _TrustWash(
          on: trust.risky,
          child: SessionColumns(
            startWidth: 400,
            endWidth: 520,
            gap: 56,
            start: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._laidOut(requestorPart),
                const SizedBox(height: 28),
                pageEnd,
              ],
            ),
            end: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _laidOut(requestedPart, first: true),
            ),
            actions: bar,
          ),
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "share.bar.$kind",
      onDismiss: widget.onDismiss,
      scrollsUnderBars: true,
      // No band under the bar: only its buttons float over the content.
      scrollEdge: false,
      bottomNavigationBar: bar,
      startBar: _CompactBarSlot(
        shown: _scrolledPast,
        requestor: session.requestor,
        subtitle: ask,
      ),
      body: _TrustWash(
        on: trust.risky,
        child: Builder(
          builder: (context) {
            final insets = BarInsets.of(context);
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                _scrolled = n.metrics.pixels;
                _checkHeader();
                return false;
              },
              child: FillScrollView(
                scrollKey: const Key("share_scroll_view"),
                padding: EdgeInsets.fromLTRB(
                  16 + insets.left,
                  16 + insets.top,
                  16 + insets.right,
                  16 + insets.bottom,
                ),
                // At least the screen high, so the footnote and the details
                // sit at its bottom also when the page is short.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _laidOut([...requestorPart, ...requestedPart]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: pageEnd,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// [items] with their gaps above them; the first item's gap is dropped
  /// when [first].
  static List<Widget> _laidOut(List<_Spaced> items, {bool first = false}) => [
    for (final (n, item) in items.indexed) ...[
      if (!(first && n == 0) && item.gap > 0) SizedBox(height: item.gap),
      item.child,
    ],
  ];

  /// The cards that would be shared with the current selection.
  static List<SelectableCredentialInstance> _sharedCredentials(
    List<DisclosurePickOne> pickOnes,
    Map<int, int> selections,
  ) => [
    for (final (i, p) in pickOnes.indexed)
      if (selectionOf(p, selections[i]) case final k when k >= 0)
        ...p.ownedOptions![k].credentials,
  ];

  /// "Share with a party Yivi doesn't know?": the safe answer is the big
  /// button.
  Future<bool> _confirmShareAnyway(String requestor) async {
    String t(String key) => FlutterI18n.translate(
      context,
      key,
      translationParams: {"requestor": requestor},
    );
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => GlassDialog(
            cardKey: const Key("share_anyway_dialog"),
            icon: const ToneDisc(
              icon: Icons.warning_rounded,
              tone: DialogTone.danger,
            ),
            title: t("share.trust.confirm.title"),
            message: t("share.trust.confirm.text"),
            actions: [
              FancyPillButton(
                key: const Key("share_anyway_cancel"),
                size: PillSize.regular,
                label: t("share.trust.confirm.dont_share"),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              PillButton(
                key: const Key("share_anyway_confirm"),
                label: t("share.trust.risky.share_anyway"),
                style: PillStyle.danger,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// "Passport, ID card or driving licence": the types of a spot, the ones
  /// after the first as they read inside the list.
  String _spotName(DisclosurePickOne p) => spotName(
    p,
    context.tr("share.or"),
    together: spotTogether(
      p,
      widget.session.disclosurePlan?.issueDuringDisclosure,
    ),
    inList: _inSentence,
  );

  static String _bundleName(DisclosureBundle b) =>
      b.credentials.map((c) => c.name).join(" + ");

  String _inSentence(String name) => inSentence(
    name,
    language: FlutterI18n.currentLocale(context)?.languageCode,
  );

  static String _issuersOf(DisclosurePickOne p) => {
    for (final d in p.obtainableOptions ?? const <CredentialDescriptor>[])
      if (d.issuer.name.isNotEmpty) d.issuer.name,
  }.join(", ");

  /// "You can also choose your other email address or a mobile number",
  /// with "Change choice": the strip at the foot of a card with other
  /// choices. Null when there are none.
  Widget? _choiceStrip(int i, DisclosurePickOne p, int selected) {
    if (!canChange(p)) return null;
    final items = alsoChoose(p, selected);
    if (items.isEmpty) return null;
    final list = orList([
      for (final (kind, name) in items)
        context.tr("share.also_${kind.name}", {"name": _inSentence(name)}),
    ], context.tr("share.or"));
    return _ChoiceStrip(
      text: context.tr("share.also", {"list": list}),
      button: SmallPill(
        key: Key("share_change_$i"),
        label: context.tr("share.change_choice"),
        tone: SmallPillTone.surface,
        onPressed: () => _openChoice(i),
      ),
    );
  }

  /// A required item: its card, or the empty spot when it is not in the app.
  _Spaced _requiredItem(
    int i,
    DisclosurePickOne p,
    Map<int, int> selections, {
    required bool first,
  }) {
    final k = selectionOf(p, selections[i]);
    final empty = k < 0;
    // Right under the section's label the spot's room above its dashed edge
    // (for the pill) is the gap; under a card it is 12 more, as between
    // cards, so the pill never touches the card above.
    final gap = empty && first ? 0.0 : 12.0;
    final child = empty ? _emptySpot(i, p) : _filledTile(i, p, k);
    if (!useSessionColumns(context)) return _Spaced(gap, child);
    // On a tablet the Change sheet is a dialog and nothing flies: the card
    // that was added fades into its spot. The switcher holds the spot as
    // well, so it is already there when the card comes; its key keeps it
    // when the gap above it comes or goes.
    return _Spaced(
      gap,
      AnimatedSwitcher(
        key: ValueKey(("share_required_item", i)),
        duration: YiviMotion.duration(
          context,
          const Duration(milliseconds: 300),
        ),
        child: KeyedSubtree(key: ValueKey((i, empty)), child: child),
      ),
    );
  }

  /// A card that is not in the app yet. With one way to get it, Add goes
  /// straight to adding it; with more, to the choice in the sheet, and the
  /// spot shows the types as small cards.
  Widget _emptySpot(int i, DisclosurePickOne p, {Key? key}) {
    final t = context.tr;
    final addable = addableOptions(p);
    final plan = widget.session.disclosurePlan?.issueDuringDisclosure;
    final mismatch = spotMismatch(p, plan);
    final together = spotTogether(p, plan);
    final issuers = _issuersOf(p);
    final single = addable.length == 1 && !together ? addable.single : null;
    final several = !together && addable.length > 1;
    // Cards only accepted together: which of the set are in the app already.
    final inApp = together
        ? ref.watch(cardTypesInAppProvider)
        : const <String>{};
    final missing = [
      for (final d in addable)
        if (!inApp.contains(d.credentialId)) d,
    ];
    final requestor = widget.session.requestor.name;
    final subtitle = addable.isEmpty
        ? issuers.isEmpty
              ? t("share.spot.cant_unknown")
              : t("share.spot.cant", {"issuer": issuers})
        : together
        ? (missing.length == 1 && addable.length == 2
              ? t("share.spot.together_one_left", {
                  "name": addable
                      .firstWhere((d) => inApp.contains(d.credentialId))
                      .name,
                  "other": _inSentence(missing.single.name),
                  "requestor": requestor,
                })
              : t("share.spot.together_both", {"requestor": requestor}))
        : single != null
        ? single.issuer.name
        : t("share.spot.many");
    // With one card to add, its rows show what the request asks for, as the
    // card will once it is there; a set shows the fields of each of its
    // cards, "In your app" for one that is there already.
    final rows = together
        ? [
            for (final d in addable)
              for (final (label, value) in emptySpotRows(context, d))
                (
                  label,
                  inApp.contains(d.credentialId)
                      ? t("data.add.in_your_app")
                      : value,
                ),
          ]
        : single == null
        ? const <(String, String)>[]
        : emptySpotRows(context, single);
    return EmptyCardSpot(
      key: key ?? Key("share_spot_$i"),
      rows: rows,
      // Where the added card flies to; on a tablet it fades in instead, and
      // the spot fading out must not hold the key the card then has.
      landingKey: useSessionColumns(context) ? null : _landingKey(i),
      title: _spotName(p),
      subtitle: subtitle,
      kinds: several || together ? addable : null,
      together: together,
      addLabel: together && missing.length > 1 ? t("share.add_both") : null,
      // Without rows the values it must have go below the name; with a
      // choice of types they are in the sheet.
      requirements: [
        if (rows.isEmpty && !several && !together)
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
      onTap: addable.isEmpty ? null : () => _openChoice(i, addNew: single),
    );
  }

  Widget _filledTile(int i, DisclosurePickOne p, int k) {
    final bundle = p.ownedOptions![k];
    final problem = problemOfBundle(bundle);
    final fix = problem == null ? null : fixFor(p, bundle);
    final isNew = addedDuringRequest(
      p,
      bundle,
      widget.session.disclosurePlan?.issueDuringDisclosure,
    );
    final tile = SharedCardTile(
      key: Key("share_slot_$i"),
      bundle: bundle,
      landingKey: _landingKey(i),
      isNew: isNew,
      problemStrip: true,
      fixLabel: fix == null ? null : context.tr("share.renew"),
      onFix: fix == null ? null : () => _openChoice(i, addNew: fix),
      footer: _choiceStrip(i, p, k) ?? _togetherStrip(bundle),
    );
    if (!canChange(p)) return tile;
    // Flies into the Change sheet, where the same card is the checked one.
    return ChoiceHero(
      sessionId: _sessionId,
      index: i,
      bundle: bundle,
      child: tile,
    );
  }

  /// "These go together": a set of cards that is only accepted as a whole.
  Widget? _togetherStrip(DisclosureBundle bundle) {
    if (bundle.credentials.length < 2) return null;
    final palette = YiviPalette.of(context);
    return CardTileStrip(
      key: const Key("share_together"),
      children: [
        ExcludeSemantics(
          child: Icon(Icons.link_rounded, size: 16, color: palette.link),
        ),
        Expanded(
          child: Text(
            context.tr("share.together", {
              "requestor": widget.session.requestor.name,
            }),
            style: palette
                .body(13.5)
                .copyWith(height: 19 / 13.5, color: palette.heading),
          ),
        ),
      ],
    );
  }

  /// Optional data. Not shared: its card faded in a dashed edge with "Share
  /// too" on it, which includes it at once. Shared: the card with "Don't
  /// share". Not in the app: an empty spot whose Add opens the sheet.
  _Spaced _optionalItem(
    int i,
    DisclosurePickOne p,
    Map<int, int> selections, {
    required bool first,
  }) {
    final notifier = ref.read(sessionUserChoicesProvider(_sessionId).notifier);
    final owned = p.ownedOptions ?? const <DisclosureBundle>[];
    final k = selectionOf(p, selections[i]);
    if (k >= 0) {
      final bundle = owned[k];
      final tile = SharedCardTile(
        key: Key("share_slot_$i"),
        bundle: bundle,
        landingKey: _landingKey(i),
        trailing: SmallPill(
          key: Key("share_remove_$i"),
          label: context.tr("share.dont_share"),
          onPressed: () => notifier.removeOptional(i),
        ),
        footer: _choiceStrip(i, p, k),
      );
      // A card picked for it in the sheet flies into its place, as a
      // required card does.
      return _Spaced(
        12,
        ChoiceHero(
          sessionId: _sessionId,
          index: i,
          bundle: bundle,
          child: tile,
        ),
      );
    }
    // As a required spot: 12 more under a card, for the pill.
    final gap = first ? 0.0 : 12.0;
    if (owned.isEmpty) {
      return _Spaced(gap, _emptySpot(i, p, key: Key("share_add_optional_$i")));
    }
    return _Spaced(
      gap,
      _OptionalGhost(
        key: Key("share_add_optional_$i"),
        bundle: owned.first,
        label: context.tr("share.also_share"),
        onAdd: () => notifier.addOptional(i),
      ),
    );
  }

  static String _labelName(ShareLabel l) => switch (l) {
    ShareLabel.share => "share",
    ShareLabel.signAndShare => "sign_and_share",
    ShareLabel.shareAndAdd => "share_and_add",
    ShareLabel.shareWithoutData => "share_without_data",
    ShareLabel.close => "close",
  };
}

/// A widget on the page with the gap above it.
class _Spaced {
  final double gap;
  final Widget child;

  const _Spaced(this.gap, this.child);
}

/// The glass pill in the bar once the requestor card has scrolled away: it
/// fades in and comes down 8 pt, as on the detail pages.
class _CompactBarSlot extends StatelessWidget {
  final ValueListenable<bool> shown;
  final schemaless.TrustedParty requestor;
  final String subtitle;

  const _CompactBarSlot({
    required this.shown,
    required this.requestor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return CompactBarDropIn(
      shown: shown,
      bar: (t) => RequestorCompactBar(
        requestor: requestor,
        subtitle: subtitle,
        opacity: t,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final bool shown;

  const _SectionLabel(this.title) : shown = true;

  /// The label's room only: it holds the place of a label at the other
  /// side, so what comes under both lines up.
  const _SectionLabel.room(this.title) : shown = false;

  @override
  Widget build(BuildContext context) {
    if (!shown) {
      return ExcludeSemantics(
        child: Visibility(
          visible: false,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: _SectionLabel(title),
        ),
      );
    }
    return CapsLabel(title, padding: const EdgeInsets.symmetric(horizontal: 6));
  }
}

/// The strip at the foot of a card with other choices.
class _ChoiceStrip extends StatelessWidget {
  final String text;
  final Widget button;

  const _ChoiceStrip({required this.text, required this.button});

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return CardTileStrip(
      children: [
        Expanded(
          child: Text(
            text,
            key: const Key("share_also"),
            style: palette
                .body(13.5)
                .copyWith(height: 19 / 13.5, color: palette.heading),
          ),
        ),
        button,
      ],
    );
  }
}

/// Optional data that is not shared: the card it would be, at half
/// strength in a dashed edge, with "Share too" on that edge. A tap anywhere
/// includes it.
class _OptionalGhost extends StatelessWidget {
  final DisclosureBundle bundle;
  final String label;
  final VoidCallback onAdd;

  const _OptionalGhost({
    super.key,
    required this.bundle,
    required this.label,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final gap = EmptyCardSpot.dashGapFor(context, label);
    return Semantics(
      button: true,
      label: "$label: ${bundle.credentials.map((c) => c.name).join(" + ")}",
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: EmptyCardSpot.edgeRoom),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onAdd,
          child: PressScale(
            scale: 0.98,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SharedCardTile(bundle: bundle, ghost: true, dashGap: gap),
                EdgeAddPill(
                  pillKey: const Key("share_also_share"),
                  label: label,
                  onPressed: onAdd,
                ),
              ],
            ),
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
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
    return CentredMaxWidth(
      maxWidth: 320,
      child: Text(
        text,
        key: const Key("share_footnote"),
        textAlign: TextAlign.center,
        style: palette
            .body(13.5)
            .copyWith(height: 19 / 13.5, color: palette.secondaryText),
      ),
    );
  }
}

/// The button at the bottom, with why it cannot be pressed above it.
class _ShareBar extends StatelessWidget {
  final String? reason;
  final String label;
  final bool primary;

  /// Nobody vouches for the requestor: a sober dark "Share anyway" with the
  /// reason in red above it, instead of the celebratory red button.
  final bool risky;
  final VoidCallback? onPressed;

  /// In a bar across the bottom; otherwise just the reason and the button
  /// (the landscape panel).
  final bool inBar;

  const _ShareBar({
    required this.reason,
    required this.label,
    required this.primary,
    this.risky = false,
    required this.onPressed,
    this.inBar = true,
  });

  /// The same reason and button, without the bar around them.
  _ShareBar inline() => _ShareBar(
    reason: reason,
    label: label,
    primary: primary,
    risky: risky,
    onPressed: onPressed,
    inBar: false,
  );

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        if (reason != null)
          Text(
            reason!,
            key: const Key("share_reason"),
            textAlign: TextAlign.center,
            style: risky
                ? palette
                      .body(13.5, weight: FontWeight.w600)
                      .copyWith(height: 19 / 13.5, color: palette.errorText)
                : palette
                      .body(13.5)
                      .copyWith(height: 19 / 13.5, color: palette.heading),
          ),
        KeyedSubtree(
          key: const Key("share_button"),
          child: risky
              ? PillButton(
                  label: label,
                  style: PillStyle.neutral,
                  size: PillSize.large,
                  onPressed: onPressed,
                )
              : primary
              ? FancyPillButton(label: label, onPressed: onPressed)
              : PillButton(
                  label: label,
                  size: PillSize.large,
                  onPressed: onPressed,
                ),
        ),
      ],
    );
    // Floats over the page: solid behind the reason and the button, with
    // the fade above it, so the reason never sits on a card.
    return inBar ? IrmaBottomBarBase(child: content) : content;
  }
}

/// The panel at the left on a phone held sideways: room for the first
/// section label (so the card lines up with the first card at the right),
/// who asks, what the page is, and at its bottom the reason and the button.
/// It scrolls only when it doesn't fit (a large text size).
class _LandscapePanel extends StatelessWidget {
  final double top;
  final String? label;
  final Widget card;
  final String lead;
  final Widget action;

  const _LandscapePanel({
    required this.top,
    required this.label,
    required this.card,
    required this.lead,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final bottom = FloatingBarPlacement.buttonBottom(context);
    return FillScrollView(
      scrollKey: const Key("share_panel"),
      padding: EdgeInsets.fromLTRB(16, top, 0, bottom),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (label != null) ...[
                const SizedBox(height: 24),
                _SectionLabel.room(label!),
                const SizedBox(height: 12),
              ],
              card,
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  lead,
                  key: const Key("share_lead"),
                  style: palette
                      .body(13.5)
                      .copyWith(
                        height: 19 / 13.5,
                        color: palette.secondaryText,
                      ),
                ),
              ),
            ],
          ),
          Padding(padding: const EdgeInsets.only(top: 16), child: action),
        ],
      ),
    );
  }
}

/// A red wash behind the top of the page when nobody vouches for the
/// requestor.
class _TrustWash extends StatelessWidget {
  final bool on;
  final Widget child;

  const _TrustWash({required this.on, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!on) return child;
    final palette = YiviPalette.of(context);
    return Stack(
      children: [
        Positioned(
          key: const Key("share_trust_wash"),
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
        Positioned.fill(child: child),
      ],
    );
  }
}
