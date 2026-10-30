import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/models/schemaless/schemaless_events.dart";
import "package:yivi_core/src/util/instance_hint.dart";

import "helpers/credential_factory.dart";

String? hintOf(Credential c, List<Credential> all) => switch (instanceHintFor(
  c,
  all,
)) {
  ValueHint(:final text) => text,
  AddedHint() => "added",
  NoHint() => null,
};

void main() {
  test("one email address shows the address", () {
    final email = testCredential(
      type: "pbdf.sidn-pbdf.email",
      hash: "a",
      attributes: [stringAttr("email", "sanne@example.org"), stringAttr("domain", "example.org")],
    );
    expect(hintOf(email, [email]), "sanne@example.org");
  });

  test("two bank accounts skip the shared name and show the IBAN", () {
    final a = testCredential(
      type: "pbdf.pbdf.iban",
      hash: "a",
      attributes: [stringAttr("fullname", "S. de Vries"), stringAttr("iban", "NL91ABNA0417164300")],
    );
    final b = testCredential(
      type: "pbdf.pbdf.iban",
      hash: "b",
      attributes: [stringAttr("fullname", "S. de Vries"), stringAttr("iban", "NL20INGB0001234567")],
    );
    expect(hintOf(a, [a, b]), "NL91ABNA0417164300");
    expect(hintOf(b, [a, b]), "NL20INGB0001234567");
  });

  test("other credential types do not count as siblings", () {
    final iban = testCredential(
      type: "pbdf.pbdf.iban",
      hash: "a",
      attributes: [stringAttr("fullname", "S. de Vries"), stringAttr("iban", "NL91")],
    );
    final linkedin = testCredential(
      type: "pbdf.pbdf.linkedin",
      hash: "b",
      attributes: [stringAttr("fullname", "S. de Vries")],
    );
    expect(hintOf(iban, [iban, linkedin]), "S. de Vries");
  });

  test("deny-listed identifiers are skipped", () {
    final passport = testCredential(
      type: "pbdf.pbdf.passport",
      hash: "a",
      attributes: [stringAttr("documentNumber", "NXC4R1P72"), stringAttr("firstName", "Sanne")],
    );
    expect(hintOf(passport, [passport]), "Sanne");
  });

  test("a built-in card shows the value at its top, not the first attribute", () {
    final passport = testCredential(
      type: "pbdf.pbdf.passport",
      hash: "a",
      attributes: [
        stringAttr("documentType", "P"),
        stringAttr("firstName", "Sanne"),
        stringAttr("lastName", "de Vries"),
      ],
    );
    expect(hintOf(passport, [passport]), "Sanne de Vries");

    final big = testCredential(
      type: "pbdf.pbdf.big",
      hash: "b",
      attributes: [stringAttr("bignumber", "19012345601"), stringAttr("profession", "Arts")],
    );
    expect(hintOf(big, [big]), "Arts");

    final address = testCredential(
      type: "pbdf-staging.gemeente.address",
      hash: "c",
      attributes: [
        stringAttr("zipcode", "1234 AB"),
        stringAttr("street", "Meander"),
        stringAttr("houseNumber", "501"),
      ],
    );
    expect(hintOf(address, [address]), "Meander 501");
  });

  test("two built-in cards with the same top value tell themselves apart", () {
    final a = testCredential(
      type: "pbdf.pbdf.passport",
      hash: "a",
      attributes: [stringAttr("firstName", "Sanne"), stringAttr("dateOfExpiry", "2030-01-01")],
    );
    final b = testCredential(
      type: "pbdf.pbdf.passport",
      hash: "b",
      attributes: [stringAttr("firstName", "Sanne"), stringAttr("dateOfExpiry", "2034-06-01")],
    );
    expect(hintOf(a, [a, b]), "2030-01-01");
    expect(hintOf(b, [a, b]), "2034-06-01");
  });

  test("only yes/no values fall back to the date added", () {
    final ages = testCredential(
      type: "pbdf.pbdf.ageLimits",
      hash: "a",
      attributes: [boolAttr("over12", true), boolAttr("over18", true)],
      issuanceDate: 1709337600,
    );
    expect(hintOf(ages, [ages]), "added");
  });

  test("empty optional values are skipped", () {
    final linkedin = testCredential(
      type: "pbdf.pbdf.linkedin",
      hash: "a",
      attributes: [stringAttr("fullname", ""), stringAttr("email", "s@example.org")],
    );
    expect(hintOf(linkedin, [linkedin]), "s@example.org");
  });

  test("a credential with an issuer template uses the first svg_id claim", () {
    final card = testCredential(
      type: "https://library.example/card",
      hash: "a",
      attributes: [
        stringAttr("name", "Sanne de Vries"),
        stringAttr("card_number", "2041", svgId: "card_no"),
      ],
      display: CredentialDisplay(svgTemplates: [SvgCardTemplate(svg: "<svg/>")]),
    );
    expect(hintOf(card, [card]), "2041");
  });

  test("no values and no date gives no hint", () {
    final empty = testCredential(type: "x", hash: "a");
    expect(hintOf(empty, [empty]), isNull);
  });
}
