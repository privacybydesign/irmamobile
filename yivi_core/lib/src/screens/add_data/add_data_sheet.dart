import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../models/schemaless/session_state.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/nfc_availability_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credential_store_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/nfc_credentials.dart";
import "../../widgets/credential_card/credential_type_thumbnail.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/glass_sheet.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../../widgets/glass/sheet_action_row.dart";
import "../../widgets/irma_dialog.dart";
import "../data/wallet/issuance_flight.dart";
import "../session/widgets/issue_flow.dart";
import "../session/widgets/issue_sheet_progress.dart";

/// Opens Add data: a sheet over the Data tab with every type of card the
/// user can add, and the whole of adding one inside it ([AddDataSheet]).
/// With [addNew] it opens straight on the details of that type. Without
/// [flyToDataTab] (opened from elsewhere than the Data tab), "Done" only
/// closes it.
Future<void> showAddDataSheet(
  BuildContext context, {
  CredentialDescriptor? addNew,
  bool flyToDataTab = true,
}) => showGlassSheet<void>(
  context: context,
  builder: (_) => AddDataSheet(
    key: const Key("add_data_sheet"),
    addNew: addNew,
    flyToDataTab: flyToDataTab,
  ),
);

/// "Get again" for a card in the app: the Add data sheet, straight on the
/// details of its type ([credentialId]). The type is looked up in the
/// credential store, or else described by the [card] itself. Without an
/// issue URL there is nothing to add it from in the sheet, and the issuer is
/// opened as before.
Future<void> obtainAgain(
  BuildContext context,
  WidgetRef ref, {
  required String credentialId,
  required String? issueUrl,
  schemaless.Credential? card,
}) async {
  if (issueUrl == null || issueUrl.isEmpty) {
    return ref
        .read(irmaRepositoryProvider)
        .openIssueURL(context, credentialId, issueUrl, ref);
  }
  // Listened to while waiting, so the store stays loaded until it is there.
  final subscription = ProviderScope.containerOf(
    context,
    listen: false,
  ).listen(groupedCredentialStoreProvider.future, (_, _) {});
  List<CredentialStoreCategory>? store;
  try {
    store = await subscription.read();
  } catch (_) {
    // Without the store, the card describes its type.
  } finally {
    subscription.close();
  }
  if (!context.mounted) return;
  CredentialDescriptor? descriptor;
  for (final group in store ?? const <CredentialStoreCategory>[]) {
    for (final item in group.items) {
      if (item.credential.credentialId == credentialId) {
        descriptor = item.credential;
      }
    }
  }
  descriptor ??= card == null
      ? null
      : CredentialDescriptor(
          credentialId: credentialId,
          name: card.name,
          issuer: card.issuer,
          category: null,
          image: card.image,
          attributes: const [],
          issueURL: issueUrl,
        );
  if (descriptor == null) {
    return ref
        .read(irmaRepositoryProvider)
        .openIssueURL(context, credentialId, issueUrl, ref);
  }
  return showAddDataSheet(context, addNew: descriptor, flyToDataTab: false);
}

/// Add data as a sheet. Its root page is the list of what can be added, by
/// category, with a search field under the bar. Tapping a type adds it in
/// the sheet, with the same steps as adding a card during a request
/// ([IssueFlow]): its details, proving it, the issuance. "Success" then
/// offers "Add more", back to the list, and "Done", which closes the sheet.
class AddDataSheet extends ConsumerStatefulWidget {
  final CredentialDescriptor? addNew;

  /// "Done" flies the new card into the Data tab, which is under the sheet.
  final bool flyToDataTab;

  const AddDataSheet({super.key, this.addNew, this.flyToDataTab = true});

  @override
  ConsumerState<AddDataSheet> createState() => _AddDataSheetState();
}

class _AddDataSheetState extends ConsumerState<AddDataSheet>
    with IssueFlow<AddDataSheet> {
  /// The name of the card just added with "Add more", noted on the list.
  String? _justAdded;

  /// The list page, kept as one widget: the flow's changes (an issuance,
  /// the PIN, a website opened) rebuild this State, not the list.
  Widget? _listPage;
  String? _listPageFor;

  /// What is typed in the search field. Kept here, not on the list page:
  /// a step further than the details drops the list page, and coming back
  /// to it the search is still there.
  final _search = TextEditingController();

  Widget get _list {
    if (_listPage == null || _listPageFor != _justAdded) {
      _listPageFor = _justAdded;
      _listPage = _AddDataListPage(
        justAdded: _justAdded,
        search: _search,
        onOpen: _open,
      );
    }
    return _listPage!;
  }

  @override
  void initState() {
    super.initState();
    issueStartWith(widget.addNew);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  // ---------- the flow, without a request ----------

  @override
  int? get underlyingSessionId => null;

  @override
  SessionState? get issueRequest => null;

  @override
  IssueSheetSubject issueSubject(CredentialDescriptor d) =>
      IssueSheetSubject.card(d);

  @override
  String issueStopText() => _t("data.add.stop_text");

  Map<String, String> _params(List<schemaless.Credential> cards) => {
    "name": cards.firstOrNull?.name ?? "",
    "count": "${cards.length}",
  };

  @override
  String issueSuccessText(List<schemaless.Credential> cards) => _t(
    cards.length > 1
        ? "issuance.success_feedback.added_many"
        : "issuance.success_feedback.added_one",
    _params(cards),
  );

  @override
  Widget issueSuccessBar(List<schemaless.Credential> cards) => SheetActionRow(
    secondaryKey: const Key("sheet_add_more"),
    secondaryLabel: _t("data.add.add_more"),
    onSecondary: _addMore,
    primaryKey: const Key("sheet_done"),
    primaryLabel: _t("data.add.done"),
    onPrimary: _done,
  );

  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  /// "Add more": the card is in the app already; back to the list, which
  /// says so.
  void _addMore() {
    final cards = issueAdded ?? const <schemaless.Credential>[];
    setState(() {
      _justAdded = cards.length == 1 ? cards.single.name : null;
      issueShowRoot();
    });
  }

  /// "Done": the sheet closes on the Data tab while the new card flies from
  /// "Success" into the first slot. Where the data tab has a detail pane
  /// (tablet, landscape), the card opens in the pane instead.
  void _done() {
    final cards = issueAdded ?? const <schemaless.Credential>[];
    if (!widget.flyToDataTab) {
      // Opened over another page: the card is in the app, nothing flies.
    } else if (useHomePanes(context)) {
      final wallet = ref
          .read(schemalessCredentialOrderControllerProvider)
          .value;
      final first = wallet?.firstOrNull;
      if (first != null &&
          cards.any((c) => c.credentialId == first.credentialId)) {
        ref.read(selectedCardProvider.notifier).select(first.hash);
      }
    } else {
      IssuanceFlight.startFirstOf(
        context,
        received: cards,
        sources: issueAddedKeys,
        curtain: false,
      );
    }
    issueReset();
    Navigator.of(context).pop();
  }

  // ---------- the list ----------

  /// Explains that the credential cannot be loaded because the device has
  /// no NFC hardware.
  void _showNfcUnsupportedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => IrmaDialog(
        icon: const ToneDisc(icon: Icons.nfc_rounded, tone: DialogTone.warning),
        title: FlutterI18n.translate(context, "data.add.nfc_unsupported.title"),
        content: FlutterI18n.translate(
          context,
          "data.add.nfc_unsupported.body",
        ),
        child: FancyPillButton(
          label: FlutterI18n.translate(context, "error.button_ok"),
          size: PillSize.regular,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _open(CredentialStoreItem item, {required bool nfcBlocked}) {
    if (nfcBlocked) {
      _showNfcUnsupportedDialog();
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _justAdded = null);
    issueOpen(item.credential);
  }

  @override
  Widget build(BuildContext context) {
    issueListen();
    return GlassSheetConfirmDismiss(
      ask: issueStarted,
      confirm: issueConfirmStop,
      child: GlassSheetPages(
        onBack: issueBack,
        pages: [
          // Opened on one card: its details are the first page.
          if (!issueDirect || issueAdding == null)
            KeyedSubtree(key: const ValueKey("list"), child: _list),
          ...issueFlowPages(),
        ],
      ),
    );
  }
}

/// The root page of Add data: what can be added, by category. Its own
/// widget, so typing rebuilds only the list, and the rows are built as they
/// scroll into view.
///
/// The search field is the first thing in the list and scrolls away with
/// it; once it has, a narrower field takes the title's place in the bar,
/// next to the close button (docs/add-data-simpler-plan.md, 4.3). Both
/// share one text. Once typed in, the bar's field stays until it is empty,
/// unfocused and the list is back at its top, so it never jumps while the
/// results change.
class _AddDataListPage extends ConsumerStatefulWidget {
  /// The name of the card just added with "Add more", noted at the top.
  final String? justAdded;

  /// The search, owned by the sheet so it outlives this page.
  final TextEditingController search;
  final void Function(CredentialStoreItem item, {required bool nfcBlocked})
  onOpen;

  const _AddDataListPage({
    required this.justAdded,
    required this.search,
    required this.onOpen,
  });

  @override
  ConsumerState<_AddDataListPage> createState() => _AddDataListPageState();
}

class _AddDataListPageState extends ConsumerState<_AddDataListPage> {
  late String _query = widget.search.text;

  TextEditingController get _search => widget.search;
  final _listFocus = FocusNode();
  final _barFocus = FocusNode();

  /// The list's field has scrolled out from under the bar.
  bool _pastField = false;

  /// The field is in the bar.
  bool _inBar = false;

  /// How far the list scrolls before its field is gone: the field and the
  /// gap under it.
  static const _fieldHeight = 44.0;
  static const _fieldGap = 12.0;

  @override
  void initState() {
    super.initState();
    _barFocus.addListener(_place);
  }

  @override
  void dispose() {
    _barFocus.removeListener(_place);
    _listFocus.dispose();
    _barFocus.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final past =
        n.metrics.pixels - n.metrics.minScrollExtent >
        _fieldHeight + _fieldGap / 2;
    if (past != _pastField) {
      _pastField = past;
      _place();
    }
    return false;
  }

  /// Where the field is: in the bar once scrolled past, and held there while
  /// it is in use.
  void _place() {
    final inUse = _barFocus.hasFocus || _search.text.isNotEmpty;
    final inBar = _pastField || (_inBar && inUse);
    if (inBar == _inBar || !mounted) return;
    // Typing in the list's field and scrolling on: go on in the bar.
    final carryFocus = inBar && _listFocus.hasFocus;
    setState(() => _inBar = inBar);
    if (carryFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _barFocus.requestFocus();
      });
    }
  }

  void _onQuery(String q) {
    setState(() => _query = q);
    _place();
  }

  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

  bool _matches(CredentialStoreItem item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final credential = item.credential;
    return credential.name.toLowerCase().contains(query) ||
        credential.issuer.name.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final storeItems = ref.watch(groupedCredentialStoreProvider);
    final owned = {
      for (final c
          in ref.watch(schemalessCredentialOrderControllerProvider).value ??
              const <schemaless.Credential>[])
        c.credentialId,
    };

    // Treat the device as NFC-capable while the check is loading or if it
    // fails: greying out a credential the user can actually obtain is worse
    // than showing it normally. Only a confirmed "no NFC chip" result greys
    // out the NFC-requiring credentials.
    final nfcAvailable = ref.watch(nfcAvailableProvider).value ?? true;

    String title(CredentialStoreCategory group) => switch (group.source) {
      CredentialStoreSource.staging => _t("data.add.staging"),
      CredentialStoreSource.demo => _t("data.add.demo"),
      _ => group.category,
    };

    final landscape = usePhoneLandscape(context);
    Widget row(CredentialStoreItem item) {
      final blocked =
          !nfcAvailable && credentialRequiresNfc(item.credential.credentialId);
      return AddDataRow(
        item: item,
        nfcBlocked: blocked,
        owned: owned.contains(item.credential.credentialId),
        onTap: () => widget.onOpen(item, nfcBlocked: blocked),
      );
    }

    final List<Widget> body = switch (storeItems) {
      AsyncLoading() => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      AsyncError(error: final error) => [
        SliverToBoxAdapter(
          child: Text(
            error.toString(),
            style: palette.body(14).copyWith(color: palette.danger),
          ),
        ),
      ],
      AsyncData(value: final value) => () {
        final groups = [
          for (final group in value)
            (group, group.items.where(_matches).toList()),
        ].where((g) => g.$2.isNotEmpty).toList();
        return [
          if (groups.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  _t("data.add.no_results", {"query": _query.trim()}),
                  textAlign: TextAlign.center,
                  style: palette.body(16).copyWith(color: palette.heading),
                ),
              ),
            ),
          // A phone held sideways: each type a card of its own, two side by
          // side, under the category's name.
          if (landscape)
            for (final (group, items) in groups)
              SliverMainAxisGroup(
                slivers: [
                  if (title(group).isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                        child: Semantics(
                          header: true,
                          child: Text(title(group), style: palette.display(15)),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 12),
                    sliver: SliverList.builder(
                      itemCount: (items.length + 1) ~/ 2,
                      itemBuilder: (context, r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 8,
                            children: [
                              for (final i in [2 * r, 2 * r + 1])
                                Expanded(
                                  child: i < items.length
                                      ? _card(row(items[i]))
                                      : const SizedBox.shrink(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
          else
            for (final (group, items) in groups)
              SliverGlassGroup(
                // A credential without a category (irmago marshals it
                // `omitempty`) gets no header.
                header: title(group).isEmpty ? null : title(group),
                dividerIndent: AddDataRow.dividerIndent,
                itemCount: items.length,
                itemBuilder: (context, i) => row(items[i]),
              ),
        ];
      }(),
    };

    final justAdded = widget.justAdded;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: GlassSheetPage(
        title: _t("data.add.title"),
        // Sideways the search field is in the bar from the start, next to
        // the title.
        titleWidget: _inBar || landscape
            ? GlassSearchField(
                fieldKey: const Key("add_data_search_bar"),
                hintKey: "data.add.search",
                controller: _search,
                focusNode: _barFocus,
                height: 40,
                onChanged: _onQuery,
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        slivers: [
          if (!landscape)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: _fieldGap),
              // Never two fields: while the field is in the bar (scrolled
              // down, or searching from there and the list jumped back up)
              // the list's own field keeps its room but isn't there.
              sliver: SliverToBoxAdapter(
                child: Visibility(
                  visible: !_inBar,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: GlassSearchField(
                    fieldKey: const Key("add_data_search"),
                    hintKey: "data.add.search",
                    controller: _search,
                    focusNode: _listFocus,
                    height: _fieldHeight,
                    onChanged: _onQuery,
                  ),
                ),
              ),
            ),
          if (justAdded != null)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverToBoxAdapter(
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    key: const Key("add_data_added_note"),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: ShapeDecoration(
                      color: palette.successSurface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
                      ),
                    ),
                    child: Row(
                      spacing: 8,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: palette.successText,
                        ),
                        Expanded(
                          child: Text(
                            _t("data.add.added_more", {"name": justAdded}),
                            style: palette
                                .body(14, weight: FontWeight.w600)
                                .copyWith(color: palette.successText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ...body,
        ],
      ),
    );
  }

  /// A row of the list as a card of its own (the list sideways).
  Widget _card(Widget row) {
    final palette = YiviPalette.of(context);
    return Material(
      color: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(YiviCorners.card)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: row),
    );
  }
}

/// One credential type to add: its card, small (with a check when the user
/// has one already, [owned]), its name, and the issuer, after "Needs NFC"
/// for documents. Greyed out when it needs NFC the device lacks.
class AddDataRow extends StatelessWidget {
  final CredentialStoreItem item;

  /// Needs NFC the device does not have: greyed out, with the reason under
  /// the name and as a screen-reader hint.
  final bool nfcBlocked;

  /// The user has a card of this type already.
  final bool owned;
  final VoidCallback onTap;

  const AddDataRow({
    super.key,
    required this.item,
    required this.nfcBlocked,
    this.owned = false,
    required this.onTap,
  });

  /// Where a divider between rows starts: past the card.
  static const dividerIndent = 14.0 + 56 + 14;

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    String t(String key) => FlutterI18n.translate(context, key);
    final credential = item.credential;
    final needsNfc = credentialRequiresNfc(credential.credentialId);
    final subtitle = nfcBlocked
        ? t("data.add.nfc_unsupported.hint")
        : needsNfc
        // First, so a long issuer can't cut it off.
        ? "${t("data.add.needs_nfc")} · ${credential.issuer.name}"
        : credential.issuer.name;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: [
        credential.name,
        subtitle,
        if (owned && !nfcBlocked) t("data.add.in_your_app"),
      ].join(", "),
      onTap: onTap,
      child: Opacity(
        opacity: nfcBlocked ? 0.5 : 1,
        child: InkWell(
          key: Key("${credential.credentialId}_tile"),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: Row(
                spacing: 14,
                children: [
                  CredentialTypeThumbnail(
                    descriptor: credential,
                    owned: owned && !nfcBlocked,
                    greyedOut: nfcBlocked,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential.name,
                          style: palette
                              .display(15.5)
                              .copyWith(height: 21 / 15.5, color: palette.text),
                        ),
                        Text(
                          subtitle,
                          key: Key("${credential.credentialId}_subtitle"),
                          maxLines: nfcBlocked ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette
                              .body(13)
                              .copyWith(color: palette.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: palette.faint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
