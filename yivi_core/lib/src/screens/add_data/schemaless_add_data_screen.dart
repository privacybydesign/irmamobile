import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/schemaless/credential_store.dart";
import "../../providers/nfc_availability_provider.dart";
import "../../providers/schemaless_credential_store_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../util/nfc_credentials.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/credential_card/schemaless_yivi_credential_type_card.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/section_header.dart";
import "../../widgets/yivi_dialog.dart";
import "../../widgets/yivi_themed_button.dart";

class SchemalessAddDataScreen extends ConsumerWidget {
  /// Shows an explanation that the credential cannot be loaded because the
  /// device has no NFC hardware.
  void _showNfcUnsupportedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => YiviDialog.structured(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeItems = ref.watch(groupedCredentialStoreProvider);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    // Treat the device as NFC-capable while the check is loading or if it
    // fails: greying out a credential the user can actually obtain is worse
    // than showing it normally. Only a confirmed "no NFC chip" result greys
    // out the NFC-requiring credentials.
    final nfcAvailable = ref.watch(nfcAvailableProvider).value ?? true;

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHigh,
      appBar: IrmaAppBar(titleTranslationKey: "data.add.title"),
      body: SingleChildScrollView(
        padding: .all(context.yivi.spacing.base),
        child: SafeArea(
          child: Column(
            spacing: context.yivi.spacing.small,
            crossAxisAlignment: .start,
            children: [
              switch (storeItems) {
                AsyncLoading() => Center(child: CircularProgressIndicator()),
                AsyncError(error: final error) => Center(
                  child: Text(
                    error.toString(),
                    style: context.yivi.form.errorMessage,
                  ),
                ),
                AsyncData(value: final value) => Column(
                  crossAxisAlignment: .start,
                  spacing: context.yivi.spacing.large,
                  children: [
                    for (final CredentialStoreCategory(:category, :items)
                        in value)
                      Column(
                        crossAxisAlignment: .start,
                        spacing: context.yivi.spacing.small,
                        children: [
                          SectionHeader.text(category.translate(lang)),
                          Column(
                            spacing: context.yivi.spacing.small,
                            children: [
                              for (final CredentialStoreItem(:credential, :faq)
                                  in items)
                                () {
                                  final nfcBlocked =
                                      !nfcAvailable &&
                                      credentialRequiresNfc(
                                        credential.credentialId,
                                      );
                                  return SchemalessYiviCredentialTypeCard(
                                    credentialImageBase64:
                                        credential.image != null
                                        ? Base64Image(
                                            base64: credential.image!.base64,
                                          )
                                        : null,
                                    credentialName: credential.name,
                                    credentialId: credential.credentialId,
                                    issuerName: credential.issuer.name,
                                    trailingIcon: Icons.add_circle_sharp,
                                    disabled: nfcBlocked,
                                    disabledHint: nfcBlocked
                                        ? FlutterI18n.translate(
                                            context,
                                            "data.add.nfc_unsupported.hint",
                                          )
                                        : null,
                                    onTap: nfcBlocked
                                        ? () =>
                                              _showNfcUnsupportedDialog(context)
                                        : () => context
                                              .pushSchemalessDataDetailsScreen(
                                                AddDataDetailsRouteParams(
                                                  credential: credential,
                                                  faq: faq,
                                                ),
                                              ),
                                  );
                                }(),
                            ],
                          ),
                        ],
                      ),
                    SizedBox(height: 25),
                  ],
                ),
              },
            ],
          ),
        ),
      ),
    );
  }
}
