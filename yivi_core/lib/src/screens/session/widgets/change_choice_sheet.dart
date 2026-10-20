import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../widgets/credential_card/card_flight.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../models/disclosure_view_model.dart";
import "empty_card_spot.dart";
import "issue_flow.dart";
import "issue_sheet_progress.dart";
import "shared_card_tile.dart";

export "issue_flow.dart" show issuerOpenerProvider;

/// The "Change" sheet of the share screen, for pick-one [index]: the cards
/// in the app (one tap picks one and closes the sheet) and, clearly apart,
/// the types that are not in the app yet.
///
/// Adding one of those happens in the sheet ([IssueFlow]): its details, then
/// proving it, then the issuance. "Back to {requestor}" then flies the new
/// card into its spot on the share screen ([landingKey]) as the sheet
/// closes.
///
/// [addNew] opens it straight on the details of that type, for the "Add a
/// new …" button of a card that cannot be shared.
Future<void> showChangeChoiceSheet({
  required BuildContext context,
  required int sessionId,
  required int index,
  CredentialDescriptor? addNew,
  GlobalKey? landingKey,
}) => showGlassSheet<void>(
  context: context,
  builder: (_) => ChangeChoiceSheet(
    key: const Key("disclosure_choice_sheet"),
    sessionId: sessionId,
    index: index,
    addNew: addNew,
    landingKey: landingKey,
  ),
);

/// The hero tag of [bundle] as the choice for pick-one [index]: the card on
/// the share screen and the same card in the sheet, so the chosen card flies
/// into the sheet and the picked one back.
Object choiceHeroTag(int sessionId, int index, DisclosureBundle bundle) => (
  "disclosure_choice",
  sessionId,
  index,
  bundle.credentials.map((c) => c.hash).join("+"),
);

/// A card flying between the share screen and the sheet: the destination
/// card without its "Change" pill or selection outline, which appear once it
/// has landed, on a transparent material so its text and ink have one.
///
/// The flight's box goes from the size of one card to the other; the card
/// keeps its own height in it, so two that differ a little (an
/// optional card has its leave-out button) do not overflow on the way.
Widget choiceHeroShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromContext,
  BuildContext toContext,
) => Material(
  type: MaterialType.transparency,
  child: OverflowBox(
    alignment: Alignment.topCenter,
    minHeight: 0,
    maxHeight: double.infinity,
    child: SharedCardTileInFlight(child: (toContext.widget as Hero).child),
  ),
);

class ChangeChoiceSheet extends ConsumerStatefulWidget {
  final int sessionId;
  final int index;
  final CredentialDescriptor? addNew;

  /// Where a card added in the sheet lands on the share screen.
  final GlobalKey? landingKey;

  const ChangeChoiceSheet({
    super.key,
    required this.sessionId,
    required this.index,
    this.addNew,
    this.landingKey,
  });

  @override
  ConsumerState<ChangeChoiceSheet> createState() => _ChangeChoiceSheetState();
}

class _ChangeChoiceSheetState extends ConsumerState<ChangeChoiceSheet>
    with IssueFlow<ChangeChoiceSheet> {
  @override
  void initState() {
    super.initState();
    issueStartWith(widget.addNew);
  }

  @override
  int get underlyingSessionId => widget.sessionId;

  @override
  SessionState? get issueRequest =>
      ref.read(sessionStateProvider(widget.sessionId)).value;

  schemaless.TrustedParty? get _requestor => issueRequest?.requestor;

  @override
  IssueSheetSubject issueSubject(CredentialDescriptor d) =>
      IssueSheetSubject.request(_requestor ?? d.issuer);

  @override
  String issueStopText() =>
      _t("share.sheet.stop_text", {"requestor": _requestor?.name ?? ""});

  @override
  void beforeIssueAdd(CredentialDescriptor d) {
    final pickOnes =
        issueRequest?.disclosurePlan?.disclosureChoicesOverview ?? const [];
    if (widget.index < pickOnes.length && pickOnes[widget.index].optional) {
      _choices.includeOptionalWhenAdded(widget.index);
    }
  }

  Map<String, String> _successParams(List<schemaless.Credential> cards) => {
    "name": cards.firstOrNull?.name ?? "",
    "count": "${cards.length}",
    "requestor": _requestor?.name ?? "",
  };

  @override
  Widget issueSuccessBar(List<schemaless.Credential> cards) => SheetActionRow(
    primaryKey: const Key("sheet_back_to_request"),
    primaryLabel: _t(
      "issuance.success_feedback.back_to",
      _successParams(cards),
    ),
    onPrimary: _finish,
  );

  @override
  String issueSuccessText(List<schemaless.Credential> cards) => _t(
    cards.length > 1
        ? "issuance.success_feedback.added_many_back"
        : "issuance.success_feedback.added_one_back",
    _successParams(cards),
  );

  SessionUserChoicesNotifier get _choices =>
      ref.read(sessionUserChoicesProvider(widget.sessionId).notifier);

  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  String _inSentence(String name) => inSentence(
    name,
    language: FlutterI18n.currentLocale(context)?.languageCode,
  );

  void _pick(DisclosurePickOne pickOne, DisclosureBundle bundle) {
    if (pickOne.optional) _choices.addOptional(widget.index);
    _choices.setBundle(widget.index, bundle);
    Navigator.of(context).pop();
  }

  /// "Back to {requestor}": the new card flies into its spot as the sheet
  /// closes. Without a spot to fly to, or for a card of another type than
  /// the one being added (an issuance that happened to come in meanwhile),
  /// the sheet just closes. On a tablet, where the sheet is a dialog over
  /// the page, the card fades into its spot instead (the share screen).
  void _finish() {
    final cards = issueAdded ?? const <schemaless.Credential>[];
    final landing = widget.landingKey;
    final i = cards.indexWhere(
      (c) => c.credentialId == issueAdding?.credentialId,
    );
    if (landing != null && i >= 0 && !isExpandedLayout(context)) {
      CardFlight.start(
        context,
        source: issueAddedKeys[i],
        card: cards[i],
        landingKey: landing,
        cardKey: const Key("sheet_flight_card"),
        target: (overlay, {required first}) =>
            CardFlight.rectOf(landing, overlay),
      );
    }
    issueReset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // The plan changes while the sheet is open when a card is added.
    final session = ref.watch(sessionStateProvider(widget.sessionId)).value;
    final pickOnes =
        session?.disclosurePlan?.disclosureChoicesOverview ?? const [];
    issueListen();
    if (widget.index >= pickOnes.length || session == null) {
      return const SizedBox.shrink();
    }
    final pickOne = pickOnes[widget.index];
    // "Add …" and its steps are subpages inside the sheet, as in a native
    // iOS sheet.
    return GlassSheetConfirmDismiss(
      ask: issueStarted,
      confirm: issueConfirmStop,
      child: GlassSheetPages(
        onBack: issueBack,
        pages: [
          // Opened on the one card the request can use: its details are
          // the first page.
          if (!issueDirect || issueAdding == null)
            KeyedSubtree(
              key: const ValueKey("choose"),
              child: _buildChoose(pickOne),
            ),
          ...issueFlowPages(),
        ],
      ),
    );
  }

  Widget _buildChoose(DisclosurePickOne pickOne) {
    final choices = ref.watch(sessionUserChoicesProvider(widget.sessionId));
    final owned = pickOne.ownedOptions ?? const [];
    final addable = addableOptions(pickOne);
    final selections = selectionsFrom(
      [pickOne],
      {0: ?choices.disclosureChoices[widget.index]},
      {if (choices.addedOptionalIndices.contains(widget.index)) 0},
    );
    final selected =
        pickOne.optional && !choices.addedOptionalIndices.contains(widget.index)
        ? -1
        : selectionOf(pickOne, selections[0]);

    final names = {
      for (final b in owned) _nameOf(b),
      for (final d in addable) d.name,
    };
    final sameType = names.length == 1;

    final title = pickOne.optional
        ? _t("share.sheet.add_optional")
        : sameType
        ? _t("share.sheet.which", {"name": _inSentence(names.single)})
        : _t("share.sheet.what");

    return GlassSheetPage(
      title: title,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Room for the selection outline around a card.
        spacing: 12,
        children: [
          _Intro(
            owned.isEmpty
                ? _t("share.sheet.subtitle_add")
                : _t("share.sheet.subtitle"),
          ),
          if (owned.isNotEmpty) ...[
            _Label(_t("share.in_your_app")),
            for (final (k, b) in owned.indexed)
              Hero(
                tag: choiceHeroTag(widget.sessionId, widget.index, b),
                flightShuttleBuilder: choiceHeroShuttle,
                // Also back into the overview when the sheet is dragged closed.
                transitionOnUserGestures: true,
                child: _OwnedCard(
                  key: Key("sheet_owned_${b.credentials.first.hash}"),
                  bundle: b,
                  selected: k == selected,
                  onTap: () => _pick(pickOne, b),
                ),
              ),
          ],
          if (addable.isNotEmpty) ...[
            _Label(_t("share.not_in_app_yet")),
            // One empty spot per type that can be added, as on the share
            // screen: the card's shape, with what it will share still empty.
            for (final d in addable)
              EmptyCardSpot(
                key: Key("sheet_add_${d.credentialId}"),
                title: owned.any((b) => _nameOf(b) == d.name)
                    ? _t("share.sheet.another", {"name": _inSentence(d.name)})
                    : d.name,
                subtitle: _t("share.sheet.on_host", {
                  "issuer": d.issuer.name,
                  "host": hostOf(d.issueURL)!,
                }),
                rows: emptySpotRows(context, d),
                onTap: () => issueOpen(d),
              ),
          ],
        ],
      ),
    );
  }

  static String _nameOf(DisclosureBundle b) =>
      b.credentials.map((c) => c.name).join(" + ");
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: palette
              .body(12.5, weight: FontWeight.w700)
              .copyWith(letterSpacing: 0.6, color: palette.secondaryText),
        ),
      ),
    );
  }
}

/// The text under a sheet's title, at the top of its scrolling content.
class _Intro extends StatelessWidget {
  final String text;

  const _Intro(this.text);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: palette
            .body(15)
            .copyWith(height: 21 / 15, color: palette.secondaryText),
      ),
    );
  }
}

/// A card in the app, drawn as on the share screen with every value it
/// would share: tap to use it. The one in use has the outline of the current
/// card on the credential's page, drawn just outside the card so it keeps the
/// share screen's size (and hidden while the card flies).
class _OwnedCard extends StatelessWidget {
  final DisclosureBundle bundle;
  final bool selected;
  final VoidCallback onTap;

  const _OwnedCard({
    super.key,
    required this.bundle,
    required this.selected,
    required this.onTap,
  });

  /// The outline's 2 pt line, 3 pt from the card, as on the credential page.
  static const _ring = 2.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final outlined = selected && !SharedCardTileInFlight.of(context);
    const out = -(_ring + _gap);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      onTap: onTap,
      child: PressScale(
        scale: 0.98,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SharedCardTile(bundle: bundle),
              if (outlined)
                Positioned(
                  left: out,
                  top: out,
                  right: out,
                  bottom: out,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: RoundedSuperellipseBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(24 + _ring + _gap),
                          ),
                          side: BorderSide(
                            color: palette.primary,
                            width: _ring,
                          ),
                        ),
                      ),
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
