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
import "../../theme/yivi_palette.dart";
import "../../util/adaptive_layout.dart";
import "../../util/nfc_credentials.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/glass/glass_sheet.dart";
import "../../widgets/glass/sheet_action_row.dart";
import "../../widgets/irma_avatar.dart";
import "../../widgets/irma_dialog.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_themed_button.dart";
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
  heightFraction: 0.9,
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
  String _query = "";

  /// The name of the card just added with "Add more", noted on the list.
  String? _justAdded;

  @override
  void initState() {
    super.initState();
    issueAdding = widget.addNew;
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
      issueReset();
    });
  }

  /// "Done": the sheet closes on the Data tab while the new card flies from
  /// "Success" into the first slot. On a tablet, where the sheet is a dialog
  /// beside the detail pane, the card opens in the pane instead.
  void _done() {
    final cards = issueAdded ?? const <schemaless.Credential>[];
    if (!widget.flyToDataTab) {
      // Opened over another page: the card is in the app, nothing flies.
    } else if (isExpandedLayout(context)) {
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
        child: YiviThemedButton(
          label: "error.button_ok",
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  bool _matches(CredentialStoreItem item) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final credential = item.credential;
    return credential.name.toLowerCase().contains(query) ||
        credential.issuer.name.toLowerCase().contains(query);
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
          KeyedSubtree(key: const ValueKey("list"), child: _buildList()),
          ...issueFlowPages(),
        ],
      ),
    );
  }

  Widget _buildList() {
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

    final Widget body = switch (storeItems) {
      AsyncLoading() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Center(child: CircularProgressIndicator()),
      ),
      AsyncError(error: final error) => Text(
        error.toString(),
        style: palette.body(14).copyWith(color: palette.danger),
      ),
      AsyncData(value: final value) => () {
        final groups = [
          for (final group in value)
            (group, group.items.where(_matches).toList()),
        ].where((g) => g.$2.isNotEmpty).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(
                  _t("data.add.no_results", {"query": _query.trim()}),
                  textAlign: TextAlign.center,
                  style: palette.body(16).copyWith(color: palette.heading),
                ),
              ),
            for (final (group, items) in groups)
              GlassGroup(
                // A credential without a category (irmago marshals it
                // `omitempty`) gets no header.
                header: title(group).isEmpty ? null : title(group),
                dividerIndent: 72,
                children: [
                  for (final item in items)
                    () {
                      final blocked =
                          !nfcAvailable &&
                          credentialRequiresNfc(item.credential.credentialId);
                      return AddDataRow(
                        item: item,
                        nfcBlocked: blocked,
                        owned: owned.contains(item.credential.credentialId),
                        onTap: () => _open(item, nfcBlocked: blocked),
                      );
                    }(),
                ],
              ),
          ],
        );
      }(),
    };

    final justAdded = _justAdded;
    return GlassSheetPage(
      title: _t("data.add.title"),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      pinned: GlassSearchField(
        fieldKey: const Key("add_data_search"),
        hintKey: "data.add.search",
        onChanged: (q) => setState(() => _query = q),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          if (justAdded != null)
            Semantics(
              liveRegion: true,
              child: Container(
                key: const Key("add_data_added_note"),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: ShapeDecoration(
                  color: palette.successSurface,
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TranslatedText(
              "data.add.choose",
              style: palette.body(16).copyWith(color: palette.heading),
            ),
          ),
          body,
        ],
      ),
    );
  }
}

/// One credential type to add: its logo, name and issuer, an "In your app"
/// chip when the user has one already ([owned]), an NFC chip for documents,
/// and a chevron. Greyed out when it needs NFC the device lacks.
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

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final credential = item.credential;
    final needsNfc = credentialRequiresNfc(credential.credentialId);
    final image = credential.image;

    Widget chip(String label, Color fill, Color ink, {IconData? icon}) =>
        ExcludeSemantics(
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: ShapeDecoration(
              color: fill,
              shape: const StadiumBorder(),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                if (icon != null) Icon(icon, size: 12, color: ink),
                Text(
                  label,
                  style: palette
                      .body(11, weight: FontWeight.w700)
                      .copyWith(color: ink),
                ),
              ],
            ),
          ),
        );

    return Semantics(
      button: true,
      hint: nfcBlocked
          ? FlutterI18n.translate(context, "data.add.nfc_unsupported.hint")
          : owned
          ? FlutterI18n.translate(context, "data.add.in_your_app")
          : null,
      child: Opacity(
        opacity: nfcBlocked ? 0.5 : 1,
        child: InkWell(
          key: Key("${credential.credentialId}_tile"),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 68),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: Row(
                spacing: 14,
                children: [
                  ExcludeSemantics(
                    child: IrmaAvatar(
                      size: 44,
                      initials: credential.name.isEmpty
                          ? null
                          : credential.name.characters.first,
                      logoImage: image == null
                          ? null
                          : Base64Image(
                              base64: image.base64,
                              mimeType: image.mimeType,
                            ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential.name,
                          style: palette
                              .display(16)
                              .copyWith(color: palette.text),
                        ),
                        Text(
                          nfcBlocked
                              ? FlutterI18n.translate(
                                  context,
                                  "data.add.nfc_unsupported.hint",
                                )
                              : credential.issuer.name,
                          maxLines: nfcBlocked ? 3 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: palette
                              .body(13)
                              .copyWith(color: palette.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  if (owned && !nfcBlocked)
                    chip(
                      FlutterI18n.translate(context, "data.add.in_your_app"),
                      palette.successSurface,
                      palette.successText,
                    ),
                  if (needsNfc)
                    chip(
                      "NFC",
                      palette.tint,
                      palette.link,
                      icon: Icons.nfc_rounded,
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
