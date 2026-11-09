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
import "../../../theme/yivi_corners.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/caps_label.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/credential_card/faded_card_art.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/sheet_actions.dart";
import "../../../widgets/glass/sheet_heading.dart";
import "../../../widgets/press_scale.dart";
import "../../../widgets/surface_card.dart";
import "../models/disclosure_view_model.dart";
import "empty_card_spot.dart";
import "issue_flow.dart";
import "issue_sheet_progress.dart";
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
  GlobalKey? liftFrom,
  GlobalKey? returnTo,
  Widget Function(DisclosureBundle bundle, double strip)? tileCopy,
  VoidCallback? onLanded,
}) {
  // A card picked up first: the sheet waits and comes in under it. The
  // tapped card first rises to its row's place ([ChangeChoiceSheet] lifts
  // it in); a card being added only needs a beat.
  final wait = liftFrom == null || MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : addNew != null
      ? const Duration(milliseconds: 120)
      : ChangeChoiceSheet.liftedWait;
  return showGlassSheet<void>(
    context: context,
    motion: (addNew != null ? SheetMotion.issue : SheetMotion.share).copyWith(
      openDelay: wait,
    ),
    builder: (_) => ChangeChoiceSheet(
      key: const Key("disclosure_choice_sheet"),
      sessionId: sessionId,
      index: index,
      addNew: addNew,
      kindsOnly: kindsOnly,
      landingKey: landingKey,
      liftFrom: liftFrom,
      returnTo: returnTo,
      tileCopy: tileCopy,
      onLanded: onLanded,
    ),
  );
}

/// A copy of a card tile, built at a flight's [size] (taller or shorter than
/// the tile: its top stays, the rest is cut), on a transparent material.
Widget tileAtSize(Size size, Widget tile) => Material(
  type: MaterialType.transparency,
  child: SizedBox.fromSize(
    size: size,
    child: ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: SizedBox(width: size.width, child: tile),
      ),
    ),
  ),
);

class ChangeChoiceSheet extends ConsumerStatefulWidget {
  /// How long the sheet waits when a card is lifted in: until the card has
  /// nearly risen to its row's place.
  static const liftedWait = Duration(milliseconds: 320);

  final int sessionId;
  final int index;
  final CredentialDescriptor? addNew;

  /// Only the kinds that can be added, without the cards in the app.
  final bool kindsOnly;

  /// Where a card added in the sheet lands on the share screen.
  final GlobalKey? landingKey;

  /// What was tapped on the share screen: the card (it is picked up and put
  /// down in the sheet), or the picture of a card to add (it rises into the
  /// first step).
  final GlobalKey? liftFrom;

  /// The card on the share screen the chosen card goes back to.
  final GlobalKey? returnTo;

  /// The share screen's tile of a card, with its bottom strip at [strip]
  /// opacity: what flies between the share screen and the sheet.
  final Widget Function(DisclosureBundle bundle, double strip)? tileCopy;

  /// A card added in the sheet has landed in its place on the share screen.
  final VoidCallback? onLanded;

  const ChangeChoiceSheet({
    super.key,
    required this.sessionId,
    required this.index,
    this.addNew,
    this.kindsOnly = false,
    this.landingKey,
    this.liftFrom,
    this.returnTo,
    this.tileCopy,
    this.onLanded,
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
    final from = widget.liftFrom;
    if (from == null) return;
    final adding = widget.addNew;
    if (adding != null) {
      _rise(from, adding);
    } else {
      // The tapped card is picked up and put down on its row here.
      final row = _currentRow;
      if (row != null) YiviFlight.hide([row]);
      WidgetsBinding.instance.addPostFrameCallback((_) => _liftIn(from));
    }
  }

  /// Per card in the app (by its first card's hash): where its row is.
  final _rowKeys = <String, GlobalKey>{};

  GlobalKey _rowKey(DisclosureBundle b) =>
      _rowKeys[b.credentials.first.hash] ??= GlobalKey(
        debugLabel: "sheet_row_${b.credentials.first.hash}",
      );

  /// The bundle in use now.
  DisclosureBundle? get _current {
    final pickOne = _pickOne;
    if (pickOne == null) return null;
    final choices = ref.read(sessionUserChoicesProvider(widget.sessionId));
    if (pickOne.optional &&
        !choices.addedOptionalIndices.contains(widget.index)) {
      return null;
    }
    final selections = selectionsFrom(
      [pickOne],
      {0: ?choices.disclosureChoices[widget.index]},
      {if (choices.addedOptionalIndices.contains(widget.index)) 0},
      preferred: {
        0: ?ref.read(lastSharedBundlesProvider(widget.sessionId))[widget.index],
      },
    );
    final k = selectionOf(pickOne, selections[0]);
    final owned = pickOne.ownedOptions ?? const <DisclosureBundle>[];
    return k >= 0 && k < owned.length ? owned[k] : null;
  }

  GlobalKey? get _currentRow {
    final b = _current;
    return b == null ? null : _rowKey(b);
  }

  /// The chosen card's ring shows once the card has been put down.
  bool _ringShown = true;

  /// Opened from the card on the share screen: it is picked up there (a
  /// little bigger, a shadow, its bottom strip folding away), rises to where
  /// its row will be, waits there while the sheet comes in under it
  /// ([liftedWait]), and is put down on its row, whose ring then fades in.
  /// 800 ms.
  void _liftIn(GlobalKey from) {
    final bundle = _current;
    final row = _currentRow;
    final copy = widget.tileCopy;
    if (!mounted || bundle == null || row == null || copy == null) {
      if (row != null) YiviFlight.show([row]);
      return;
    }
    setState(() => _ringShown = false);
    YiviFlight.start(
      context,
      from: from,
      // Where the row will be once the sheet is up, not where it is while
      // the sheet slides: the card goes there first and waits.
      to: (overlay) => sheetSettledBox(row, overlay),
      keys: [
        const FlightKey(0, FlightKey.start),
        FlightKey(
          0.15,
          (from, to) =>
              Rect.fromLTWH(from.left, from.top, from.width, to.height),
          lifted: true,
          strip: 0,
        ),
        const FlightKey(0.48, FlightKey.end, lifted: true, strip: 0),
        const FlightKey(0.88, FlightKey.end, lifted: true, strip: 0),
        const FlightKey(1, FlightKey.end, strip: 0),
      ],
      duration: const Duration(milliseconds: 800),
      radius: YiviCorners.cardRadius,
      hide: [from, row],
      copyKey: const Key("sheet_lift_card"),
      copy: (context, frame) =>
          tileAtSize(frame.size, copy(bundle, frame.strip)),
      onLanded: () {
        if (mounted) setState(() => _ringShown = true);
      },
    );
  }

  /// Back to the share screen with [bundle] (picked, or the one in use when
  /// the sheet is closed): its row is picked up, carried over the card's
  /// place and put down there, its bottom strip unfolding as it lands, while
  /// the sheet goes down a beat later. 680 ms.
  void _flyBack(DisclosureBundle bundle) {
    final to = widget.returnTo;
    final copy = widget.tileCopy;
    if (to == null || copy == null) return;
    final row = _rowKey(bundle);
    YiviFlight.start(
      context,
      from: row,
      to: YiviFlight.boxOf(to),
      keys: [
        const FlightKey(0, FlightKey.start, strip: 0),
        const FlightKey(0.22, FlightKey.start, lifted: true, strip: 0),
        FlightKey(
          0.72,
          (from, to) => Rect.fromLTWH(to.left, to.top, to.width, from.height),
          lifted: true,
          strip: 0,
        ),
        const FlightKey(1, FlightKey.end),
      ],
      duration: const Duration(milliseconds: 680),
      radius: YiviCorners.cardRadius,
      hide: [row, to],
      copyKey: const Key("sheet_back_card"),
      copy: (context, frame) =>
          tileAtSize(frame.size, copy(bundle, frame.strip)),
    );
  }

  /// Opened on adding a card from its picture on the share screen ([from]),
  /// or from a kind's row in this sheet: the picture is picked up, carried
  /// into the first step's picture and put down there, while the sheet comes
  /// in under it (or grows). 620 ms. The first step's picture shows only once
  /// it has landed.
  void _rise(GlobalKey from, CredentialDescriptor d) {
    YiviFlight.hide([issueHeroKey]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      YiviFlight.start(
        context,
        from: from,
        to: YiviFlight.boxOf(issueHeroKey),
        keys: FlightKey.carry(startOpacity: 0.6),
        duration: const Duration(milliseconds: 620),
        lift: YiviFlight.liftCarried,
        shadow: _carriedShadow,
        radius: const BorderRadius.all(Radius.circular(4)),
        hide: [from, issueHeroKey],
        copy: (context, frame) => SizedBox.fromSize(
          size: frame.size,
          child: FittedBox(
            fit: BoxFit.fill,
            child: CredentialTypeThumbnail(descriptor: d, width: 200),
          ),
        ),
        onLanded: () => YiviFlight.show([issueHeroKey]),
      );
    });
  }

  /// The shadow of a card carried between the page and a sheet.
  static const _carriedShadow = BoxShadow(
    color: Color(0x3D102846),
    blurRadius: 28,
    offset: Offset(0, 12),
  );

  /// The sheet is closing because a card added in it lands on the share
  /// screen: no card flies back from the list.
  bool _landing = false;

  @override
  int get underlyingSessionId => widget.sessionId;

  @override
  SessionState? get issueRequest =>
      ref.read(sessionStateProvider(widget.sessionId)).value;

  schemaless.TrustedParty? get _requestor => issueRequest?.requestor;

  /// The request behind the sheet asks for a signature.
  bool get _signing => issueRequest?.type == SessionType.signature;

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
        _signing ? "share.sheet.continue_sign" : "share.sheet.continue_share",
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
      "share.sheet.added_${count > 1 ? "many" : "one"}${_signing ? "_sign" : ""}",
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
    _picked = bundle;
    Navigator.of(context).pop();
  }

  /// The card picked in the list, to fly back once the sheet is told to go.
  DisclosureBundle? _picked;

  /// The sheet goes (picked, closed, dragged down) from its list: the card
  /// in use flies back to its place on the share screen.
  void _onClose() {
    if (_landing || issueAdding != null) return;
    final bundle = _picked ?? _current;
    if (bundle != null) _flyBack(bundle);
  }

  /// "Continue sharing": the new card flies from the success page into its
  /// spot as the sheet closes. Without a spot to fly to, or for a card of
  /// another type than the one being added (an issuance that happened to
  /// come in meanwhile), the sheet just closes.
  ///
  /// First the spot is brought into view on the page behind the sheet, at
  /// once (it is still under the sheet); then the card is picked up from the
  /// success page (turned as it lies there), carried and put down in the
  /// spot, 950 ms, while the sheet goes down a beat (180 ms) later.
  Future<void> _finish() async {
    final cards = issueAdded ?? const <schemaless.Credential>[];
    final landing = widget.landingKey;
    final i = cards.indexWhere(
      (c) => c.credentialId == issueAdding?.credentialId,
    );
    // A card of a set flies only once the set is whole: until then the
    // spot stays empty.
    if (landing != null && i >= 0 && _nextOfSet(cards) == null) {
      _landing = true;
      final spot = landing.currentContext;
      if (spot != null && !_inView(spot)) {
        Scrollable.ensureVisible(spot, alignment: 0.5);
        // Laid out at its new place before the flight measures it.
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
      }
      final card = cards[i];
      final flew = YiviFlight.start(
        context,
        from: issueAddedKeys[i],
        to: YiviFlight.boxOf(landing),
        keys: const [
          FlightKey(0, FlightKey.start, turn: -0.035),
          FlightKey(0.2, FlightKey.start, lifted: true, turn: -0.035),
          FlightKey(0.8, FlightKey.end, lifted: true),
          FlightKey(1, FlightKey.end),
        ],
        duration: const Duration(milliseconds: 950),
        lift: YiviFlight.liftCarried,
        shadow: _carriedShadow,
        radius: const BorderRadius.all(Radius.circular(4)),
        hide: [landing],
        copyKey: const Key("sheet_flight_card"),
        copy: (context, frame) =>
            CredentialCardArt(credential: card, width: frame.size.width),
        onLanded: widget.onLanded,
      );
      if (flew && mounted) {
        delayGlassSheetClose(context, const Duration(milliseconds: 180));
      }
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
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _onClose();
      },
      child: issueSheet(
        rootKey: "choose",
        root: () => _buildChoose(pickOne),
        onBack: _back,
        // Adding a card is pushed onto the list: the list moves a little
        // further aside and is dimmed under it.
        rootShift: 0.28,
      ),
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
                descriptor: d,
                onTap: () => _addOfSet(set, d),
              ),
          ],
        ],
      ),
    );
  }

  /// Whether the kinds to add are open under "Add another card".
  bool _addOpen = false;

  /// The big headings of the list pages, for the bar's title.
  final _chooseTitle = GlobalKey(debugLabel: "sheet_choose_title");
  final _kindsTitle = GlobalKey(debugLabel: "sheet_kinds_title");

  /// Per kind to add: where its row's picture is.
  final _kindArtKeys = <String, GlobalKey>{};

  GlobalKey _kindArtKey(CredentialDescriptor d) =>
      _kindArtKeys[d.credentialId] ??= GlobalKey(
        debugLabel: "sheet_kind_${d.credentialId}",
      );

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

    final title = pickOne.optional
        ? context.tr("share.sheet.optional_title")
        : context.tr("share.sheet.pick_card");
    return GlassSheetPage(
      title: title,
      titleUnder: _chooseTitle,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeading(
            title: title,
            titleKey: _chooseTitle,
            lead: pickOne.optional
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
          ..._inRows(landscape, gap: 10, first: 18, [
            for (final b in owned)
              FlightSpot(
                flightKey: _rowKey(b),
                child: _OwnedCard(
                  key: Key("sheet_owned_${b.credentials.first.hash}"),
                  bundle: b,
                  selected:
                      _ringShown &&
                      outlined(
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
    final title = pickOne.optional
        ? context.tr("share.sheet.optional_title")
        : context.tr("share.next.pick");
    return GlassSheetPage(
      title: title,
      titleUnder: _kindsTitle,
      // A low sheet with only the kinds; it grows into the full sheet as
      // adding one comes in.
      fit: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        key: const Key("sheet_kinds"),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeading(
            title: title,
            titleKey: _kindsTitle,
            lead: pickOne.optional
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
            const SizedBox(height: 22),
            CapsLabel(
              context.tr(
                many ? "share.sheet.or_add_one" : "share.sheet.or_add_it",
              ),
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
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
          artKey: _kindArtKey(b.missing.single),
          onTap: () {
            _add(b.missing);
            // Its picture rises into the first step as the sheet grows.
            _rise(_kindArtKey(b.missing.single), b.missing.single);
          },
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
            (a.effectiveDisplayName, t("data.add.in_your_app"), false),
      ],
      together: true,
      kinds: b.missing.length > 1 ? b.missing : null,
      descriptor: b.missing.length == 1 ? b.missing.single : null,
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
