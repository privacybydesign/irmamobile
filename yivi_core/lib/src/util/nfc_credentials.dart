/// Full credential IDs whose issuance requires reading a physical document over
/// the device's onboard NFC chip (passport, ID card, driving licence).
///
/// These can only be obtained on devices that actually have NFC hardware. On
/// devices without NFC (e.g. iPads) they are not hidden from the credential
/// store, but shown greyed out: tapping one explains that the device cannot
/// load the credential without NFC. The matching embedded issuance flows live
/// in `IrmaRepository.openIssueURL`.
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
