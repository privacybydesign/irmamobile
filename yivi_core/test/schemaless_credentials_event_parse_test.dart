import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/log_entry.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";

void main() {
  test("parses an event with empty credentials and empty problematic", () {
    final e = SchemalessCredentialsEvent.fromJson({
      "credentials": <dynamic>[],
      "problematic": <dynamic>[],
    });
    expect(e.credentials, isEmpty);
    expect(e.problematic, isEmpty);
  });

  test("parses an event with the problematic key absent", () {
    final e = SchemalessCredentialsEvent.fromJson({"credentials": <dynamic>[]});
    expect(e.problematic, isEmpty);
  });

  test("parses a problematic entry", () {
    final e = SchemalessCredentialsEvent.fromJson({
      "credentials": <dynamic>[],
      "problematic": [
        {
          "credential_instance_ids": {"idemix": "hash123"},
          "reason": "unknown credential type irma-demo.acme.gone",
          "credential_id": "irma-demo.acme.gone",
        },
      ],
    });
    expect(e.problematic, hasLength(1));
    expect(e.problematic.first.credentialInstanceIds, hasLength(1));
    expect(e.problematic.first.reason, contains("unknown"));
  });

  group("CredentialDescriptor.format", () {
    CredentialDescriptor parse(Map<String, dynamic> extra) =>
        CredentialDescriptor.fromJson({
          "credential_id": "org.iso.18013.5.1.mDL",
          "name": "Driving licence",
          "issuer": {"id": "", "name": "", "verified": false},
          "attributes": <dynamic>[],
          ...extra,
        });

    test("reads the format", () {
      expect(parse({"format": "mso_mdoc"}).format, CredentialFormat.msoMdoc);
    });

    test("is null when absent, as from an older irmago", () {
      expect(parse({}).format, isNull);
    });

    test("is null for a format the app does not know", () {
      expect(parse({"format": "ldp_vc"}).format, isNull);
    });
  });
}
