import "package:flutter_test/flutter_test.dart";

import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/translated_value.dart";
import "package:yivi_core/src/util/nfc_credentials.dart";

TrustedParty _issuer() => TrustedParty(
  id: "issuer",
  name: const TranslatedValue.empty(),
  url: null,
  parent: null,
  verified: true,
);

CredentialStoreItem _item(String credentialId) => CredentialStoreItem(
  credential: CredentialDescriptor(
    credentialId: credentialId,
    name: const TranslatedValue.empty(),
    issuer: _issuer(),
    category: null,
    attributes: const [],
    issueURL: null,
  ),
  faq: Faq(
    intro: const TranslatedValue.empty(),
    purpose: const TranslatedValue.empty(),
    content: const TranslatedValue.empty(),
    howTo: const TranslatedValue.empty(),
  ),
);

List<String> _ids(List<CredentialStoreItem> items) =>
    items.map((i) => i.credential.credentialId).toList();

void main() {
  group("credentialRequiresNfc", () {
    test("true for document credentials that need onboard NFC scanning", () {
      expect(credentialRequiresNfc("pbdf.pbdf.passport"), isTrue);
      expect(credentialRequiresNfc("pbdf.pbdf.drivinglicence"), isTrue);
      expect(credentialRequiresNfc("pbdf.pbdf.idcard"), isTrue);
      expect(credentialRequiresNfc("pbdf-staging.pbdf.passport"), isTrue);
      expect(credentialRequiresNfc("pbdf-staging.pbdf.drivinglicence"), isTrue);
      expect(credentialRequiresNfc("pbdf-staging.pbdf.idcard"), isTrue);
    });

    test("false for credentials that don't need NFC", () {
      expect(credentialRequiresNfc("pbdf.sidn-pbdf.email"), isFalse);
      expect(credentialRequiresNfc("pbdf.sidn-pbdf.mobilenumber"), isFalse);
      expect(credentialRequiresNfc("pbdf.gemeente.personalData"), isFalse);
    });
  });

  group("filterNfcRequiringCredentials", () {
    final items = [
      _item("pbdf.sidn-pbdf.email"),
      _item("pbdf.pbdf.passport"),
      _item("pbdf.gemeente.personalData"),
      _item("pbdf.pbdf.drivinglicence"),
      _item("pbdf.pbdf.idcard"),
    ];

    test(
      "hides NFC-requiring credentials on a device without NFC capability",
      () {
        final filtered = filterNfcRequiringCredentials(
          items,
          nfcAvailable: false,
        );

        expect(_ids(filtered), [
          "pbdf.sidn-pbdf.email",
          "pbdf.gemeente.personalData",
        ]);
        // None of the remaining credentials require NFC.
        expect(
          filtered.every(
            (i) => !credentialRequiresNfc(i.credential.credentialId),
          ),
          isTrue,
        );
      },
    );

    test("keeps every credential when the device has NFC", () {
      final filtered = filterNfcRequiringCredentials(items, nfcAvailable: true);
      expect(_ids(filtered), _ids(items));
    });

    test("returns an empty list when every credential requires NFC", () {
      final nfcOnly = [_item("pbdf.pbdf.passport"), _item("pbdf.pbdf.idcard")];
      expect(
        filterNfcRequiringCredentials(nfcOnly, nfcAvailable: false),
        isEmpty,
      );
    });
  });
}
