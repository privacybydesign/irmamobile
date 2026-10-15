import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";

import "../../data/feature_flags.dart";
import "../../models/schemaless/credential_store.dart";
import "../../providers/feature_flag_provider.dart";
import "../../providers/irma_repository_provider.dart";
import "../../providers/nfc_availability_provider.dart";
import "../../providers/schemaless_credential_store_provider.dart";
import "../../theme/yivi_palette.dart";
import "../../util/navigation.dart";
import "../../util/nfc_credentials.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/glass/glass_dialog.dart";
import "../../widgets/glass/glass_group.dart";
import "../../widgets/glass/glass_search_field.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/irma_avatar.dart";
import "../../widgets/irma_dialog.dart";
import "../../widgets/translated_text.dart";
import "../../widgets/yivi_themed_button.dart";

class SchemalessAddDataScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SchemalessAddDataScreen> createState() =>
      _SchemalessAddDataScreenState();
}

class _SchemalessAddDataScreenState
    extends ConsumerState<SchemalessAddDataScreen> {
  String _query = "";

  /// Shows an explanation that the credential cannot be loaded because the
  /// device has no NFC hardware.
  void _showNfcUnsupportedDialog(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final storeItems = ref.watch(groupedCredentialStoreProvider);

    // Treat the device as NFC-capable while the check is loading or if it
    // fails: greying out a credential the user can actually obtain is worse
    // than showing it normally. Only a confirmed "no NFC chip" result greys
    // out the NFC-requiring credentials.
    final nfcAvailable = ref.watch(nfcAvailableProvider).value ?? true;
    final documentFlowV2 =
        ref.watch(featureFlagProvider(FeatureFlag.documentFlowV2)).value ??
        false;

    void open(CredentialStoreItem item) {
      final credential = item.credential;
      final nfcBlocked =
          !nfcAvailable && credentialRequiresNfc(credential.credentialId);
      if (nfcBlocked) {
        _showNfcUnsupportedDialog(context);
      } else if (documentFlowV2 &&
          credentialRequiresNfc(credential.credentialId)) {
        IrmaRepositoryProvider.of(context).openIssueURL(
          context,
          credential.credentialId,
          credential.issueURL,
          ref,
        );
      } else {
        context.pushSchemalessDataDetailsScreen(
          AddDataDetailsRouteParams(credential: credential, faq: item.faq),
        );
      }
    }

    String title(CredentialStoreCategory group) => switch (group.source) {
      CredentialStoreSource.staging => FlutterI18n.translate(
        context,
        "data.add.staging",
      ),
      CredentialStoreSource.demo => FlutterI18n.translate(
        context,
        "data.add.demo",
      ),
      _ => group.category,
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: palette.background,
      appBar: IrmaAppBar(titleTranslationKey: "data.add.title"),
      body: BarInsetsBuilder(
        builder: (context, insets) => Stack(
          fit: StackFit.expand,
          children: [
            switch (storeItems) {
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              AsyncError(error: final error) => Center(
                child: Text(
                  error.toString(),
                  style: palette.body(14).copyWith(color: palette.danger),
                ),
              ),
              AsyncData(value: final value) => () {
                final groups = [
                  for (final group in value)
                    (group, group.items.where(_matches).toList()),
                ].where((g) => g.$2.isNotEmpty).toList();
                return ListView(
                  // Starts below the app bar and the search field, and
                  // scrolls underneath them, as on the Data tab.
                  padding: EdgeInsets.fromLTRB(
                    16 + insets.left,
                    insets.top + _searchHeight + 20,
                    16 + insets.right,
                    48 + insets.bottom,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TranslatedText(
                        "data.add.choose",
                        style: palette
                            .body(16)
                            .copyWith(color: palette.heading),
                      ),
                    ),
                    if (groups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            "data.add.no_results",
                            translationParams: {"query": _query.trim()},
                          ),
                          textAlign: TextAlign.center,
                          style: palette
                              .body(16)
                              .copyWith(color: palette.heading),
                        ),
                      ),
                    for (final (group, items) in groups)
                      GlassGroup(
                        // A credential without a category (irmago marshals
                        // it `omitempty`) gets no header.
                        header: title(group).isEmpty ? null : title(group),
                        dividerIndent: 72,
                        children: [
                          for (final item in items)
                            AddDataRow(
                              item: item,
                              nfcBlocked:
                                  !nfcAvailable &&
                                  credentialRequiresNfc(
                                    item.credential.credentialId,
                                  ),
                              onTap: () => open(item),
                            ),
                        ],
                      ),
                  ],
                );
              }(),
            },
            // The page colour fading out under the search field, so the
            // list scrolling underneath it fades away.
            Positioned(
              left: 0,
              right: 0,
              top: insets.top,
              height: _searchHeight + 32,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        palette.background,
                        palette.background.withValues(alpha: 0),
                      ],
                      stops: const [0.55, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16 + insets.left,
              right: 16 + insets.right,
              top: insets.top + 8,
              child: GlassSearchField(
                fieldKey: const Key("add_data_search"),
                hintKey: "data.add.search",
                onChanged: (q) => setState(() => _query = q),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One credential type to add: its logo, name and issuer, an NFC chip for
/// documents, and a chevron. Greyed out when it needs NFC the device lacks.
/// Height of the floating search field.
const double _searchHeight = 48;

class AddDataRow extends StatelessWidget {
  final CredentialStoreItem item;

  /// Needs NFC the device does not have: greyed out, with the reason under
  /// the name and as a screen-reader hint.
  final bool nfcBlocked;
  final VoidCallback onTap;

  const AddDataRow({
    super.key,
    required this.item,
    required this.nfcBlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = YiviPalette.of(context);
    final credential = item.credential;
    final needsNfc = credentialRequiresNfc(credential.credentialId);
    final image = credential.image;

    return Semantics(
      button: true,
      hint: nfcBlocked
          ? FlutterI18n.translate(context, "data.add.nfc_unsupported.hint")
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
                  if (needsNfc)
                    ExcludeSemantics(
                      child: Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: ShapeDecoration(
                          color: palette.tint,
                          shape: const StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            Icon(
                              Icons.nfc_rounded,
                              size: 12,
                              color: palette.link,
                            ),
                            Text(
                              "NFC",
                              style: palette
                                  .body(11, weight: FontWeight.w700)
                                  .copyWith(color: palette.link),
                            ),
                          ],
                        ),
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
