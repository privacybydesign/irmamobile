import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/schemaless/credential_store.dart";
import "../../providers/schemaless_credential_store_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/base64_image.dart";
import "../../widgets/credential_card/schemaless_yivi_credential_type_card.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/section_header.dart";

class SchemalessAddDataScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeItems = ref.watch(groupedCredentialStoreProvider);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Scaffold(
      backgroundColor: context.colors.surfaceContainerHigh,
      appBar: IrmaAppBar(titleTranslationKey: "data.add.title"),
      body: SingleChildScrollView(
        padding: .all(context.yivi.defaultSpacing),
        child: SafeArea(
          child: Column(
            spacing: context.yivi.smallSpacing,
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
                  spacing: context.yivi.largeSpacing,
                  children: [
                    for (final CredentialStoreCategory(:category, :items)
                        in value)
                      Column(
                        crossAxisAlignment: .start,
                        spacing: context.yivi.smallSpacing,
                        children: [
                          SectionHeader.text(category.translate(lang)),
                          Column(
                            spacing: context.yivi.smallSpacing,
                            children: [
                              for (final CredentialStoreItem(:credential, :faq)
                                  in items)
                                SchemalessYiviCredentialTypeCard(
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
                                  onTap: () =>
                                      context.pushSchemalessDataDetailsScreen(
                                        AddDataDetailsRouteParams(
                                          credential: credential,
                                          faq: faq,
                                        ),
                                      ),
                                ),
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
