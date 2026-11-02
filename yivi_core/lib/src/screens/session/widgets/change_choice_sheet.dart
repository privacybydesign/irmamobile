import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/irma_repository.dart";
import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/last_shared_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/caps_label.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_flight.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/press_scale.dart";
import "../models/disclosure_view_model.dart";
import "empty_card_spot.dart";
import "issue_flow.dart";
import "issue_sheet_progress.dart";
import "session_columns.dart";
import "shared_card_tile.dart";

export "issue_flow.dart" show issuerOpenerProvider;

part "change_choice_rows.dart";

/// The "Change" sheet of the share screen, for pick-one [index]: the cards
/// in the app (one tap picks one and closes the sheet) and, clearly apart,
/// the types that are not in the app yet.
///
/// Adding one of those happens in the sheet ([IssueFlow]): its details, then
/// proving it, then the issuance. "Back to {requestor}" then flies the new
/// card into its spot on the share screen ([landingKey]) as the sheet
/// closes.
///
/// [addNew] opens it straight on the details of that type, for the share
/// button's "Add passport". [kindsOnly] shows only the kinds that can be
/// added ("Choose what you add"), for an item with nothing in the app.
Future<void> showChangeChoiceSheet({
  required BuildContext context,
  required int sessionId,
  required int index,
  CredentialDescriptor? addNew,
  bool kindsOnly = false,
  GlobalKey? landingKey,
}) => showGlassSheet<void>(
  context: context,
  builder: (_) => ChangeChoiceSheet(
    key: const Key("disclosure_choice_sheet"),
    sessionId: sessionId,
    index: index,
    addNew: addNew,
    kindsOnly: kindsOnly,
    landingKey: landingKey,
  ),
);

/// [child], the card of [bundle] as the choice for pick-one [index], as a
/// hero: the card on the share screen and the same card in the sheet, so
/// the chosen card flies into the sheet and the picked one back, also when
/// the sheet is dragged closed.
class ChoiceHero extends StatelessWidget {
  final int sessionId;
  final int index;
  final DisclosureBundle bundle;
  final Widget child;

  const ChoiceHero({
    super.key,
    required this.sessionId,
    required this.index,
    required this.bundle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Hero(
    tag: (
      "disclosure_choice",
      sessionId,
      index,
      bundle.credentials.map((c) => c.hash).join("+"),
    ),
    flightShuttleBuilder: _shuttle,
    transitionOnUserGestures: true,
    child: child,
  );

  /// A card flying between the share screen and the sheet: the card as it
  /// is in the sheet, both ways, without its selection outline, on a
  /// transparent material so its text and ink have one. Back on the share
  /// screen its own card (with "Change choice" and every value) takes over
  /// only once it has landed.
  ///
  /// The flight's box goes from the size of one card to the other; the card
  /// keeps its own height in it, so it does not grow or shrink on the way.
  static Widget _shuttle(
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
      child: SharedCardTileInFlight(
        // The sheet is pushed over the share screen: its card is the
        // destination on the way in and the source on the way back.
        child:
            ((direction == HeroFlightDirection.push ? toContext : fromContext)
                        .widget
                    as Hero)
                .child,
      ),
    ),
  );
}

class ChangeChoiceSheet extends ConsumerStatefulWidget {
  final int sessionId;
  final int index;
  final CredentialDescriptor? addNew;

  /// Only the kinds that can be added, without the cards in the app.
  final bool kindsOnly;

  /// Where a card added in the sheet lands on the share screen.
  final GlobalKey? landingKey;

  const ChangeChoiceSheet({
    super.key,
    required this.sessionId,
    required this.index,
    this.addNew,
    this.kindsOnly = false,
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
  IssueSheetSubject issueSubject(CredentialDescriptor d) {
    final set = _set;
    final n = set?.indexWhere((c) => c.credentialId == d.credentialId) ?? -1;
    return IssueSheetSubject.request(
      _requestor ?? d.issuer,
      ofSet: set != null && n >= 0 ? (n: n + 1, total: set.length) : null,
    );
  }

  @override
  String issueStopText() => context.tr("share.sheet.stop_text", {
    "requestor": _requestor?.name ?? "",
  });

  @override
  void beforeIssueAdd(CredentialDescriptor d) {
    if (_pickOne?.optional ?? false) {
      _choices.includeOptionalWhenAdded(widget.index);
    }
  }

  Map<String, String> _successParams(List<schemaless.Credential> cards) => {
    "name": cards.firstOrNull?.name ?? "",
    "count": "${cards.length}",
    "requestor": _requestor?.name ?? "",
  };

  @override
  SheetAction issueSuccessAction(List<schemaless.Credential> cards) {
    // A card of a set: on to the other one, which the request needs too.
    final next = _nextOfSet(cards);
    if (next != null) {
      return SheetAction(
        key: const Key("sheet_together_next"),
        label: context.tr("share.sheet.together_add_next", {
          "next": _inSentence(next.name),
        }),
        onTap: () => setState(() {
          issueReset();
          issueOpen(next);
        }),
      );
    }
    return SheetAction(
      key: const Key("sheet_back_to_request"),
      label: context.tr(
        "issuance.success_feedback.back_to",
        _successParams(cards),
      ),
      onTap: _finish,
    );
  }

  @override
  IssueSuccessLink? issueSuccessLink(List<schemaless.Credential> cards) =>
      _nextOfSet(cards) == null
      ? null
      : (
          key: const Key("sheet_together_later"),
          label: context.tr("share.sheet.later"),
          onTap: _finish,
        );

  @override
  bool get issueHasOtherChoices {
    final pickOne = _pickOne;
    if (pickOne == null) return false;
    return (pickOne.ownedOptions ?? const []).isNotEmpty ||
        addableBundles(pickOne).length > 1;
  }

  @override
  String issueSuccessText(List<schemaless.Credential> cards) {
    // Added anyway, with a value the request doesn't take: it is in the app,
    // but doesn't count.
    final miss = issuanceMismatches(
      cards,
      issueRequest?.disclosurePlan?.issueDuringDisclosure?.steps ?? const [],
    ).firstOrNull;
    if (miss != null) {
      return context.tr(
        cards.any((c) => c.isSingleton)
            ? "share.offer.done_replaced_not_counted"
            : "share.offer.done_not_counted",
        {
          "requestor": _requestor?.name ?? "",
          "field": miss.attributeName,
          "value": localizedAttributeText(context, miss.required) ?? "",
        },
      );
    }
    final next = _nextOfSet(cards);
    if (next != null) {
      return context.tr("share.sheet.together_added", {
        ..._successParams(cards),
        "next": _inSentence(next.name),
      });
    }
    // The last card of a set added one by one: the set is in.
    final count = _set?.length ?? cards.length;
    return context.tr(
      count > 1
          ? "issuance.success_feedback.added_many_back"
          : "issuance.success_feedback.added_one_back",
      {..._successParams(cards), "count": "$count"},
    );
  }

  /// The pick-one of this sheet, while the request is there.
  DisclosurePickOne? get _pickOne {
    final pickOnes =
        issueRequest?.disclosurePlan?.disclosureChoicesOverview ?? const [];
    return widget.index < pickOnes.length ? pickOnes[widget.index] : null;
  }

  /// Whether this sheet's spot is a set of cards only accepted together.
  bool get _isTogether {
    final pickOne = _pickOne;
    return _set != null ||
        pickOne != null &&
            spotTogether(
              pickOne,
              issueRequest?.disclosurePlan?.issueDuringDisclosure,
            );
  }

  /// The cards being added one by one for an option of several that only
  /// go together ("Add both"), picked under "Not in your app yet".
  List<CredentialDescriptor>? _set;

  /// After adding [added], the card of the set still missing, if any.
  CredentialDescriptor? _nextOfSet(List<schemaless.Credential> added) {
    final pickOne = _pickOne;
    if (pickOne == null || !_isTogether) return null;
    final inApp = {
      ...ref.read(cardTypesInAppProvider),
      for (final c in added) c.credentialId,
    };
    for (final d in _set ?? addableOptions(pickOne)) {
      if (!inApp.contains(d.credentialId)) return d;
    }
    return null;
  }

  /// Adds what is missing of an option: one card, or, of a set, the first
  /// and then the next ([_nextOfSet]).
  void _add(List<CredentialDescriptor> missing) {
    _set = missing.length > 1 ? missing : null;
    issueOpen(missing.first);
  }

  /// Adds [d], one card of a [set] only accepted together, and then the
  /// rest of it. The set is kept: once [d] is in the app the request only
  /// offers the others, and no longer reads as a set.
  void _addOfSet(List<CredentialDescriptor> set, CredentialDescriptor d) {
    _set = set;
    issueOpen(d);
  }

  SessionUserChoicesNotifier get _choices =>
      ref.read(sessionUserChoicesProvider(widget.sessionId).notifier);

  String _inSentence(String name) => inSentence(name, language: context.lang);

  /// "Share nothing": the optional data is left out.
  void _pickNothing() {
    _press(_nothing);
    _choices.removeOptional(widget.index);
    Navigator.of(context).pop();
  }

  static const _nothing = "nothing";

  void _pick(DisclosurePickOne pickOne, DisclosureBundle bundle) {
    if (pickOne.optional) _choices.addOptional(widget.index);
    _choices.setBundle(widget.index, bundle);
    Navigator.of(context).pop();
  }

  /// "Back to {requestor}": the new card flies into its spot as the sheet
  /// closes. Without a spot to fly to, or for a card of another type than
  /// the one being added (an issuance that happened to come in meanwhile),
  /// the sheet just closes. On a tablet held upright, where the share screen
  /// has its tablet columns, the card fades into its spot instead; held
  /// sideways (also an unfolded phone) it flies, as on the phone.
  Future<void> _finish() async {
    final cards = issueAdded ?? const <schemaless.Credential>[];
    final landing = widget.landingKey;
    final i = cards.indexWhere(
      (c) => c.credentialId == issueAdding?.credentialId,
    );
    // A card of a set flies only once the set is whole: until then the
    // spot stays empty.
    if (landing != null &&
        i >= 0 &&
        !useSessionColumns(context) &&
        _nextOfSet(cards) == null) {
      // First the spot into view on the page behind the sheet (to its middle,
      // clear of the bars), then the flight: the card lands where they see
      // it.
      final spot = landing.currentContext;
      if (spot != null && !_inView(spot)) {
        await Scrollable.ensureVisible(
          spot,
          alignment: 0.5,
          duration: YiviMotion.duration(
            context,
            const Duration(milliseconds: 320),
          ),
          curve: Curves.easeOutCubic,
        );
        if (!mounted) return;
      }
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
    // On "Success" while the sheet goes.
    issueClose();
  }

  /// Whether [spot] is in view on its page, clear of the bars over it (the
  /// top bar, the share button at the bottom).
  static bool _inView(BuildContext spot) {
    final box = spot.findRenderObject();
    final scrollable = Scrollable.maybeOf(spot);
    final viewport = scrollable?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || !box.hasSize) {
      return true;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final bottom = top + box.size.height;
    const bars = 120.0, button = 190.0;
    return top >= bars && bottom <= viewport.size.height - button;
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
    return issueSheet(
      rootKey: "choose",
      root: () => _buildChoose(pickOne),
      onBack: _back,
    );
  }

  /// The card in the app tapped: it has the outline of the chosen card
  /// from the moment the finger lifts, as the sheet closes with it. A card
  /// to add never gets it: the outline stays on the card in use.
  /// `owned:{hash}`, or `nothing` for "Share nothing".
  String? _pressed;

  void _press(String? key) {
    if (_pressed != key) setState(() => _pressed = key);
  }

  /// Back from adding a card: the list shows the card in use again.
  void _back() {
    _pressed = null;
    issueBack();
  }

  /// A set of cards only accepted together: both are needed, so the page
  /// says so and shows them as numbered steps, each in the app already or
  /// still to add, instead of a choice of one.
  Widget _buildTogether(DisclosurePickOne pickOne) {
    final palette = YiviPalette.of(context);
    final set = addableOptions(pickOne);
    final inApp = ref.watch(cardTypesInAppProvider);
    return GlassSheetPage(
      title: context.tr("share.sheet.together_title"),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        key: const Key("sheet_together"),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Intro(
            context.tr("share.sheet.together_intro", {
              "requestor": _requestor?.name ?? "",
            }),
          ),
          for (final (n, d) in set.indexed) ...[
            SizedBox(height: n == 0 ? 18 : 24),
            CapsLabel(
              context.tr("share.sheet.together_step", {
                "n": "${n + 1}",
                "total": "${set.length}",
              }),
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            if (inApp.contains(d.credentialId)) ...[
              const SizedBox(height: 8),
              CardTile(
                key: Key("sheet_together_in_app_${d.credentialId}"),
                art: CredentialTypeThumbnail(
                  descriptor: d,
                  width: SharedCardTile.miniWidth,
                  owned: true,
                ),
                title: d.name,
                subtitle: context.tr("data.add.in_your_app"),
                trailing: Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: palette.successText,
                ),
              ),
            ] else
              EmptyCardSpot(
                key: Key("sheet_add_${d.credentialId}"),
                title: d.name,
                subtitle: d.issuer.name,
                rows: emptySpotRows(context, d),
                onTap: () => _addOfSet(set, d),
              ),
          ],
        ],
      ),
    );
  }

  /// Whether the kinds to add are open under "Add another card".
  bool _addOpen = false;

  Widget _buildChoose(DisclosurePickOne pickOne) {
    if (spotTogether(
      pickOne,
      ref
          .watch(sessionStateProvider(widget.sessionId))
          .value
          ?.disclosurePlan
          ?.issueDuringDisclosure,
    )) {
      return _buildTogether(pickOne);
    }
    final owned = pickOne.ownedOptions ?? const <DisclosureBundle>[];
    if (widget.kindsOnly || owned.isEmpty) return _buildKinds(pickOne);
    final choices = ref.watch(sessionUserChoicesProvider(widget.sessionId));
    // A card that can't be used carries its own "Add a new one"; its kind
    // is not offered again below.
    final problemIds = {
      for (final b in owned)
        if (problemOfBundle(b) != null)
          for (final c in b.credentials) c.credentialId,
    };
    final ownedIds = {
      for (final b in owned)
        for (final c in b.credentials) c.credentialId,
    };
    // Another of a kind you already have comes first.
    bool another(ObtainableBundle b) =>
        b.owned.isEmpty &&
        b.missing.length == 1 &&
        ownedIds.contains(b.missing.single.credentialId);
    final kept = [
      for (final b in addableBundles(pickOne))
        if (!(b.owned.isEmpty &&
            b.missing.length == 1 &&
            problemIds.contains(b.missing.single.credentialId)))
          b,
    ];
    final addable = [...kept.where(another), ...kept.where((b) => !another(b))];
    final selections = selectionsFrom(
      [pickOne],
      {0: ?choices.disclosureChoices[widget.index]},
      {if (choices.addedOptionalIndices.contains(widget.index)) 0},
      preferred: {
        0: ?ref.watch(
          lastSharedBundlesProvider(widget.sessionId),
        )[widget.index],
      },
    );
    final selected =
        pickOne.optional && !choices.addedOptionalIndices.contains(widget.index)
        ? -1
        : selectionOf(pickOne, selections[0]);
    final landscape = useSheetColumns(context);

    // The outline: on the card in use, or the one in the app just tapped.
    bool outlined(String key, {String? current}) =>
        _pressed != null ? _pressed == key : key == current;
    final current = selected >= 0 && selected < owned.length
        ? "owned:${owned[selected].credentials.first.hash}"
        : pickOne.optional
        ? _nothing
        : null;
    final requestor = _requestor?.name ?? "";
    final usable = owned.any((b) => problemOfBundle(b) == null);
    // Nothing usable in the app: what can be added is open from the start.
    final addOpen = _addOpen || !usable;

    return GlassSheetPage(
      title: pickOne.optional
          ? context.tr("share.sheet.optional_title")
          : context.tr("share.sheet.pick_card"),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Intro(
            pickOne.optional
                ? _optionalIntro(pickOne, requestor)
                : context.tr("share.sheet.subtitle_one", {
                    "requestor": requestor,
                  }),
          ),
          // Optional data: leaving it out is the first choice, the whole
          // width also held sideways.
          if (pickOne.optional) ...[
            const SizedBox(height: 18),
            _ShareNothingCard(
              key: const Key("sheet_share_nothing"),
              subtitle: context.tr("share.sheet.share_nothing_sub", {
                "requestor": requestor,
              }),
              selected: outlined(_nothing, current: current),
              onTap: _pickNothing,
            ),
          ],
          ..._inRows(landscape, gap: 12, first: 18, [
            for (final b in owned)
              ChoiceHero(
                sessionId: widget.sessionId,
                index: widget.index,
                bundle: b,
                child: _OwnedCard(
                  key: Key("sheet_owned_${b.credentials.first.hash}"),
                  bundle: b,
                  selected: outlined(
                    "owned:${b.credentials.first.hash}",
                    current: current,
                  ),
                  fix: _fixOf(pickOne, b),
                  onTap: () {
                    _press("owned:${b.credentials.first.hash}");
                    _pick(pickOne, b);
                  },
                ),
              ),
          ]),
          if (addable.isNotEmpty) ...[
            const SizedBox(height: 24),
            _AddToggle(
              key: const Key("sheet_more_toggle"),
              label: context.tr("share.sheet.add_other"),
              open: addOpen,
              onTap: usable ? () => setState(() => _addOpen = !_addOpen) : null,
            ),
            if (addOpen) ..._kindRows(addable, requestor, landscape),
          ],
        ],
      ),
    );
  }

  /// "Add a new passport" under a card in the app that can't be used.
  ({String label, VoidCallback onTap})? _fixOf(
    DisclosurePickOne pickOne,
    DisclosureBundle bundle,
  ) {
    if (problemOfBundle(bundle) == null) return null;
    final fix = fixFor(pickOne, bundle);
    if (fix == null) return null;
    final single = replacesCard(fix, bundle);
    return (
      label: context.tr(
        single ? "share.next.fetch_again" : "share.next.add_again",
        {"name": fix.name},
      ),
      onTap: () => _add([fix]),
    );
  }

  /// "{requestor} asks for this / for one of these cards, but you don't have
  /// to share it."
  String _optionalIntro(DisclosurePickOne pickOne, String requestor) {
    final many = optionalKinds(pickOne).length > 1;
    final none = (pickOne.ownedOptions ?? const []).isEmpty;
    return context.tr(
      "share.sheet.optional_intro${many ? "_many" : ""}${none ? "_none" : ""}",
      {"requestor": requestor},
    );
  }

  /// Only the kinds that can be added: "Choose what you add" for an item
  /// with nothing in the app (from the share button, or the spot), and for
  /// optional data with nothing in the app, "Don't share" on top.
  Widget _buildKinds(DisclosurePickOne pickOne) {
    final requestor = _requestor?.name ?? "";
    final addable = addableBundles(pickOne);
    final landscape = useSheetColumns(context);
    final docs =
        addable.isNotEmpty &&
        addable.every(
          (b) => b.missing.every(
            (d) =>
                ref
                    .read(irmaRepositoryProvider)
                    .embeddedFlowOf(d.credentialId) ==
                EmbeddedFlow.document,
          ),
        );
    final many = addable.length > 1;
    return GlassSheetPage(
      title: pickOne.optional
          ? context.tr("share.sheet.optional_title")
          : context.tr("share.next.pick"),
      // A low sheet with only the kinds; it grows into the full sheet as
      // adding one comes in.
      fit: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        key: const Key("sheet_kinds"),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Intro(
            pickOne.optional
                ? _optionalIntro(pickOne, requestor)
                : context.tr(
                    docs
                        ? "share.sheet.subtitle_one_docs"
                        : "share.sheet.subtitle_one_add",
                    {"requestor": requestor},
                  ),
          ),
          if (pickOne.optional) ...[
            const SizedBox(height: 18),
            _ShareNothingCard(
              key: const Key("sheet_share_nothing"),
              subtitle: context.tr("share.sheet.share_nothing_sub", {
                "requestor": requestor,
              }),
              selected: true,
              onTap: _pickNothing,
            ),
            const SizedBox(height: 24),
            CapsLabel(
              context.tr(
                many ? "share.sheet.or_add_one" : "share.sheet.or_add_it",
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
          ],
          ..._kindRows(addable, requestor, landscape),
        ],
      ),
    );
  }

  /// A row per kind to add, or a spot for a set that only goes together.
  List<Widget> _kindRows(
    List<ObtainableBundle> addable,
    String requestor,
    bool landscape,
  ) => _inRows(landscape, gap: 10, first: 12, [
    for (final b in addable)
      if (b.owned.isEmpty && b.missing.length == 1)
        _AddKindRow(
          key: Key("sheet_add_${b.missing.single.credentialId}"),
          descriptor: b.missing.single,
          onTap: () => _add(b.missing),
        )
      else
        _setSpot(b, requestor),
  ]);

  /// An option of several cards that only go together, not all in the app:
  /// one empty spot, "Passport + Address", that says what is there already
  /// and what is still to add, with the fields of each. Its pill adds the
  /// missing card, or both one by one.
  Widget _setSpot(ObtainableBundle b, String requestor) {
    final t = context.tr;
    final missingNames = [for (final d in b.missing) d.name];
    final ownedNames = [for (final c in b.owned) c.name];
    return EmptyCardSpot(
      key: Key(
        "sheet_add_${[for (final d in b.missing) d.credentialId].join("+")}",
      ),
      title: [...missingNames, ...ownedNames].join(" + "),
      subtitle: b.owned.isEmpty
          ? t("share.spot.together_both", {"requestor": requestor})
          : t("share.spot.together_one_left", {
              "name": andList(ownedNames, t("share.and")),
              "other": andList([
                for (final n in missingNames) _inSentence(n),
              ], t("share.and")),
              "requestor": requestor,
            }),
      rows: [
        for (final d in b.missing) ...emptySpotRows(context, d),
        for (final c in b.owned)
          for (final a in c.attributes)
            (a.effectiveDisplayName, t("data.add.in_your_app")),
      ],
      together: true,
      kinds: b.missing.length > 1 ? b.missing : null,
      // What a tap adds: both, or the one card the set still misses.
      addLabel: b.missing.length > 1
          ? t("share.add_both")
          : t("share.sheet.together_add_next", {
              "next": _inSentence(b.missing.single.name),
            }),
      onTap: () => _add(b.missing),
    );
  }

  /// [cards] under each other with [gap] between them (and [first] above the
  /// first: room for the outline around a card), or on a phone held
  /// sideways two side by side, the rows [gap] apart.
  static List<Widget> _inRows(
    bool landscape,
    List<Widget> cards, {
    required double gap,
    double? first,
  }) {
    if (!landscape) {
      return [
        for (final (n, c) in cards.indexed) ...[
          SizedBox(height: n == 0 ? first ?? gap : gap),
          c,
        ],
      ];
    }
    return [
      for (var n = 0; n < cards.length; n += 2) ...[
        SizedBox(height: n == 0 ? first ?? gap : gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            Expanded(child: cards[n]),
            Expanded(
              child: n + 1 < cards.length
                  ? cards[n + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    ];
  }
}
