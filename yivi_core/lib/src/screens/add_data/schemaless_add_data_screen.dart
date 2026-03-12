import "package:flutter/material.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../models/schemaless/credential_store.dart";
import "../../providers/schemaless_credential_store_provider.dart";
import "../../theme/theme.dart";
import "../../util/navigation.dart";
import "../../widgets/credential_card/schemaless_yivi_credential_type_card.dart";
import "../../widgets/irma_app_bar.dart";
import "../../widgets/translated_text.dart";

class SchemalessAddDataScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final storeItems = ref.watch(groupedCredentialStoreProvider);
    final lang = FlutterI18n.currentLocale(context)!.languageCode;

    return Scaffold(
      backgroundColor: theme.backgroundTertiary,
      appBar: IrmaAppBar(titleTranslationKey: "data.add.title"),
      body: SingleChildScrollView(
        padding: .all(theme.defaultSpacing),
        child: SafeArea(
          child: Column(
            spacing: theme.smallSpacing,
            crossAxisAlignment: .start,
            children: [
              TranslatedText(
                "data.add.choose",
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: theme.defaultSpacing),
              switch (storeItems) {
                AsyncLoading() => Center(child: CircularProgressIndicator()),
                AsyncError(error: final error) => Center(
                  child: Text(
                    error.toString(),
                    style: TextStyle(color: theme.error),
                  ),
                ),
                AsyncData(value: final value) => Column(
                  crossAxisAlignment: .start,
                  spacing: theme.largeSpacing,
                  children: [
                    for (final CredentialStoreCategory(:category, :items)
                        in value)
                      Column(
                        crossAxisAlignment: .start,
                        spacing: theme.smallSpacing,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(
                              category.translate(lang),
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          Column(
                            spacing: theme.smallSpacing,
                            children: [
                              for (final CredentialStoreItem(:credential, :faq)
                                  in items)
                                SchemalessYiviCredentialTypeCard(
                                  credentialImagePath: credential.imagePath,
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
