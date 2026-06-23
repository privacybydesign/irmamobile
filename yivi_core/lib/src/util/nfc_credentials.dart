import "../models/schemaless/credential_store.dart";

/// Full credential IDs whose issuance requires reading a physical document over
/// the device's onboard NFC chip (passport, ID card, driving licence).
///
/// These can only be obtained on devices that actually have NFC hardware, so
/// they are hidden from the credential store on devices without NFC (e.g.
/// iPads). The matching embedded issuance flows live in
/// `IrmaRepository.openIssueURL`.
const Set<String> nfcRequiringCredentialIds = {
  // production
  "pbdf.pbdf.passport",
  "pbdf.pbdf.drivinglicence",
  "pbdf.pbdf.idcard",
  // staging
  "pbdf-staging.pbdf.passport",
  "pbdf-staging.pbdf.drivinglicence",
  "pbdf-staging.pbdf.idcard",
};

/// Whether obtaining the credential with [credentialId] requires onboard NFC.
bool credentialRequiresNfc(String credentialId) =>
    nfcRequiringCredentialIds.contains(credentialId);

/// Removes credentials that require onboard NFC issuance from [items] when the
/// device has no NFC capability. When [nfcAvailable] is `true` the list is
/// returned unchanged.
List<CredentialStoreItem> filterNfcRequiringCredentials(
  List<CredentialStoreItem> items, {
  required bool nfcAvailable,
}) {
  if (nfcAvailable) return items;
  return items
      .where((item) => !credentialRequiresNfc(item.credential.credentialId))
      .toList();
}
