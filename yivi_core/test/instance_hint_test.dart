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
