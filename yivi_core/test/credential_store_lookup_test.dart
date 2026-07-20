import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/providers/schemaless_credential_store_provider.dart";

CredentialStoreItem _item(String credentialId) => CredentialStoreItem(
  credential: CredentialDescriptor(
    credentialId: credentialId,
    name: TranslatedValue.fromString(credentialId),
    issuer: TrustedParty(
      id: "issuer",
      name: TranslatedValue.fromString("Issuer"),
      url: null,
      parent: null,
      verified: true,
    ),
    category: TranslatedValue.fromString("Personal"),
    attributes: [],
    issueURL: null,
  ),
  faq: Faq(
    intro: TranslatedValue.fromString("intro $credentialId"),
    purpose: TranslatedValue.fromString("purpose"),
    content: TranslatedValue.fromString("content"),
    howTo: TranslatedValue.fromString("howto"),
  ),
);

void main() {
  final store = [
    _item("pbdf.pbdf.passport"),
    _item("pbdf-staging.sidn-pbdf.email"),
  ];

  test("returns the store entry matching the credential id", () {
    final item = store.forCredentialId("pbdf-staging.sidn-pbdf.email");

    expect(item, isNotNull);
    expect(item!.credential.credentialId, "pbdf-staging.sidn-pbdf.email");
    expect(
      item.faq.intro.translate("en"),
      "intro pbdf-staging.sidn-pbdf.email",
    );
  });

  test("returns null when the store has no entry for the credential id", () {
    expect(store.forCredentialId("https://example.com/vct/eduid"), isNull);
  });
}
