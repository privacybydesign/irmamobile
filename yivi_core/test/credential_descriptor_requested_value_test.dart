import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/credential_store.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/models/translated_value.dart";

CredentialDescriptor _descriptor(List<Attribute> attributes) =>
    CredentialDescriptor(
      credentialId: "pbdf.sidn-pbdf.email",
      name: TranslatedValue.fromString("Email"),
      issuer: TrustedParty(
        id: "pbdf.sidn-pbdf",
        name: TranslatedValue.fromString("SIDN"),
        url: null,
        parent: null,
        verified: true,
      ),
      category: null,
      attributes: attributes,
      issueURL: TranslatedValue.fromString("https://email-issuer.example/"),
    );

Attribute _attr(String name, {String? requested}) => Attribute(
  claimPath: [name],
  displayName: TranslatedValue.fromString(name),
  requestedValue: requested == null
      ? null
      : AttributeValue(type: AttributeType.string, string: requested),
);

void main() {
  test("returns the requested attribute value when present", () {
    final descriptor = _descriptor([
      _attr("email", requested: "john.doe@example.com"),
      _attr("domain"),
    ]);

    expect(descriptor.requestedValueString, "john.doe@example.com");
  });

  test("returns null when no attribute carries a requested value", () {
    final descriptor = _descriptor([_attr("email"), _attr("domain")]);

    expect(descriptor.requestedValueString, isNull);
  });

  test("ignores empty requested values", () {
    final descriptor = _descriptor([
      _attr("email", requested: ""),
      _attr("domain", requested: "example.com"),
    ]);

    expect(descriptor.requestedValueString, "example.com");
  });
}
