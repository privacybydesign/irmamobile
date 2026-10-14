import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";

/// A string attribute for tests.
Attribute stringAttr(String id, String? value, {String? svgId}) => Attribute(
  claimPath: [id],
  displayName: id,
  value: AttributeValue(type: AttributeType.string, string: value),
  svgId: svgId,
);

/// A yes/no attribute for tests.
Attribute boolAttr(String id, bool value) => Attribute(
  claimPath: [id],
  displayName: id,
  value: AttributeValue(type: AttributeType.boolean, boolValue: value),
);

/// A credential for tests; only [type], [hash] and [attributes] usually matter.
Credential testCredential({
  required String type,
  required String hash,
  List<Attribute> attributes = const [],
  String name = "Test credential",
  String issuerName = "Test issuer",
  int? issuanceDate,
  int? expiryDate,
  CredentialDisplay? display,
}) => Credential(
  credentialId: type,
  hash: hash,
  name: name,
  issuer: TrustedParty(
    id: "issuer",
    name: issuerName,
    url: null,
    parent: null,
    verified: true,
  ),
  credentialInstanceIds: {CredentialFormat.idemix: hash},
  batchInstanceCountsRemaining: const {},
  attributes: attributes,
  revoked: false,
  revocationSupported: false,
  issueUrl: null,
  issuanceDate: issuanceDate,
  expiryDate: expiryDate,
  display: display,
);
