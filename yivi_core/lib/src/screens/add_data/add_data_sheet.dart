import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../models/schemaless/credential_store.dart";
import "../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../providers/credentials_search.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/nfc_availability_provider.dart";
import "../../providers/pane_selection_provider.dart";
import "../../providers/schemaless_credential_store_provider.dart";
import "../../providers/schemaless_credentials_list_provider.dart";
import "../../theme/yivi_corners.dart";
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/after_frame.dart";
import "../../util/i18n.dart";
import "../../util/nfc_credentials.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/glass_sheet.dart";
import "../../widgets/glass/pill_buttons.dart";
import "../data/wallet/issuance_flight.dart";
import "../home/widgets/home_tab_top.dart";
import "../session/widgets/issue_flow.dart";
import "add_data_row.dart";

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
          isSingleton: card.isSingleton,
        );
  if (descriptor == null) {
    return ref
        .read(irmaRepositoryProvider)
        .openIssueURL(context, credentialId, issueUrl, ref);
  }
  return showAddDataSheet(context, addNew: descriptor, flyToDataTab: false);
}

/// Add data as a sheet. Its root page is the list of what can be added, by
/// category. Tapping a type adds it in
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
    with IssueFlow<AddDataSheet>, StandaloneIssueFlow<AddDataSheet> {
  /// The name of the card just added with "Add more", noted on the list.
  String? _justAdded;

  /// The list page, kept as one widget: the flow's changes (an issuance,
  /// the PIN, a website opened) rebuild this State, not the list.
  Widget? _listPage;
  String? _listPageFor;

  /// What is typed in the search. Kept here, not on the list page: a step
  /// further than the details drops the list page, and coming back to it
  /// the search is still there.
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
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    issueStartWith(widget.addNew);
  }

  @override
  void issueDone() => _done();

  @override
  IssueSuccessLink issueSuccessLink(List<schemaless.Credential> cards) => (
    key: const Key("sheet_add_more"),
    label: context.tr("data.add.add_more"),
    onTap: _addMore,
  );

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
      final first = ref.read(walletCardsProvider).firstOrNull;
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
    // On "Success" while the sheet goes.
    issueClose();
  }

  // ---------- the list ----------

  /// Explains that the credential cannot be loaded because the device has
  /// no NFC hardware.
  void _showNfcUnsupportedDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => GlassDialog(
        icon: const ToneDisc(icon: Icons.nfc_rounded, tone: DialogTone.warning),
        title: FlutterI18n.translate(context, "data.add.nfc_unsupported.title"),
        message: FlutterI18n.translate(
          context,
          "data.add.nfc_unsupported.body",
        ),
        actions: [
          FancyPillButton(
            label: FlutterI18n.translate(context, "error.button_ok"),
            size: PillSize.regular,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
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
    return issueSheet(rootKey: "list", root: () => _list, onBack: issueBack);
  }
}

/// The root page of Add data: what can be added, by category. Its own
/// widget, so the flow's changes don't rebuild it, and the rows are built as
/// they scroll into view.
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

/// The search: a field at the top of the list, as on the Data tab, that
/// scrolls away with it. A tap puts the field in the bar to type in; it goes
/// back once it is empty and left.
class _AddDataListPageState extends ConsumerState<_AddDataListPage> {
  TextEditingController get _search => widget.search;
  final _focus = FocusNode();

  /// The field is in the bar.
  late bool _inBar = _search.text.isNotEmpty;

  /// The gap under the list's field.
  static const _fieldGap = 12.0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_leaveBar);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _toBar() {
    setState(() => _inBar = true);
    afterFrame(_focus.requestFocus);
  }

  /// Out of the bar once left empty.
  void _leaveBar() {
    if (!_focus.hasFocus && _search.text.trim().isEmpty && _inBar) {
      setState(() => _inBar = false);
    }
  }

  /// Whether [item] matches [query], already [normaliseForSearch]ed.
  static bool _matches(CredentialStoreItem item, String query) {
    if (query.isEmpty) return true;
    final credential = item.credential;
    return normaliseForSearch(credential.name).contains(query) ||
        normaliseForSearch(credential.issuer.name).contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final storeItems = ref.watch(groupedCredentialStoreProvider);
    final owned = ref.watch(cardTypesInAppProvider);

    // Treat the device as NFC-capable while the check is loading or if it
    // fails: greying out a credential the user can actually obtain is worse
    // than showing it normally. Only a confirmed "no NFC chip" result greys
    // out the NFC-requiring credentials.
    final nfcAvailable = ref.watch(nfcAvailableProvider).value ?? true;

    String title(CredentialStoreCategory group) => switch (group.source) {
      CredentialStoreSource.staging => context.tr("data.add.staging"),
      CredentialStoreSource.demo => context.tr("data.add.demo"),
      _ => group.category,
    };

    final landscape = useSheetColumns(context);
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
        _inset(
          SliverToBoxAdapter(
            child: Text(
              error.toString(),
              style: palette.body(14).copyWith(color: palette.danger),
            ),
          ),
        ),
      ],
      AsyncData(value: final value) => () {
        final query = normaliseForSearch(_search.text.trim());
        final groups = [
          for (final group in value)
            (group, group.items.where((i) => _matches(i, query)).toList()),
        ].where((g) => g.$2.isNotEmpty).toList();
        return [
          if (groups.isEmpty)
            _inset(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    context.tr("data.add.no_results", {
                      "query": _search.text.trim(),
                    }),
                    key: const Key("add_data_no_results"),
                    textAlign: TextAlign.center,
                    style: palette.body(16).copyWith(color: palette.heading),
                  ),
                ),
              ),
            ),
          // A phone held sideways: each type a card of its own, two side by
          // side, under the category's name.
          if (landscape)
            for (final (group, items) in groups)
              _inset(
                SliverMainAxisGroup(
                  slivers: [
                    if (title(group).isNotEmpty)
                      SliverToBoxAdapter(child: GlassTileHeader(title(group))),
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
                                        ? GlassTile(child: row(items[i]))
                                        : const SizedBox.shrink(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
          else
            for (final (group, items) in groups)
              SliverGlassGroup(
                // A credential without a category (irmago marshals it
                // `omitempty`) gets no header.
                header: title(group).isEmpty ? null : title(group),
                fullWidth: true,
                dividerIndent: AddDataRow.dividerIndent,
                itemCount: items.length,
                itemBuilder: (context, i) => row(items[i]),
              ),
        ];
      }(),
    };

    final justAdded = widget.justAdded;
    final page = GlassSheetPage(
      title: context.tr("data.add.title"),
      titleWidget: _inBar
          ? GlassSearchField(
              fieldKey: const Key("add_data_search_bar"),
              hintKey: "data.add.search",
              controller: _search,
              focusNode: _focus,
              height: 44,
              onChanged: (_) => setState(() {}),
            )
          : null,
      // The close button at the top right on a phone held upright, as in
      // other sheets; on a tablet and a phone held sideways at the top left,
      // where the pages after this one keep the top right for the way on.
      closeAtStart: useFormSheet(context) || usePhoneLandscape(context),
      // The list's bands run from edge to edge; the rest keeps 16 from it
      // ([_inset]).
      slivers: [
        // In the bar while searching, as the Data tab's: then not here.
        if (!_inBar)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, _fieldGap),
            sliver: SliverToBoxAdapter(
              child: HomeTabSearchField(
                key: const Key("add_data_search"),
                hint: context.tr("data.add.search"),
                onTap: _toBar,
              ),
            ),
          ),
        if (justAdded != null)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                      borderRadius: YiviCorners.cardRadius,
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
                          context.tr("data.add.added_more", {
                            "name": justAdded,
                          }),
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
    );
    return page;
  }

  /// [sliver] 16 from the sides, as all but the list's bands.
  Widget _inset(Widget sliver) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    sliver: sliver,
  );
}
