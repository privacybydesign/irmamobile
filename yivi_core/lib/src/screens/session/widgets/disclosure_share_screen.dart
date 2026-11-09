import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/requestor_trust.dart";
import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/last_shared_provider.dart";
import "../../../providers/schemaless_credentials_list_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_motion.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/adaptive_layout.dart";
import "../../../util/i18n.dart";
import "../../../widgets/caps_label.dart";
import "../../../widgets/compact_bar.dart";
import "../../../widgets/credential_card/attribute_groups/attribute_group.dart";
import "../../../widgets/credential_card/card_art/card_art_support.dart";
import "../../../widgets/credential_card/card_art/credential_card_art.dart";
import "../../../widgets/credential_card/card_tile.dart";
import "../../../widgets/credential_card/yivi_credential_card_attribute_list.dart";
import "../../../widgets/fill_scroll_view.dart";
import "../../../widgets/flight/yivi_flight.dart";
import "../../../widgets/floating_bar_placement.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/irma_bottom_bar_base.dart";
import "../../../widgets/scroll_edge.dart";
import "../../../widgets/signed_message.dart";
import "../../../widgets/status_chip.dart";
import "../models/disclosure_view_model.dart";
import "../models/technical_details.dart";
import "change_choice_sheet.dart";
import "done_flight.dart";
import "empty_card_spot.dart";
import "requestor_card.dart";
import "requestor_trust_sheet.dart";
import "session_columns.dart";
import "session_scaffold.dart";
import "shared_card_tile.dart";

part "disclosure_share_parts.dart";

/// The share screen: one title that says who asks what ("Webshop Noord is
/// asking for your data"), who they are, then one card per requested item
/// with only the values that are shared, optional data, the message to
/// sign or the card offered in return, and one button.
///
/// - A card with other choices has a strip at its foot: "You can also
///   choose another card" with "Change choice", which opens the Change sheet.
/// - A required card that is not in the app yet is an empty spot: Add
///   opens adding it, and the new card flies into the spot. With several
///   types to choose from, the spot shows them as small cards, and the
///   choice is made in a sheet with only those types.
/// - A card in the app that does not count for the request (a value is not
///   what they ask) is shown as it is, with what they ask.
/// - Optional data that is not shared is a row naming its kinds, with
///   "Share"; once shared it is a card with "Change choice".
/// - The footnote sits right under the last card.
/// - Once the requestor card has scrolled under the bar, a compact bar at
///   the top says who asks, as on the detail pages.
///
/// The button is the consent: there is no confirmation dialog after it,
/// except for a party nobody vouches for. While something is missing or
/// can't be used, the button does that next step ("Add passport") with
/// what is left above it; it closes the session when that can't be done in
/// Yivi.
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
  /// compact bar then says who asks).
  final _headerKey = GlobalKey(debugLabel: "share_requestor_card");
  final _scrolledPast = ValueNotifier(false);

  /// The requestor's logo: it flies into the trust sheet and back.
  final _logoKey = GlobalKey(debugLabel: "share_requestor_logo");

  /// The message to sign: it grows into the message sheet, and flies into
  /// the done screen.
  final _messageKey = GlobalKey(debugLabel: "share_message");

  /// The page's scroll: a card is brought into view before it lifts into a
  /// sheet and before one lands in it.
  final _scroll = ScrollController();

  /// See [_orderOf].
  List<int>? _order;

  /// How far the page is scrolled: the list lets go of the card once it is
  /// far out of view, and then this says it has passed.
  double _scrolled = 0;

  /// Per pick-one, where a card added for it in the sheet lands.
  final _landingKeys = <int, GlobalKey>{};

  GlobalKey _landingKey(int i) =>
      _landingKeys[i] ??= GlobalKey(debugLabel: "share_landing_$i");

  /// Per pick-one, its whole card: it is picked up into the Change sheet and
  /// put down here again.
  final _tileKeys = <int, GlobalKey>{};

  GlobalKey _tileKey(int i) =>
      _tileKeys[i] ??= GlobalKey(debugLabel: "share_tile_$i");

  /// Pick-ones whose card landed while this screen was open: a green ring
  /// that fades in as it lands and stays.
  final _landed = <int>{};

  /// Something was missing or couldn't be used: once everything is there,
  /// the share button fades in.
  bool _hadToDo = false;

  /// The share button is fading in after the last card landed; taps are
  /// ignored meanwhile (a second tap on "Back to …" would land on it).
  bool _arriving = false;
  final _timers = <Timer>[];

  /// The pick-ones with no card in the app yet (a spot, or optional data
  /// with nothing to pick).
  static Set<int> _emptyOf(SessionState s) => {
    for (final (i, p)
        in (s.disclosurePlan?.disclosureChoicesOverview ??
                const <DisclosurePickOne>[])
            .indexed)
      if ((p.ownedOptions ?? const []).isEmpty) i,
  };

  static bool _hasToDo(SessionState s) => shareButton(s, const {}).next != null;

  /// Pick-ones that got their card while a sheet was open: they light up
  /// once it has landed ([_land]), not while the sheet still covers them.
  final _arrived = <int>{};

  /// Sheets of this screen that are open.
  int _sheets = 0;

  @override
  void initState() {
    super.initState();
    _hadToDo = _hasToDo(widget.session);
  }

  @override
  void didUpdateWidget(DisclosureShareScreen old) {
    super.didUpdateWidget(old);
    final filled = _emptyOf(old.session).difference(_emptyOf(widget.session));
    if (filled.isEmpty) return;
    _arrived.addAll(filled);
    // Nothing over the page (the card came in some other way): at once.
    if (_sheets == 0 && !YiviFlight.isFlying) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _land(fromSheet: false),
      );
    }
  }

  /// The cards that arrived are in place: a green ring around each for a
  /// moment, and, when nothing is left to do, "All set". Back from a sheet
  /// the share button fades in, ignoring taps meanwhile: it sits where "Back
  /// to …" was, and a second tap there must not share.
  void _land({bool fromSheet = true}) {
    if (!mounted || _arrived.isEmpty) return;
    final landed = {..._arrived};
    _arrived.clear();
    setState(() {
      _landed.addAll(landed);
      if (_hadToDo && !_hasToDo(widget.session)) {
        if (fromSheet) {
          _arriving = true;
          _later(const Duration(milliseconds: 1300), () => _arriving = false);
        }
      }
    });
  }

  /// Shows a sheet of this screen; once it has gone, a card that came in
  /// without a flight (a tablet, where it fades in) lands.
  Future<void> _trackSheet(Future<void> sheet) async {
    _sheets++;
    try {
      await sheet;
    } finally {
      _sheets--;
    }
    if (!mounted || YiviFlight.isFlying) return;
    _land();
  }

  void _later(Duration d, VoidCallback change) => _timers.add(
    Timer(d, () {
      if (mounted) setState(change);
    }),
  );

  int get _sessionId => widget.session.id;

  List<DisclosurePickOne> get _pickOnes =>
      widget.session.disclosurePlan?.disclosureChoicesOverview ?? const [];

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _scrolledPast.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Whether the requestor's name has started to go under the bar (its top,
  /// 12 into the card): the compact bar then says who asks, so the name is
  /// never cut off without it.
  void _checkHeader() {
    if (!mounted) return;
    _scrolledPast.value =
        headerUnderBar(context, _headerKey, at: 12) ?? _scrolled > 0;
  }

  /// The choice sheet for pick-one [i]: "Change choice", "Add" on a spot,
  /// and the fix of a card that cannot be shared. With [addNew] it opens on
  /// adding that type. With [kindsOnly] it is "Choose what you add": only
  /// the kinds that can be added (and "Don't share" for optional data).
  ///
  /// First the card is brought into view, between the bar and the button
  /// (a smooth scroll, 380 ms), when it is not; then it is picked up into the
  /// sheet: the card into "Which card do you share?", or the picture of one
  /// to add into the first step of adding it.
  Future<void> _openSheet(
    int i, {
    CredentialDescriptor? addNew,
    bool kindsOnly = false,
  }) async {
    final lifts = addNew != null || !kindsOnly;
    final liftFrom = !lifts
        ? null
        : addNew != null
        ? _landingKey(i)
        : _tileKey(i);
    await _reveal(liftFrom ?? _landingKey(i));
    if (!mounted) return;
    await _trackSheet(
      showChangeChoiceSheet(
        context: context,
        sessionId: _sessionId,
        index: i,
        addNew: addNew,
        kindsOnly: kindsOnly,
        landingKey: _landingKey(i),
        liftFrom: liftFrom,
        returnTo: _tileKey(i),
        tileCopy: (bundle, strip) => _tileCopy(i, bundle, strip),
        onLanded: _land,
      ),
    );
  }

  /// Brings the card at [key] into view between the bar and the button,
  /// to the middle of that room, when it is not (a smooth scroll, then a
  /// moment for it to settle).
  Future<void> _reveal(GlobalKey key) async {
    final spot = key.currentContext;
    if (spot == null || !_scroll.hasClients) return;
    final box = spot.findRenderObject();
    final viewport = Scrollable.maybeOf(spot)?.context.findRenderObject();
    if (box is! RenderBox || viewport is! RenderBox || !box.hasSize) return;
    final sideways = useSheetColumns(context) || useSessionColumns(context);
    final top = sideways ? 40.0 : 120.0;
    final bottom = viewport.size.height - (sideways ? 16.0 : 200.0);
    final y = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    if (y >= top && y + box.size.height <= bottom) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      await Scrollable.ensureVisible(spot, alignment: 0.5);
      return;
    }
    await Scrollable.ensureVisible(
      spot,
      alignment: 0.5,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
    );
  }

  /// The share screen's tile of [bundle] for pick-one [i], with its bottom
  /// strip at [strip]: what flies between this screen and the sheet.
  Widget _tileCopy(int i, DisclosureBundle bundle, double strip) {
    final p = _pickOnes[i];
    final k = (p.ownedOptions ?? const []).indexOf(bundle);
    final footer = k < 0 ? null : _choiceStrip(i, p, k);
    return SharedCardTile(
      bundle: bundle,
      footer: footer == null ? null : Opacity(opacity: strip, child: footer),
    );
  }

  /// What the share button does before it can share.
  void _doNext(NextStep next) => switch (next.kind) {
    NextKind.add ||
    NextKind.addAgain ||
    NextKind.fetchAgain => _openSheet(next.index, addNew: next.descriptor),
    NextKind.pick => _openSheet(next.index, kindsOnly: true),
    NextKind.addBoth => _openSheet(next.index),
  };

  String _nextLabel(NextStep next) {
    return switch (next.kind) {
      NextKind.add => context.tr("share.next.add_card", {
        "card": next.descriptor?.name ?? "",
      }),
      NextKind.addAgain => context.tr("share.next.add_again"),
      NextKind.fetchAgain => context.tr("share.next.fetch_again"),
      NextKind.pick => context.tr("share.next.pick"),
      NextKind.addBoth => context.tr("share.add_both"),
    };
  }

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
      preferred: ref.watch(lastSharedBundlesProvider(_sessionId)),
    );
    final wallet = ref.watch(walletCardsProvider);
    final button = shareButton(session, selections, wallet: wallet);
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
      logoFrom: _logoKey,
      onDontShare: widget.onClose,
      technicalDetails: technicalDetailsOf(
        session,
        _sharedCredentials(pickOnes, selections),
        t,
      ),
    );

    final ask = t("share.ask.$kind");
    // Only optional data: say that nothing has to be shared.
    final lead = t("share.section.nothing_required_text", {
      "requestor": requestor,
    });

    final messageText = isSignature ? session.messageToSign : null;
    final message = messageText == null
        ? null
        : FlightSpot(
            flightKey: _messageKey,
            child: SignedMessage(
              key: const Key("share_message"),
              message: messageText,
              clamp: SignedMessage.shareClamp,
              onReadAll: () => showSignedMessageSheet(
                context: context,
                message: messageText,
                lead: t("share.message_sheet.lead", {"requestor": requestor}),
                from: _messageKey,
              ),
            ),
          );

    final title = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Semantics(
        header: true,
        child: Text(
          t("share.title.$kind"),
          key: const Key("share_title"),
          style: palette
              .display(24, weight: FontWeight.w700)
              .copyWith(height: 30 / 24, color: palette.text),
        ),
      ),
    );
    final card = KeyedSubtree(
      key: _headerKey,
      child: RequestorCard.compact(
        requestor: session.requestor,
        onInfo: openTrust,
        logoKey: _logoKey,
      ),
    );

    // The title says what is going on; the card under it says with whom.
    final requestorPart = <_Spaced>[
      _Spaced(0, title),
      _Spaced(18, card),
      if (required.isEmpty && optional.isNotEmpty)
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
    ];
    final messagePart = <_Spaced>[
      if (message != null) ...[
        _Spaced(24, _SectionLabel(t("share.message_label"))),
        _Spaced(8, message),
      ],
    ];

    // The order is the one the request had when it opened: what is ready
    // first, what still has to be added after it. A card that is added
    // stays where it was.
    final order = _orderOf(required, selections);
    final requiredLabel = isSignature
        ? t("share.section.with_signature")
        : t("share.section.you_share");
    final requestedPart = <_Spaced>[
      if (required.isNotEmpty) ...[
        _Spaced(24, _SectionLabel(requiredLabel)),
        for (final (i, p) in order)
          _requiredItem(i, p, selections, wallet: wallet),
      ],
      if (optional.isNotEmpty) ...[
        _Spaced(24, _SectionLabel(t("share.section.optional"))),
        for (final (i, p) in [
          ...optional.where((o) => selectionOf(o.$2, selections[o.$1]) >= 0),
          ...optional.where((o) => selectionOf(o.$2, selections[o.$1]) < 0),
        ])
          _optionalItem(i, p, selections),
      ],
      if (offered.isNotEmpty) ...[
        _Spaced(24, _SectionLabel(t("share.section.you_receive"))),
        for (final card in offered) _Spaced(8, _OfferedCard(card: card)),
      ],
    ];

    // Nobody vouches for the requestor: Share becomes "Share anyway", asks
    // once more, and says above it to share only if you trust them.
    final risky =
        trust.risky &&
        button.enabled &&
        button.label != ShareLabel.close &&
        button.label != ShareLabel.shareWithoutData;
    void share() {
      _captureForDone();
      widget.onShare(disclosureChoicesFor(pickOnes, selections));
    }

    final next = button.next;
    final verb = isSignature ? "_sign" : "";
    final notReady = button.ready.where((r) => !r).length;
    // The line under the parts: what is left, or that all is set; a card
    // that does not count in red. Why it can't be done in Yivi stands alone.
    final String? cannot = switch (button) {
      ShareButtonState(cannotAdd: final p?) =>
        _issuersOf(p).isEmpty
            ? t("share.reason.cant_add_unknown", {
                "name": _inSentence(_spotName(p)),
              })
            : t("share.reason.cant_add", {
                "name": _inSentence(_spotName(p)),
                "issuer": _issuersOf(p),
              }),
      ShareButtonState(cannotRenewFrom: final issuer?) => t(
        "share.reason.cant_renew",
        {"requestor": requestor, "issuer": issuer},
      ),
      _ => null,
    };
    final line = switch (button) {
      ShareButtonState(mismatch: _?) => t("share.progress.not_counted"),
      ShareButtonState(missing: _?) =>
        notReady == 1
            ? t("share.progress.add_one$verb")
            : t("share.progress.add_many$verb", {"count": "$notReady"}),
      ShareButtonState(blockedCard: _?) =>
        button.toDo == 1
            ? t("share.reason.fix_one")
            : t("share.reason.fix_many", {"count": "${button.toDo}"}),
      _ => t("share.progress.ready"),
    };
    final bar = _ShareBar(
      inBar: !landscape,
      parts: risky || cannot != null || button.ready.isEmpty
          ? null
          : (
              total: button.ready.length,
              filled: button.ready.length - notReady,
            ),
      line: risky || cannot != null ? null : line,
      warn: button.mismatch != null,
      reason: risky
          ? t(
              isSignature
                  ? "share.trust.risky.reason_sign"
                  : "share.trust.risky.reason",
              {"requestor": requestor},
            )
          : cannot,
      arriving: _arriving,
      isNext: next != null,
      decline: button.mismatch == null
          ? null
          : (label: t("share.trust.confirm.dont_share"), onTap: widget.onClose),
      label: next != null
          ? _nextLabel(next)
          : risky
          ? t(
              button.label == ShareLabel.signAndShare
                  ? "share.trust.risky.sign_anyway"
                  : "share.trust.risky.share_anyway",
            )
          : t("share.button.${_labelName(button.label)}"),
      primary: button.label != ShareLabel.close && !risky,
      risky: risky,
      onPressed: next != null
          ? () => _doNext(next)
          : !button.enabled
          ? null
          : button.label == ShareLabel.close
          ? widget.onClose
          : risky
          ? () async {
              if (await _confirmShareAnyway(requestor)) share();
            }
          : share,
    );

    // Held sideways, and on a tablet: the title, who asks and the button in
    // a panel at the left that stays put; what is shared scrolls at the
    // right, the message first.
    if (landscape || columns) {
      return SessionScaffold(
        appBarTitle: "share.bar.$kind",
        onDismiss: widget.onDismiss,
        wide: true,
        scrollsUnderBars: true,
        // The band is the right column's own (see _SidewaysCards).
        scrollEdge: false,
        cornerClose: true,
        body: _TrustWash(
          on: trust.risky,
          height: 300,
          child: Builder(
            builder: (context) {
              final top = sidewaysContentTop(context);
              return SidewaysLayout(
                panel: _LandscapePanel(
                  top: sidewaysPanelTop(context),
                  title: title,
                  card: card,
                  action: bar,
                ),
                content: _SidewaysCards(
                  top: top,
                  risky: trust.risky,
                  children: _laidOut([
                    ...messagePart,
                    ...requestedPart,
                  ], first: true),
                ),
              );
            },
          ),
        ),
      );
    }

    return SessionScaffold(
      appBarTitle: "share.bar.$kind",
      onDismiss: widget.onDismiss,
      scrollsUnderBars: true,
      bottomNavigationBar: bar,
      edgeColor: trust.risky ? palette.errorSurface : null,
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
                controller: _scroll,
                // Scrolls (and bounces) also when it all fits.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16 + insets.left,
                  16 + insets.top,
                  16 + insets.right,
                  16 + insets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _laidOut([
                    ...requestorPart,
                    ...messagePart,
                    ...requestedPart,
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Notes where the cards and the message are on screen, for the flight
  /// into the done screen (see [DoneFlight]).
  void _captureForDone() {
    final pickOnes = _pickOnes;
    final choices = ref.read(sessionUserChoicesProvider(_sessionId));
    final selections = selectionsFrom(
      pickOnes,
      choices.disclosureChoices,
      choices.addedOptionalIndices,
      preferred: ref.read(lastSharedBundlesProvider(_sessionId)),
    );
    DoneFlight.capture(
      context,
      messageKey: _messageKey,
      cards: [
        for (final (i, p) in pickOnes.indexed)
          if (selectionOf(p, selections[i]) case final k when k >= 0)
            if (_landingKeys[i] case final key?)
              for (final c in p.ownedOptions![k].credentials.take(1))
                (key, c.hash),
      ],
    );
  }

  /// The required items in the order they keep on this screen: as they
  /// were when it opened, the ready ones first and the ones to add after.
  List<(int, DisclosurePickOne)> _orderOf(
    List<(int, DisclosurePickOne)> required,
    Map<int, int> selections,
  ) {
    final ids = [for (final (i, _) in required) i];
    if (_order == null || !listEquals([..._order!]..sort(), ids)) {
      final ready = [
        for (final (i, p) in required)
          if (selectionOf(p, selections[i]) >= 0) i,
      ];
      _order = [...ready, ...ids.where((i) => !ready.contains(i))];
    }
    final byIndex = {for (final r in required) r.$1: r};
    return [for (final i in _order!) byIndex[i]!];
  }

  /// [items] with their gaps above them; the first item's gap is dropped
  /// when [first].
  /// Right under a section label the gap is 8: the label sits close to the
  /// cards it names.
  static List<Widget> _laidOut(List<_Spaced> items, {bool first = false}) => [
    for (final (n, item) in items.indexed) ...[
      if (!(first && n == 0) && item.gap > 0)
        SizedBox(
          height: n > 0 && items[n - 1].child is _SectionLabel ? 8 : item.gap,
        ),
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

  String _inSentence(String name) => inSentence(name, language: context.lang);

  static String _issuersOf(DisclosurePickOne p) => {
    for (final d in p.obtainableOptions ?? const <CredentialDescriptor>[])
      if (d.issuer.name.isNotEmpty) d.issuer.name,
  }.join(", ");

  /// "You can also choose another card" (or "add another card"), with
  /// "Change choice": the strip at the foot of a card with other choices.
  /// Null when there are none.
  Widget? _choiceStrip(int i, DisclosurePickOne p, int selected) {
    if (!canChange(p)) return null;
    final also = alsoChoice(p, selected);
    if (also == null) return null;
    return _ChoiceStrip(
      text: context.tr("share.also_${also.name}"),
      button: SmallPill(
        key: Key("share_change_$i"),
        label: context.tr("share.change_choice"),
        tone: SmallPillTone.surface,
        onPressed: () => _openSheet(i),
      ),
    );
  }

  /// A required item: its card, or the empty spot when it is not in the app.
  _Spaced _requiredItem(
    int i,
    DisclosurePickOne p,
    Map<int, int> selections, {
    required List<schemaless.Credential> wallet,
  }) {
    final k = selectionOf(p, selections[i]);
    final empty = k < 0;
    final mismatch = empty ? walletMismatch(p, wallet) : null;
    final child = mismatch != null
        ? _MismatchTile(
            key: Key("share_not_counted_$i"),
            mismatch: mismatch,
            landingKey: _landingKey(i),
            requestor: widget.session.requestor.name,
          )
        : empty
        ? _emptySpot(i, p)
        : _filledTile(i, p, k);
    return _Spaced(12, child);
  }

  /// A card that is not in the app yet. With one way to get it, Add goes
  /// straight to adding it; with more, to the choice in the sheet, and the
  /// spot shows the types as small cards.
  Widget _emptySpot(int i, DisclosurePickOne p) {
    final t = context.tr;
    final addable = addableOptions(p);
    final plan = widget.session.disclosurePlan?.issueDuringDisclosure;
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
              for (final (label, value, asked) in emptySpotRows(context, d))
                inApp.contains(d.credentialId)
                    ? (label, t("data.add.in_your_app"), false)
                    : (label, value, asked),
          ]
        : single == null
        ? const <SpotRow>[]
        : emptySpotRows(context, single);
    return EmptyCardSpot(
      key: Key("share_spot_$i"),
      rows: rows,
      // Where the added card flies to.
      landingKey: _landingKey(i),
      title: _spotName(p),
      subtitle: subtitle,
      kinds: several || together ? addable : null,
      together: together,
      descriptor: single ?? (missing.length == 1 ? missing.single : null),
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
      // One kind: straight to adding it. Several: the sheet with only the
      // kinds; a set: the sheet that adds them one by one.
      onTap: addable.isEmpty
          ? null
          : several
          ? () => _openSheet(i, kindsOnly: true)
          : () => _openSheet(i, addNew: single),
    );
  }

  Widget _filledTile(int i, DisclosurePickOne p, int k) {
    final bundle = p.ownedOptions![k];
    final problem = problemOfBundle(bundle);
    final isNew = addedDuringRequest(
      p,
      bundle,
      widget.session.disclosurePlan?.issueDuringDisclosure,
    );
    // A card that can't be used says so; the share button does the fix.
    final tile = _LandedRing(
      shown: _landed.contains(i),
      child: SharedCardTile(
        key: Key("share_slot_$i"),
        bundle: bundle,
        landingKey: _landingKey(i),
        isNew: isNew,
        problemStrip: true,
        footer: problem != null
            ? null
            : _choiceStrip(i, p, k) ?? _togetherStrip(bundle),
      ),
    );
    // Picked up into the Change sheet, and put down here again.
    return FlightSpot(flightKey: _tileKey(i), child: tile);
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
            style: CardTileStrip.textStyle(context),
          ),
        ),
      ],
    );
  }

  /// Optional data. Not shared: a row naming its kinds, "Not shared.
  /// {requestor} asks for it, but you don't have to.", with "Share", which
  /// opens the sheet ("Don't share" on top, the cards in the app, the ones
  /// to add; with none in the app, only the kinds). Shared: the card with
  /// all it shares and a strip with "Change choice".
  _Spaced _optionalItem(int i, DisclosurePickOne p, Map<int, int> selections) {
    final owned = p.ownedOptions ?? const <DisclosureBundle>[];
    final k = selectionOf(p, selections[i]);
    if (k < 0) {
      final kinds = optionalKinds(p);
      final addable = addableOptions(p);
      final one = addable.length == 1 && owned.isEmpty ? addable.single : null;
      return _Spaced(
        12,
        EmptyCardSpot(
          key: Key("share_add_optional_$i"),
          landingKey: _landingKey(i),
          title: orList(kinds, context.tr("share.or")),
          subtitle: one?.issuer.name ?? context.tr("share.spot.many"),
          descriptor: one,
          kinds: one == null && addable.length > 1 ? addable : null,
          strip: context.tr("share.optional.not_shared"),
          onTap: owned.isEmpty
              ? () => _openSheet(i, kindsOnly: true)
              : () => _openSheet(i),
        ),
      );
    }
    final bundle = owned[k];
    final tile = _LandedRing(
      shown: _landed.contains(i),
      child: SharedCardTile(
        key: Key("share_slot_$i"),
        bundle: bundle,
        landingKey: _landingKey(i),
        footer: _ChoiceStrip(
          text: context.tr("share.optional.also"),
          button: SmallPill(
            key: Key("share_change_$i"),
            label: context.tr("share.change_choice"),
            tone: SmallPillTone.surface,
            onPressed: () => _openSheet(i),
          ),
        ),
      ),
    );
    // A card picked for it in the sheet flies into its place, as a
    // required card does.
    return _Spaced(12, FlightSpot(flightKey: _tileKey(i), child: tile));
  }

  static String _labelName(ShareLabel l) => switch (l) {
    ShareLabel.share => "share",
    ShareLabel.signAndShare => "sign_and_share",
    ShareLabel.shareAndAdd => "share_and_add",
    ShareLabel.shareWithoutData => "share_without_data",
    ShareLabel.close => "close",
  };
}
