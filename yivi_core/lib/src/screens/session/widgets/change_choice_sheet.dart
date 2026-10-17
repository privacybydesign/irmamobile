import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../../data/irma_repository.dart";
import "../../../models/schemaless/credential_store.dart";
import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../models/schemaless/session_state.dart";
import "../../../models/schemaless/session_user_interaction.dart";
import "../../../providers/external_issuer_provider.dart";
import "../../../providers/irma_repository_provider.dart";
import "../../../providers/nested_issuance_host_provider.dart";
import "../../../providers/schemaless_credential_store_provider.dart";
import "../../../providers/session_state_provider.dart";
import "../../../providers/session_user_choices_provider.dart";
import "../../../theme/yivi_palette.dart";
import "../../../util/navigation.dart";
import "../../../widgets/credential_card/card_flight.dart";
import "../../../widgets/glass/glass_dialog.dart";
import "../../../widgets/glass/glass_sheet.dart";
import "../../../widgets/glass/glass_surface.dart";
import "../../../widgets/glass/pill_buttons.dart";
import "../../../widgets/glass/sheet_action_row.dart";
import "../../../widgets/loading_indicator.dart";
import "../../add_data/schemaless_add_data_details_screen.dart";
import "../../error/session_error_screen.dart";
import "../models/disclosure_view_model.dart";
import "issuance_permission.dart";
import "issuance_success_screen.dart";
import "issue_sheet_progress.dart";
import "session_pin_entry_screen.dart";
import "shared_card_tile.dart";

/// Sends the user to the issuer of a credential type: its website, or the
/// app's own flow for the types Yivi issues itself (e-mail, phone,
/// documents). A provider, so tests can see where the sheet sends the user.
final issuerOpenerProvider =
    Provider<
      Future<void> Function(
        BuildContext context,
        CredentialDescriptor descriptor,
        WidgetRef ref,
      )
    >(
      (ref) =>
          (context, d, widgetRef) => ref
              .read(irmaRepositoryProvider)
              .openIssueURL(context, d.credentialId, d.issueURL, widgetRef),
    );

/// The "Change" sheet of the share screen, for pick-one [index]: the cards
/// in the app (one tap picks one and closes the sheet) and, clearly apart,
/// the types that are not in the app yet.
///
/// Adding one of those happens in the sheet, in three steps under an
/// [IssueSheetProgress]: 1 its details (as on the add-data page), 2 the
/// issuer's website, from which the user comes back to the sheet, and 3 the
/// issuance itself ("Do you want to add this data?", then "Success").
/// "Back to {requestor}" then flies the new card into its spot on the share
/// screen ([landingKey]) as the sheet closes. Once adding has started, closing
/// the sheet asks first. Cards Yivi issues in its own screens (e-mail,
/// phone, documents) still open those, with the sheet closed.
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
  heightFraction: 0.9,
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
    implements NestedIssuanceHost {
  /// The type the user is adding; null while choosing.
  late CredentialDescriptor? _adding = widget.addNew;

  /// The issuer's website was opened for [_adding].
  bool _opened = false;

  /// The issuance that came back from the issuer, shown in the sheet.
  int? _nestedId;

  /// The cards of a finished issuance, kept for "Success" (the session state
  /// moves on once the request picks them up).
  List<schemaless.Credential>? _added;
  List<GlobalKey> _addedKeys = const [];

  /// A full-screen page shown over the sheet for the issuance (PIN, error).
  bool _overSheet = false;

  // The repository only once something is added, kept for dispose (where
  // ref is unsafe). The host notifier up front for the same reason.
  IrmaRepository? _repoRead;
  IrmaRepository get _repo {
    final read = _repoRead;
    if (read != null) return read;
    final repo = ref.read(irmaRepositoryProvider);
    _repoRead = repo;
    return repo;
  }

  late final NestedIssuanceHostNotifier _hosts;

  @override
  void initState() {
    super.initState();
    _hosts = ref.read(nestedIssuanceHostProvider.notifier);
  }

  @override
  int get underlyingSessionId => widget.sessionId;

  @override
  void attach(int sessionId) {
    if (!mounted) return;
    final previous = _nestedId;
    if (previous != null && previous != sessionId) _dismissNested(previous);
    setState(() {
      _nestedId = sessionId;
      _added = null;
    });
  }

  @override
  void dispose() {
    _hosts.unregister(this);
    final nested = _nestedId;
    // A nested id means the repository was read (the website was opened).
    if (nested != null && _added == null) {
      _repoRead?.bridgedDispatch(
        SessionUserInteractionEvent.dismiss(sessionId: nested),
      );
    }
    super.dispose();
  }

  /// Adding has started: closing asks first.
  bool get _started => _adding != null && _added == null;

  SessionUserChoicesNotifier get _choices =>
      ref.read(sessionUserChoicesProvider(widget.sessionId).notifier);

  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  String _inSentence(String name) => inSentence(
    name,
    language: FlutterI18n.currentLocale(context)?.languageCode,
  );

  void _openAdd(CredentialDescriptor d) => setState(() {
    _adding = d;
    _opened = false;
  });

  /// Back from the details to the choice, leaving nothing behind.
  void _backToChoice() {
    _stopAdding();
    setState(() => _adding = null);
  }

  /// Ends what adding left running: the issuance, the waiting host, the
  /// launch record.
  void _stopAdding() {
    final nested = _nestedId;
    if (nested != null && _added == null) _dismissNested(nested);
    _hosts.unregister(this);
    if (_opened) _repo.clearInAppLaunches();
    _nestedId = null;
    _added = null;
    _opened = false;
  }

  void _dismissNested(int sessionId) => _repo.bridgedDispatch(
    SessionUserInteractionEvent.dismiss(sessionId: sessionId),
  );

  void _pick(DisclosurePickOne pickOne, DisclosureBundle bundle) {
    if (pickOne.optional) _choices.addOptional(widget.index);
    _choices.setBundle(widget.index, bundle);
    Navigator.of(context).pop();
  }

  /// "Add" on the details: the issuer's website, with the sheet waiting for
  /// what comes back. A card Yivi issues in its own screens opens those, from
  /// the page behind the sheet, as before.
  Future<void> _add(DisclosurePickOne pickOne, CredentialDescriptor d) async {
    if (pickOne.optional) _choices.includeOptionalWhenAdded(widget.index);
    final open = ref.read(issuerOpenerProvider);
    if (_repo.hasEmbeddedFlow(d.credentialId)) {
      final navigator = Navigator.of(context);
      final pageContext = navigator.context;
      navigator.pop();
      await open(pageContext, d, ref);
      return;
    }
    _hosts.register(this);
    setState(() => _opened = true);
    await open(context, d, ref);
  }

  /// "Stop adding {name}?" before a started adding is left.
  Future<bool> _confirmStop() async {
    final d = _adding;
    if (d == null || !_started) return true;
    final requestor = ref
        .read(sessionStateProvider(widget.sessionId))
        .value
        ?.requestor;
    final stop =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => GlassDialog(
            cardKey: const Key("sheet_stop_dialog"),
            title: _t("share.sheet.stop_title", {"name": _inSentence(d.name)}),
            message: _t("share.sheet.stop_text", {
              "requestor": requestor?.name ?? "",
            }),
            actions: [
              PillButton(
                key: const Key("sheet_stop_confirm"),
                label: _t("share.sheet.stop_confirm"),
                style: PillStyle.dangerFilled,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              PillButton(
                key: const Key("sheet_stop_keep"),
                label: _t("share.sheet.keep_going"),
                style: PillStyle.text,
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ) ??
        false;
    if (stop) _stopAdding();
    return stop;
  }

  /// Cancel on a step: asks, then back to the choice.
  Future<void> _cancel() async {
    if (await _confirmStop() && mounted) setState(() => _adding = null);
  }

  // ---------- the issuance in the sheet ----------

  void _onNested(SessionState? previous, SessionState next) {
    final status = next.status;
    if (status == SessionStatus.success) {
      // Kept: the request picks the cards up and the state moves on.
      final cards = next.offeredCredentials ?? const [];
      _repo.clearInAppLaunches();
      _hosts.unregister(this);
      setState(() {
        _added = cards;
        _addedKeys = [
          for (final (i, _) in cards.indexed)
            GlobalKey(debugLabel: "sheet_added_$i"),
        ];
      });
      return;
    }
    if (status == SessionStatus.dismissed) {
      // Cancelled on the permission: back on the details, to try again.
      setState(() => _nestedId = null);
      return;
    }
    if (status == previous?.status || _overSheet) return;
    if (status == SessionStatus.requestPin) {
      _showOverSheet((_) => _NestedPin(sessionId: next.id));
    } else if (status == SessionStatus.error) {
      _showOverSheet(
        (context) => SessionErrorScreen(
          error: next.error,
          onTapClose: () => Navigator.of(context).pop(),
        ),
        then: () {
          if (mounted) setState(() => _nestedId = null);
        },
      );
    } else if (!_handledInSheet(next)) {
      // Anything else (a pairing code, an OpenID4VCI code, a request instead
      // of an issuance) takes the session screen, as without the sheet.
      final id = next.id;
      setState(() => _nestedId = null);
      context.pushSessionScreen(
        SessionRouteParams(sessionId: id, hasUnderlyingSession: true),
      );
    }
  }

  bool _handledInSheet(SessionState s) =>
      s.status == SessionStatus.requestPermission &&
      s.type == SessionType.issuance &&
      s.offeredCredentials != null &&
      (s.disclosurePlan?.disclosureChoicesOverview?.isEmpty ?? true);

  void _showOverSheet(WidgetBuilder builder, {VoidCallback? then}) {
    _overSheet = true;
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<void>(builder: builder)).whenComplete(() {
      _overSheet = false;
      then?.call();
    });
  }

  void _grant(int sessionId) => _repo.bridgedDispatch(
    SessionUserInteractionEvent.permission(
      sessionId: sessionId,
      granted: true,
      disclosureChoices: const [],
    ),
  );

  /// "Back to {requestor}": the new card flies into its spot as the sheet
  /// closes. Without a spot to fly to, or for a card of another type than
  /// the one being added (an issuance that happened to come in meanwhile),
  /// the sheet just closes.
  void _finish() {
    final cards = _added ?? const <schemaless.Credential>[];
    final landing = widget.landingKey;
    final i = cards.indexWhere((c) => c.credentialId == _adding?.credentialId);
    if (landing != null && i >= 0) {
      CardFlight.start(
        context,
        source: _addedKeys[i],
        card: cards[i],
        landingKey: landing,
        cardKey: const Key("sheet_flight_card"),
        target: (overlay, {required first}) =>
            CardFlight.rectOf(landing, overlay),
      );
    }
    _added = null;
    _adding = null;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // The plan changes while the sheet is open when a card is added.
    final session = ref.watch(sessionStateProvider(widget.sessionId)).value;
    final pickOnes =
        session?.disclosurePlan?.disclosureChoicesOverview ?? const [];
    final nested = _nestedId;
    if (nested != null) {
      ref.listen(sessionStateProvider(nested), (prev, next) {
        if (next.value case final state?) _onNested(prev?.value, state);
      });
    }
    if (widget.index >= pickOnes.length || session == null) {
      return const SizedBox.shrink();
    }
    final pickOne = pickOnes[widget.index];
    final adding = _adding;
    // "Add …" and its steps are subpages inside the sheet, as in a native
    // iOS sheet.
    return GlassSheetConfirmDismiss(
      ask: _started,
      confirm: _confirmStop,
      child: GlassSheetPages(
        onBack: () {
          if (_nestedId != null && _added == null) {
            _dismissNested(_nestedId!);
            setState(() => _nestedId = null);
          } else {
            _backToChoice();
          }
        },
        pages: [
          KeyedSubtree(
            key: const ValueKey("choose"),
            child: _buildChoose(pickOne),
          ),
          if (adding != null)
            KeyedSubtree(
              key: ValueKey(("add", adding.credentialId)),
              child: _buildDetails(session, pickOne, adding),
            ),
          if (adding != null && (nested != null || _added != null))
            KeyedSubtree(
              key: ValueKey(("issue", nested)),
              child: _buildIssuance(session, nested),
            ),
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
            _Group(
              children: [
                for (final d in addable)
                  _AddRow(
                    key: Key("sheet_add_${d.credentialId}"),
                    name: owned.any((b) => _nameOf(b) == d.name)
                        ? _t("share.sheet.another", {
                            "name": _inSentence(d.name),
                          })
                        : d.name,
                    subtitle: _t("share.sheet.on_host", {
                      "issuer": d.issuer.name,
                      "host": hostOf(d.issueURL)!,
                    }),
                    onTap: () => _openAdd(d),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Step 1 (and 2, while the website is open): what the card is, as on
  /// the add-data page.
  Widget _buildDetails(
    SessionState session,
    DisclosurePickOne pickOne,
    CredentialDescriptor d,
  ) {
    final palette = YiviPalette.of(context);
    final host = hostOf(d.issueURL) ?? "";
    final faq = _faqFor(d.credentialId);
    return GlassSheetPage(
      title: _t("data.add.details.title"),
      onBack: () async {
        if (!_opened || await _confirmStop()) _backToChoice();
      },
      padding: const EdgeInsets.symmetric(horizontal: 16),
      bottom: SheetActionRow(
        secondaryKey: const Key("sheet_cancel_button"),
        secondaryLabel: _t("data.add.details.back_button"),
        onSecondary: _cancel,
        primaryKey: const Key("sheet_go_button"),
        // The note above says which website.
        primaryLabel: _opened
            ? _t("share.sheet.open_again")
            : _t("data.add.details.get_button"),
        onPrimary: () => _add(pickOne, d),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          IssueSheetProgress(
            requestor: session.requestor,
            step: _opened ? 2 : 1,
          ),
          if (_opened)
            Container(
              key: const Key("sheet_opened_note"),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: ShapeDecoration(
                color: palette.infoSurface,
                shape: const RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
              child: Text(
                _t("share.sheet.opened_note", {"host": host}),
                style: palette
                    .body(14)
                    .copyWith(height: 20 / 14, color: palette.noteText),
              ),
            ),
          AddDataDetailsContent(credential: d, faq: faq, inDisclosure: true),
        ],
      ),
    );
  }

  Faq? _faqFor(String credentialId) {
    final store = ref.watch(groupedCredentialStoreProvider).value;
    for (final group in store ?? const <CredentialStoreCategory>[]) {
      for (final item in group.items) {
        if (item.credential.credentialId == credentialId) return item.faq;
      }
    }
    return null;
  }

  /// Step 3: the issuance that came back, then "Success".
  Widget _buildIssuance(SessionState request, int? nestedId) {
    final added = _added;
    if (added != null) return _buildSuccess(request, added);

    final state = nestedId == null
        ? null
        : ref.watch(sessionStateProvider(nestedId)).value;
    final awaiting =
        nestedId != null &&
        ref.watch(sessionAwaitingInteractionProvider(nestedId));
    final offer = state != null && _handledInSheet(state) && !awaiting
        ? state
        : null;
    final cards = offer?.offeredCredentials ?? const <schemaless.Credential>[];

    return GlassSheetPage(
      title: _t("issuance.title"),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      bottom: SheetActionRow(
        secondaryKey: const Key("sheet_issue_cancel"),
        secondaryLabel: _t("issuance.cancel"),
        onSecondary: () {
          if (nestedId != null) _dismissNested(nestedId);
        },
        primaryKey: const Key("sheet_issue_add"),
        primaryLabel: cards.length > 1
            ? _t("issuance.add_many", {"count": "${cards.length}"})
            : _t("issuance.add"),
        onPrimary: offer == null || nestedId == null
            ? null
            : () => _grant(nestedId),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          IssueSheetProgress(requestor: request.requestor, step: 3),
          if (offer == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Center(child: LoadingIndicator()),
            )
          else
            KeyedSubtree(
              key: const Key("sheet_issuance"),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: _offer(offer, request),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _offer(SessionState offer, SessionState request) {
    final palette = YiviPalette.of(context);
    final cards = offer.offeredCredentials!;
    final returned = _opened && cards.any((c) => _launched(c.credentialId))
        ? cards.first.issuer.name
        : null;
    final content = IssuanceOffer(
      cards: cards,
      forRequest: request,
      returnedFromIssuer: returned,
      showRequestChip: false,
    );
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Semantics(
          header: true,
          child: Text(
            cards.length > 1
                ? _t("issuance.question_many", {"count": "${cards.length}"})
                : _t("issuance.description"),
            style: palette
                .display(22)
                .copyWith(height: 30 / 22, color: palette.heading),
          ),
        ),
      ),
      ...content.overview(context, cardWidth: 358),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content.receives(context),
      ),
    ];
  }

  bool _launched(String credentialId) =>
      ref
          .watch(websiteLaunchedCredentialsProvider)
          .value
          ?.contains(credentialId) ??
      false;

  Widget _buildSuccess(
    SessionState request,
    List<schemaless.Credential> cards,
  ) {
    final palette = YiviPalette.of(context);
    final params = {
      "name": cards.firstOrNull?.name ?? "",
      "count": "${cards.length}",
      "requestor": request.requestor.name,
    };
    // The bar keeps the step's title; "Success" is the heading below.
    return GlassSheetPage(
      title: _t("issuance.title"),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      bottom: SheetActionRow(
        primaryKey: const Key("sheet_back_to_request"),
        primaryLabel: _t("issuance.success_feedback.back_to", params),
        onPrimary: _finish,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          IssueSheetProgress(requestor: request.requestor, step: 3, done: true),
          if (cards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: IssuanceReceived(cards: cards, cardKeys: _addedKeys),
            ),
          Text(
            _t("issuance.success_feedback.header"),
            textAlign: TextAlign.center,
            style: palette
                .display(26, weight: FontWeight.w700)
                .copyWith(color: palette.heading),
          ),
          Text(
            _t(
              cards.length > 1
                  ? "issuance.success_feedback.added_many_back"
                  : "issuance.success_feedback.added_one_back",
              params,
            ),
            key: const Key("sheet_added_text"),
            textAlign: TextAlign.center,
            style: palette.body(16).copyWith(height: 24 / 16),
          ),
        ],
      ),
    );
  }

  static String _nameOf(DisclosureBundle b) =>
      b.credentials.map((c) => c.name).join(" + ");
}

/// The PIN for an issuance in the sheet, full-screen over it, as for any
/// session. It goes away once the PIN is accepted (or the session ends).
class _NestedPin extends ConsumerStatefulWidget {
  final int sessionId;

  const _NestedPin({required this.sessionId});

  @override
  ConsumerState<_NestedPin> createState() => _NestedPinState();
}

class _NestedPinState extends ConsumerState<_NestedPin> {
  late final _repo = ref.read(irmaRepositoryProvider);
  bool _closed = false;
  bool _longPin = false;

  @override
  void initState() {
    super.initState();
    _repo.preferences.getLongPin().first.then((value) {
      if (mounted) setState(() => _longPin = value);
    });
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionStateProvider(widget.sessionId)).value;
    final awaiting = ref.watch(
      sessionAwaitingInteractionProvider(widget.sessionId),
    );
    if (state != null && state.status != SessionStatus.requestPin) _close();
    return SessionPinEntryScreen(
      title: "issuance.title",
      remainingAttempts: state?.remainingPinAttempts,
      blockedTimeSeconds: state?.pinBlockedTimeSeconds,
      submitting: awaiting,
      maxPinSize: _longPin ? 16 : 5,
      onPinEntered: (pin) => _repo.bridgedDispatch(
        SessionUserInteractionEvent.pin(
          sessionId: widget.sessionId,
          pin: pin,
          proceed: true,
        ),
      ),
      onCancel: () => _repo.bridgedDispatch(
        SessionUserInteractionEvent.dismiss(sessionId: widget.sessionId),
      ),
    );
  }
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

/// White rounded group of rows, with lines between them.
class _Group extends StatelessWidget {
  final List<Widget> children;

  const _Group({required this.children});

  static const padding = EdgeInsets.symmetric(horizontal: 14);

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: palette.surface,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: palette.divider),
              child,
            ],
          ],
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

/// A type that is not in the app yet: tap to see where it is added.
class _AddRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _AddRow({
    super.key,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
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
                      name,
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
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: palette.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
