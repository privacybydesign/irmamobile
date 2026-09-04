import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/schemaless/session_state.dart";

// CredentialFormat mirrors clientmodels.CredentialFormat in irmago. Every value
// irmago can put in a `format` or `formats` field has to be in the enum, because
// json_serializable generates $enumDecode without an unknownValue fallback: an
// unlisted string throws ArgumentError out of fromJson, taking the whole event
// payload down rather than just the one field. So a format the wallet does not
// know is not a credential it skips, it is a screen that fails to build.
//
// These decode the payloads irmago actually sends for mso_mdoc — the disclosure
// permission screen and the activity log — and each one throws
// "Invalid argument(s): `mso_mdoc` is not one of the supported values" if the
// value is missing from the enum.
//
// Formats are asserted by `.name` rather than by enum member on purpose. Naming
// CredentialFormat.msoMdoc here would make this file fail to compile when the
// member is absent, which proves only that the member is absent; going through
// the string reproduces the decode failure the app actually hits.

Map<String, dynamic> _issuer() => {
  "id": "test.issuer",
  "name": "Test Issuer",
  "url": null,
  "parent": null,
  "verified": true,
};

Map<String, dynamic> _attribute() => {
  "claim_path": ["age_over_18"],
  "display_name": "Older than 18",
  "value": {"type": "boolean", "bool": true},
};

Map<String, dynamic> _selectableInstance({
  required String format,
  required String hash,
}) => {
  "credential_id": "eu.europa.ec.av.1",
  "hash": hash,
  "name": "Age verification",
  "issuer": _issuer(),
  "format": format,
  "attributes": [_attribute()],
  "revoked": false,
  "revocation_supported": false,
  "issue_url": null,
};

Map<String, dynamic> _logCredential({required List<String> formats}) => {
  "credential_id": "eu.europa.ec.av.1",
  "formats": formats,
  "name": "Age verification",
  "issuer": _issuer(),
  "attributes": [_attribute()],
  "revoked": false,
  "revocation_supported": false,
};

void main() {
  test("every format irmago can send is in the enum", () {
    // The Go side of this list is clientmodels.CredentialFormat in irmago
    // (common/clientmodels/enums.go). Adding a constant there without adding it
    // here breaks decoding of any payload carrying it.
    expect(
      CredentialFormat.values.map((f) => f.name),
      containsAll(<String>["idemix", "sdjwtvc", "msoMdoc"]),
    );
  });

  test("SelectableCredentialInstance decodes an mso_mdoc candidate", () {
    // eudi/openid4vp/mdoc_dcql sets this field when it answers a DCQL query, so
    // this is the disclosure permission screen's payload.
    final instance = SelectableCredentialInstance.fromJson(
      _selectableInstance(format: "mso_mdoc", hash: "abc"),
    );

    expect(instance.format.name, "msoMdoc");
  });

  test("a co-requested SD-JWT candidate survives an mso_mdoc one", () {
    // The failure is the whole document, not one field: a session requesting an
    // mdoc credential alongside an SD-JWT one used to lose both, so assert the
    // bundle decodes as a unit.
    final bundle = DisclosureBundle.fromJson({
      "credentials": [
        _selectableInstance(format: "mso_mdoc", hash: "mdoc-hash"),
        _selectableInstance(format: "dc+sd-jwt", hash: "sdjwt-hash"),
      ],
    });

    expect(bundle.credentials.map((c) => c.format.name), [
      "msoMdoc",
      "sdjwtvc",
    ]);
    expect(bundle.credentialHashes, {"mdoc-hash", "sdjwt-hash"});
  });

  test("LogCredential decodes mso_mdoc in formats", () {
    // The activity log entry mdoc_dcql builds after a disclosure.
    final logCredential = LogCredential.fromJson(
      _logCredential(formats: ["mso_mdoc"]),
    );

    expect(logCredential.formats.map((f) => f.name), ["msoMdoc"]);
  });

  test("LogCredential decodes a credential held in both formats", () {
    final logCredential = LogCredential.fromJson(
      _logCredential(formats: ["dc+sd-jwt", "mso_mdoc"]),
    );

    expect(logCredential.formats.map((f) => f.name), ["sdjwtvc", "msoMdoc"]);
  });

  test("Credential decodes mso_mdoc as a map key", () {
    // credential_instance_ids and batch_instance_counts_remaining are keyed by
    // format, so the format string arrives as a JSON object key here rather than
    // a value. json_serializable decodes map keys through $enumDecode too.
    final credential = Credential.fromJson({
      "credential_id": "eu.europa.ec.av.1",
      "hash": "abc",
      "name": "Age verification",
      "issuer": _issuer(),
      "credential_instance_ids": {"mso_mdoc": "instance-1"},
      "batch_instance_counts_remaining": {"mso_mdoc": 4},
      "attributes": [_attribute()],
      "revoked": false,
      "revocation_supported": false,
      "issue_url": null,
    });

    expect(credential.credentialInstanceIds.keys.map((f) => f.name), [
      "msoMdoc",
    ]);
    expect(credential.credentialInstanceIds.values, ["instance-1"]);
    expect(credential.batchInstanceCountsRemaining.values, [4]);
  });

  test("Attribute decodes intent_to_retain as a three-valued fact", () {
    // mdoc_dcql always sets intent_to_retain on an mdoc attribute (true or
    // false) so the app can tell "the verifier said it will not retain this"
    // from "this format cannot say", which is what the absent key on every
    // other format means. Only decoded for now; nothing renders it yet.
    final retained = Attribute.fromJson({
      ..._attribute(),
      "intent_to_retain": true,
    });
    final notRetained = Attribute.fromJson({
      ..._attribute(),
      "intent_to_retain": false,
    });
    final cannotSay = Attribute.fromJson(_attribute());

    expect(retained.intentToRetain, isTrue);
    expect(notRetained.intentToRetain, isFalse);
    expect(cannotSay.intentToRetain, isNull);
  });

  test("display_is_fallback decodes and defaults to false when absent", () {
    // Motivated by mdoc: ISO 18013-5 has no display concept, so the issuer's
    // OpenID4VCI metadata is the only source of names and it may not publish
    // the app language. irmago sends the flag on Credential and on
    // SelectableCredentialInstance; payloads from before the field default to
    // false so fixtures and previews keep decoding.
    final instance = SelectableCredentialInstance.fromJson({
      ..._selectableInstance(format: "mso_mdoc", hash: "abc"),
      "display_is_fallback": true,
    });
    final legacyInstance = SelectableCredentialInstance.fromJson(
      _selectableInstance(format: "mso_mdoc", hash: "abc"),
    );
    final credential = Credential.fromJson({
      "credential_id": "eu.europa.ec.av.1",
      "hash": "abc",
      "name": "Proof of Age",
      "issuer": _issuer(),
      "credential_instance_ids": {"mso_mdoc": "instance-1"},
      "batch_instance_counts_remaining": {"mso_mdoc": 30},
      "attributes": [_attribute()],
      "revoked": false,
      "revocation_supported": false,
      "issue_url": null,
      "display_is_fallback": true,
    });

    expect(instance.displayIsFallback, isTrue);
    expect(legacyInstance.displayIsFallback, isFalse);
    expect(credential.displayIsFallback, isTrue);
  });
}
