import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/dutch_another.dart";
import "../../../util/i18n.dart";
import "../../../widgets/caps_label.dart";
import "../../../widgets/credential_card/card_flight.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../models/disclosure_view_model.dart";
import "empty_card_spot.dart";
import "issue_flow.dart";
import "issue_sheet_progress.dart";
import "session_columns.dart";
import "shared_card_tile.dart";

export "issue_flow.dart" show issuerOpenerProvider;

/// What optional [pickOne] asks for, in a sentence: "your date of birth",
/// "your first names, surname and date of birth", or by its cards, "data
/// from your personal data" ([optionalWhat]).
String optionalWhatText(BuildContext context, DisclosurePickOne pickOne) {
  final language = FlutterI18n.currentLocale(context)?.languageCode;
  final what = optionalWhat(pickOne);
  final list = andList([
    for (final n in what.names) inSentence(n, language: language),
  ], context.tr("share.and"));
  return context.tr(
    what.byCard ? "share.optional.what_cards" : "share.optional.what_fields",
    {"list": list},
  );
}

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
  String issueStopText() => context.tr("share.sheet.stop_text", {
    "requestor": _requestor?.name ?? "",
  });

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
  String issueSuccessText(List<schemaless.Credential> cards) {
    final next = _nextOfSet(cards);
    if (next != null) {
      return context.tr("share.sheet.together_added", {
        ..._successParams(cards),
        "next": _inSentence(next.name),
      });
    }
    return context.tr(
      cards.length > 1
          ? "issuance.success_feedback.added_many_back"
          : "issuance.success_feedback.added_one_back",
      _successParams(cards),
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

  SessionUserChoicesNotifier get _choices =>
      ref.read(sessionUserChoicesProvider(widget.sessionId).notifier);

  String _inSentence(String name) => inSentence(
    name,
    language: FlutterI18n.currentLocale(context)?.languageCode,
  );

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
  void _finish() {
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
            _Label(
              context.tr("share.sheet.together_step", {
                "n": "${n + 1}",
                "total": "${set.length}",
              }),
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
                onTap: () => issueOpen(d),
              ),
          ],
        ],
      ),
    );
  }

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
    final choices = ref.watch(sessionUserChoicesProvider(widget.sessionId));
    final owned = pickOne.ownedOptions ?? const [];
    final ownedIds = {
      for (final b in owned)
        for (final c in b.credentials) c.credentialId,
    };
    // Another of a kind you already have comes first.
    bool another(ObtainableBundle b) =>
        b.owned.isEmpty &&
        b.missing.length == 1 &&
        ownedIds.contains(b.missing.single.credentialId);
    final addable = [
      ...addableBundles(pickOne).where(another),
      ...addableBundles(pickOne).where((b) => !another(b)),
    ];
    final selections = selectionsFrom(
      [pickOne],
      {0: ?choices.disclosureChoices[widget.index]},
      {if (choices.addedOptionalIndices.contains(widget.index)) 0},
    );
    final selected =
        pickOne.optional && !choices.addedOptionalIndices.contains(widget.index)
        ? -1
        : selectionOf(pickOne, selections[0]);
    final language = FlutterI18n.currentLocale(context)?.languageCode;
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
    final what = pickOne.optional ? optionalWhatText(context, pickOne) : "";

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
                ? context.tr("share.sheet.optional_intro", {
                    "requestor": requestor,
                    "what": what,
                  })
                : owned.isEmpty
                ? context.tr("share.sheet.subtitle_one_add")
                : context.tr("share.sheet.subtitle_one"),
          ),
          // Optional data: leaving it out is the first choice, the whole
          // width also held sideways.
          if (pickOne.optional) ...[
            const SizedBox(height: 18),
            _ShareNothingCard(
              key: const Key("sheet_share_nothing"),
              subtitle: context.tr("share.sheet.share_nothing_sub", {
                "requestor": requestor,
                "what": what,
              }),
              selected: outlined(_nothing, current: current),
              onTap: _pickNothing,
            ),
          ],
          if (owned.isNotEmpty) ...[
            SizedBox(height: pickOne.optional ? 32 : 18),
            _Label(context.tr("share.sheet.already_in_app")),
            ..._inRows(landscape, gap: 12, [
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
                    onTap: () {
                      _press("owned:${b.credentials.first.hash}");
                      _pick(pickOne, b);
                    },
                  ),
                ),
            ]),
          ],
          if (addable.isNotEmpty) ...[
            // Clearly apart from the cards in the app; the first empty card
            // keeps room above its edge for its pill.
            SizedBox(height: owned.isEmpty && !pickOne.optional ? 18 : 44),
            _Label(context.tr("share.not_in_app_yet")),
            ..._inRows(landscape, gap: 12, first: 0, [
              for (final b in addable)
                if (b.owned.isEmpty && b.missing.length == 1)
                  EmptyCardSpot(
                    key: Key("sheet_add_${b.missing.single.credentialId}"),
                    title: another(b)
                        ? context.tr(
                            anotherNameKey(
                              b.missing.single.name,
                              languageCode: language,
                            ),
                            {"name": _inSentence(b.missing.single.name)},
                          )
                        : b.missing.single.name,
                    subtitle: b.missing.single.issuer.name,
                    rows: emptySpotRows(context, b.missing.single),
                    onTap: () => _add(b.missing),
                  )
                else
                  _setSpot(b, requestor),
            ]),
          ],
        ],
      ),
    );
  }

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

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      CapsLabel(text, padding: const EdgeInsets.symmetric(horizontal: 6));
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

/// "Share nothing", the first choice for optional data: a card the size of
/// the others with a grey tile where the card art goes. It has the outline
/// while the data is left out; a tap leaves it out and closes the sheet.
class _ShareNothingCard extends StatelessWidget {
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ShareNothingCard({
    super.key,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      onTap: onTap,
      child: PressScale(
        scale: PressScale.card,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: CardTileOutline(
            shown: selected,
            child: CardTile(
              art: Container(
                width: CardTile.miniWidth,
                height: CardTile.miniHeight,
                decoration: ShapeDecoration(
                  color: palette.secondaryText.withValues(alpha: 0.1),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                ),
                child: Icon(
                  Icons.block_rounded,
                  size: 20,
                  color: palette.secondaryText,
                ),
              ),
              title: context.tr("share.sheet.share_nothing"),
              subtitle: subtitle,
              subtitleMaxLines: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A card in the app, drawn as on the share screen with every value it
/// would share: tap to use it. The chosen one (or the one a finger is on)
/// has the outline of the current card on the credential's page, drawn
/// just outside the card so it keeps the share screen's size (and hidden
/// while the card flies).
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

  @override
  Widget build(BuildContext context) {
    final outlined = selected && !SharedCardTileInFlight.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      onTap: onTap,
      child: PressScale(
        scale: PressScale.card,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: CardTileOutline(
            shown: outlined,
            child: SharedCardTile(bundle: bundle),
          ),
        ),
      ),
    );
  }
}
