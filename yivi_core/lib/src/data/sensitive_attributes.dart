import "../models/schemaless/session_user_interaction.dart";

/// Attribute ids (`<credential id>.<attribute id>`) that get an extra check
/// before they are shared. A flag in the scheme can replace this list later.
/// The demo scheme's copy of the BSN is here too, so the check can be tried
/// with demo credentials.
const _sensitiveAttributeIds = {
  "pbdf.gemeente.personalData.bsn",
  "irma-demo.gemeente.personalData.bsn",
};

/// Whether [credentials] disclose a sensitive attribute.
bool sharesSensitiveAttribute(Iterable<SelectedCredential> credentials) {
  return credentials.any(
    (credential) => credential.attributePaths.any((path) {
      final attributeId = path.whereType<String>().join(".");
      return _sensitiveAttributeIds.contains(
        "${credential.credentialId}.$attributeId",
      );
    }),
  );
}
