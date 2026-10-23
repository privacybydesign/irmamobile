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
    with IssueFlow<AddDataSheet> {
  /// The name of the card just added with "Add more", noted on the list.
  String? _justAdded;

  /// The list page, kept as one widget: the flow's changes (an issuance,
  /// the PIN, a website opened) rebuild this State, not the list.
  Widget? _listPage;
  String? _listPageFor;

  Widget get _list {
    if (_listPage == null || _listPageFor != _justAdded) {
      _listPageFor = _justAdded;
      _listPage = _AddDataListPage(justAdded: _justAdded, onOpen: _open);
    }
    return _listPage!;
  }

  @override
  void initState() {
    super.initState();
    issueStartWith(widget.addNew);
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
  SheetAction issueSuccessAction(List<schemaless.Credential> cards) =>
      SheetAction(
        key: const Key("sheet_done"),
        label: _t("ui.done"),
        onTap: _done,
      );

  @override
  IssueSuccessLink issueSuccessLink(List<schemaless.Credential> cards) => (
    key: const Key("sheet_add_more"),
    label: _t("data.add.add_more"),
    onTap: _addMore,
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
/// widget, so the flow's changes don't rebuild it, and the rows are built as
/// they scroll into view.
class _AddDataListPage extends ConsumerStatefulWidget {
  /// The name of the card just added with "Add more", noted at the top.
  final String? justAdded;
  final void Function(CredentialStoreItem item, {required bool nfcBlocked})
  onOpen;

  const _AddDataListPage({required this.justAdded, required this.onOpen});

  @override
  ConsumerState<_AddDataListPage> createState() => _AddDataListPageState();
}

class _AddDataListPageState extends ConsumerState<_AddDataListPage> {
  String _t(String key, [Map<String, String>? params]) =>
      FlutterI18n.translate(context, key, translationParams: params);

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
        SliverToBoxAdapter(
          child: Text(
            error.toString(),
            style: palette.body(14).copyWith(color: palette.danger),
          ),
        ),
      ],
      AsyncData(value: final value) => () {
        final groups = [
          for (final group in value) (group, group.items),
        ].where((g) => g.$2.isNotEmpty).toList();
        return [
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
    return GlassSheetPage(
      title: _t("data.add.title"),
      // The close button at the top left: on the pages after this one the
      // top right is for the way on, and they close by a drag down.
      closeAtStart: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      slivers: [
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
                      borderRadius: BorderRadius.all(
                        Radius.circular(YiviCorners.card),
                      ),
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
